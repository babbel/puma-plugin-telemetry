# frozen_string_literal: true

require 'socket'

module Puma
  class Plugin
    module Telemetry
      module Targets
        # Target wrapping Datadog Statsd client. You can configure
        # all details like _metrics prefix_ and _tags_ in the client
        # itself.
        #
        # ## Example
        #
        #     require "datadog/statsd"
        #
        #     client = Datadog::Statsd.new(namespace: "ruby.puma",
        #                                  tags: {
        #                                    service: "my-webapp",
        #                                    env: ENV["RAILS_ENV"],
        #                                    version: ENV["CODE_VERSION"]
        #                                  })
        #
        #     DatadogStatsdTarget.new(client: client)
        #
        class DatadogStatsdTarget
          TAGGED_METRICS = [Telemetry::Metrics::WORKERS_BUSY_THREADS].freeze

          def initialize(client:)
            @client = client
            @hostname = Socket.gethostname
          end

          # We are using `gauge` metric type, which means that only the last
          # value will get send to datadog. DD Statsd client is using extra
          # thread since v5 for aggregating metrics before it sends them.
          #
          # This means that we could publish metrics from here several times
          # before they get flushed from the aggregation thread, and when they
          # do, only the last values will get sent.
          #
          # That's why we are explicitly calling flush here, in order to persist
          # all metrics, and not only the most recent ones.
          #
          def call(telemetry)
            telemetry.each do |metric, value|
              if TAGGED_METRICS.include?(metric)
                @client.gauge(metric, value, tags: ["process:#{@hostname}"])
              else
                @client.gauge(metric, value)
              end
            end

            @client.flush(sync: true)
          end
        end
      end
    end
  end
end
