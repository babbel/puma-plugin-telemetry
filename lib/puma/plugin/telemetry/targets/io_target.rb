# frozen_string_literal: true

require "json"

module Puma
  class Plugin
    module Telemetry
      module Targets
        # Simple IO Target, publishing metrics to STDOUT or logs
        #
        class IOTarget
          # JSON formatter for IO, expects `call` method accepting telemetry hash
          #
          class JSONFormatter
            # NOTE: Replace dots with dashes for better support of AWS CloudWatch
            #       Log Metric filters, as they don't support dots in key names.
            def self.call(telemetry)
              log = telemetry.transform_keys { |k| k.tr(".", "-") }

              log["name"] = "Puma::Plugin::Telemetry"
              log["message"] = "Publish telemetry"

              ::JSON.dump(log)
            end
          end

          def initialize(io: $stdout, formatter: :json)
            @io = io
            @formatter = case formatter
                         when :json then JSONFormatter
                         else formatter
                         end
          end

          def call(telemetry)
            @io.puts(@formatter.call(telemetry))
          end
        end
      end
    end
  end
end
