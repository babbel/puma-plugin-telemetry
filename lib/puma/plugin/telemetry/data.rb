# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      # Helper for working with Puma stats
      module CommonData
        TELEMETRY_TO_METHODS = {
          'workers.booted' => :workers_booted,
          'workers.total' => :workers_total,
          'workers.spawned_threads' => :workers_spawned_threads,
          'workers.max_threads' => :workers_max_threads,
          'workers.requests_count' => :workers_requests_count,
          'queue.backlog' => :queue_backlog,
          'queue.capacity' => :queue_capacity
        }.freeze

        def initialize(stats)
          @stats = stats
        end

        def workers_booted
          @stats.fetch(:booted_workers, 1)
        end

        def workers_total
          @stats.fetch(:workers, 1)
        end

        def metrics(selected)
          selected.each_with_object({}) do |metric, obj|
            next unless TELEMETRY_TO_METHODS.key?(metric)

            obj[metric] = public_send(TELEMETRY_TO_METHODS[metric])
          end
        end
      end

      # Handles the case of non clustered mode, where `workers` isn't configured
      class WorkerData
        include CommonData

        def workers_max_threads
          @stats.fetch(:max_threads, 0)
        end

        def workers_requests_count
          @stats.fetch(:requests_count, 0)
        end

        def workers_spawned_threads
          @stats.fetch(:running, 0)
        end

        def queue_backlog
          @stats.fetch(:backlog, 0)
        end

        def queue_capacity
          @stats.fetch(:pool_capacity, 0)
        end
      end

      # Handles the case of clustered mode, where we have statistics
      # for all the workers. This class takes care of summing all
      # relevant data.
      class ClusteredData
        include CommonData

        def workers_max_threads
          sum_stat(:max_threads)
        end

        def workers_requests_count
          sum_stat(:requests_count)
        end

        def workers_spawned_threads
          sum_stat(:running)
        end

        def queue_backlog
          sum_stat(:backlog)
        end

        def queue_capacity
          sum_stat(:pool_capacity)
        end

        private

        def sum_stat(stat)
          @stats[:worker_status].reduce(0) do |sum, data|
            (data.dig(:last_status, stat) || 0) + sum
          end
        end
      end

      # Pulls TCP INFO data from socket
      class SocketData
        UNACKED_REGEXP = /\ unacked=(?<unacked>\d+)\ /.freeze

        def initialize(ios, parser)
          @sockets = ios.select { |io| io.respond_to?(:getsockopt) && io.is_a?(TCPSocket) }
          @parser =
            case parser
            when :inspect then method(:parse_with_inspect)
            when :unpack then method(:parse_with_unpack)
            when Proc then parser
            end
        end

        # Number of unacknowledged connections in the sockets, which
        # we know as socket backlog.
        #
        def unacked
          @sockets.sum do |socket|
            @parser.call(socket.getsockopt(Socket::SOL_TCP,
                                           Socket::TCP_INFO))
          end
        end

        def metrics
          {
            'sockets.backlog' => unacked
          }
        end

        private

        # The Socket::Option returned by `getsockopt` doesn't provide
        # any kind of accessors for data inside. It decodes it on demand
        # for `inspect` as strings in C implementation. It looks like
        #
        #     #<Socket::Option: INET TCP INFO state=LISTEN
        #                                     ca_state=Open
        #                                     retransmits=0
        #                                     probes=0
        #                                     backoff=0
        #                                     options=0
        #                                     rto=0.000000s
        #                                     ato=0.000000s
        #                                     snd_mss=0
        #                                     rcv_mss=0
        #                                     unacked=0
        #                                     sacked=5
        #                                     lost=0
        #                                     retrans=0
        #                                     fackets=0
        #                                     last_data_sent=0.000s
        #                                     last_ack_sent=0.000s
        #                                     last_data_recv=0.000s
        #                                     last_ack_recv=0.000s
        #                                     pmtu=0
        #                                     rcv_ssthresh=0
        #                                     rtt=0.000000s
        #                                     rttvar=0.000000s
        #                                     snd_ssthresh=0
        #                                     snd_cwnd=10
        #                                     advmss=0
        #                                     reordering=3
        #                                     rcv_rtt=0.000000s
        #                                     rcv_space=0
        #                                     total_retrans=0
        #                                     (128 bytes too long)>
        #
        # That's why pulling the `unacked` field by parsing
        # `inspect` output is one of the ways to retrieve it.
        #
        def parse_with_inspect(tcp_info)
          tcp_match = tcp_info.inspect.match(UNACKED_REGEXP)

          return 0 if tcp_match.nil?

          tcp_match[:unacked].to_i
        end

        # The above inspect data might not be available everywhere (looking at you
        # AWS Fargate Host running on kernel 4.14!), but we might still recover it
        # by manually unpacking the binary data based on linux headers. For example
        # below is tcp info struct from `linux/tcp.h` header file, from problematic
        # host rocking kernel 4.14.
        #
        #     struct tcp_info {
        #         __u8    tcpi_state;
        #         __u8    tcpi_ca_state;
        #         __u8    tcpi_retransmits;
        #         __u8    tcpi_probes;
        #         __u8    tcpi_backoff;
        #         __u8    tcpi_options;
        #         __u8    tcpi_snd_wscale : 4, tcpi_rcv_wscale : 4;
        #         __u8    tcpi_delivery_rate_app_limited:1;
        #
        #         __u32   tcpi_rto;
        #         __u32   tcpi_ato;
        #         __u32   tcpi_snd_mss;
        #         __u32   tcpi_rcv_mss;
        #
        #         __u32   tcpi_unacked;
        #         __u32   tcpi_sacked;
        #         __u32   tcpi_lost;
        #         __u32   tcpi_retrans;
        #         __u32   tcpi_fackets;
        #
        #         /* Times. */
        #         __u32   tcpi_last_data_sent;
        #         __u32   tcpi_last_ack_sent;     /* Not remembered, sorry. */
        #         __u32   tcpi_last_data_recv;
        #         __u32   tcpi_last_ack_recv;
        #
        #         /* Metrics. */
        #         __u32   tcpi_pmtu;
        #         __u32   tcpi_rcv_ssthresh;
        #         __u32   tcpi_rtt;
        #         __u32   tcpi_rttvar;
        #         __u32   tcpi_snd_ssthresh;
        #         __u32   tcpi_snd_cwnd;
        #         __u32   tcpi_advmss;
        #         __u32   tcpi_reordering;
        #
        #         __u32   tcpi_rcv_rtt;
        #         __u32   tcpi_rcv_space;
        #
        #         __u32   tcpi_total_retrans;
        #
        #         __u64   tcpi_pacing_rate;
        #         __u64   tcpi_max_pacing_rate;
        #         __u64   tcpi_bytes_acked;    /* RFC4898 tcpEStatsAppHCThruOctetsAcked */
        #         __u64   tcpi_bytes_received; /* RFC4898 tcpEStatsAppHCThruOctetsReceived */
        #         __u32   tcpi_segs_out;       /* RFC4898 tcpEStatsPerfSegsOut */
        #         __u32   tcpi_segs_in;        /* RFC4898 tcpEStatsPerfSegsIn */
        #
        #         __u32   tcpi_notsent_bytes;
        #         __u32   tcpi_min_rtt;
        #         __u32   tcpi_data_segs_in;      /* RFC4898 tcpEStatsDataSegsIn */
        #         __u32   tcpi_data_segs_out;     /* RFC4898 tcpEStatsDataSegsOut */
        #
        #         __u64   tcpi_delivery_rate;
        #
        #         __u64   tcpi_busy_time;      /* Time (usec) busy sending data */
        #         __u64   tcpi_rwnd_limited;   /* Time (usec) limited by receive window */
        #         __u64   tcpi_sndbuf_limited; /* Time (usec) limited by send buffer */
        #     };
        #
        # Now nowing types and order of fields we can easily parse binary data
        # by using
        # - `C` flag for `__u8` type - 8-bit unsigned (unsigned char)
        # - `L` flag for `__u32` type - 32-bit unsigned, native endian (uint32_t)
        # - `Q` flag for `__u64` type - 64-bit unsigned, native endian (uint64_t)
        #
        # Complete `unpack` would look like `C8 L24 Q4 L6 Q4`, but we are only
        # interested in `unacked` field at the moment, that's why we only parse
        # till this field by unpacking with `C8 L5`.
        #
        # If you find that it's not giving correct results, then please fall back
        # to inspect, or update this code to accept unpack sequence. But in the
        # end unpack is preferable, as it's 12x faster than inspect.
        #
        # Tested against:
        # - Amazon Linux 2 with kernel 4.14 & 5.10
        # - Ubuntu 20.04 with kernel 5.13
        #
        def parse_with_unpack(tcp_info)
          tcp_info.unpack('C8L5').last
        end
      end
    end
  end
end
