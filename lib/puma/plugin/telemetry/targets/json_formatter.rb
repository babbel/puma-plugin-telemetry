# frozen_string_literal: true

require 'json'

module Puma
  class Plugin
    module Telemetry
      module Targets
        # JSON formatter for IO, expects `call` method accepting telemetry hash
        #
        class JSONFormatter
          # NOTE: Replace dots with dashes for better support of AWS CloudWatch
          #       Log Metric filters, as they don't support dots in key names.
          def self.call(telemetry)
            log = telemetry.transform_keys { |k| String(k).tr('.', '-') }

            log['name'] = 'Puma::Plugin::Telemetry'
            log['message'] = 'Publish telemetry'

            ::JSON.dump(log)
          end
        end
      end
    end
  end
end
