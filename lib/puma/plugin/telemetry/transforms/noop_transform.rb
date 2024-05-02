# frozen_string_literal: true

require 'json'

module Puma
  class Plugin
    module Telemetry
      module Transforms
        # A NOOP Transform - it returns the telemetry Hash it was given
        class NoopTransform
          def self.call(telemetry)
            telemetry
          end
        end
      end
    end
  end
end
