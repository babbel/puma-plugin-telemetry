# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      # Helper for working with Puma stats
      module CommonData
        TELEMETRY_TO_METHODS = {
          "workers.booted" => :workers_booted,
          "workers.total" => :workers_total,
          "workers.spawned_threads" => :workers_spawned_threads,
          "workers.max_threads" => :workers_max_threads,
          "workers.requests_count" => :workers_requests_count,
          "queue.backlog" => :queue_backlog,
          "queue.capacity" => :queue_capacity
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

        def initialize(ios)
          @sockets = ios.select { |io| io.respond_to?(:getsockopt) }
        end

        # Number of unacknowledged connections in the sockets, which
        # we know as socket backlog.
        #
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
        # That's why we have to pull the `unacked`  field by parsing
        # `inspect` output, instead of using something like `opt.unacked`
        def unacked
          @sockets.sum do |socket|
            tcp_info = socket.getsockopt(Socket::SOL_TCP, Socket::TCP_INFO).inspect
            tcp_match = tcp_info.match(UNACKED_REGEXP)

            tcp_match[:unacked].to_i
          end
        end

        def metrics
          {
            "sockets.backlog" => unacked
          }
        end
      end
    end
  end
end
