# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      # Configuration object for plugin
      #
      # TBD
      class Config
        # Whenever telemetry should run with puma
        # - default: false
        attr_accessor :enabled

        # Seconds between publishing telemetry
        # - default: 5
        attr_accessor :frequency

        # List of targets which are meant to publish telemetry.
        # Target should implement `#call` method accepting a single argument - so it can be even a simple proc.
        # - default: []
        attr_accessor :targets

        def initialize
          @enabled = false
          @frequency = 5
          @targets = []
        end

        def enabled?
          !!@enabled
        end
      end
    end
  end
end
