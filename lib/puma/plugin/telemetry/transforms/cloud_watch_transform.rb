# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Transforms
        # Replace dots with dashes for better support of AWS CloudWatch Log
        # Metric filters, as they don't support dots in key names.
        # Expects `call` method accepting telemetry Hash
        class CloudWatchTransform
          def self.call(telemetry)
            telemetry.transform_keys { |k| String(k).tr('.', '-') }.tap do |data|
              data['name'] = 'Puma::Plugin::Telemetry'
              data['message'] = 'Publish telemetry'
            end
          end
        end
      end
    end
  end
end
