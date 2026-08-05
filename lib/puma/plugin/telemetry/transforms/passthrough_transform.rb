# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Transforms
        # A passthrough transform - it returns the telemetry Hash it was given
        class PassthroughTransform
          def self.call(telemetry)
            telemetry
          end
        end
      end
    end
  end
end
