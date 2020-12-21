# frozen_string_literal: true

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
          def initialize(client:)
            @client = client
          end

          def call(telemetry)
            @client.batch do |statsd|
              telemetry.each do |metric, value|
                statsd.gauge(metric, value)
              end
            end
          end
        end
      end
    end
  end
end
