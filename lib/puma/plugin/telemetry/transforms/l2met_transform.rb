# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Transforms
        # L2Met (Logs to Metrics) transform that makes all keys a `sample#` in the L2Met format.
        #
        class L2metTransform
          def self.call(telemetry)
            telemetry.transform_keys { |k| "sample##{k}" }.tap do |data|
              data['name'] = 'Puma::Plugin::Telemetry'
              # data['source'] = ??
            end
          end
        end
      end
    end
  end
end
