# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Formatters
        # A NOOP formatter - it returns the telemetry Hash it was given
        class NoopFormatter
          def self.call(telemetry)
            telemetry
          end
        end
      end
    end
  end
end
