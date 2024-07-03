# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Formatters
        # A passthrough formatter - it returns the telemetry Hash it was given
        class PassthroughFormatter
          def self.call(telemetry)
            telemetry
          end
        end
      end
    end
  end
end
