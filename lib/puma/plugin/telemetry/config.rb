# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      # Configuration object for plugin
      class Config
        DEFAULT_PUMA_TELEMETRY = [
          # Total booted workers.
          "workers.booted",

          # Total number of workers configured.
          "workers.total",

          # Current number of threads spawned.
          "workers.spawned_threads",

          # Maximum number of threads that can run .
          "workers.max_threads",

          # Number of requests performed so far.
          "workers.requests_count",

          # Number of requests waiting to be processed.
          "queue.backlog",

          # Free capacity that could be utilized, i.e. if backlog
          # is growing, and we still have capacity available, it
          # could mean that load balancing is not performing well.
          "queue.capacity"
        ].freeze

        TARGETS = {
          dogstatsd: Telemetry::Targets::DatadogStatsdTarget,
          io: Telemetry::Targets::IOTarget
        }.freeze

        # Whenever telemetry should run with puma
        # - default: false
        attr_accessor :enabled

        # Number of seconds to delay first telemetry
        # - default: 5
        attr_accessor :initial_delay

        # Seconds between publishing telemetry
        # - default: 5
        attr_accessor :frequency

        # List of targets which are meant to publish telemetry.
        # Target should implement `#call` method accepting
        # a single argument - so it can be even a simple proc.
        # - default: []
        attr_accessor :targets

        # Which metrics to publish from puma stats. You can select
        # a subset from default ones that interest you the most.
        # - default: DEFAULT_PUMA_TELEMETRY
        attr_accessor :puma_telemetry

        def initialize
          @enabled = false
          @initial_delay = 5
          @frequency = 5
          @targets = []
          @puma_telemetry = DEFAULT_PUMA_TELEMETRY
        end

        def enabled?
          !!@enabled
        end

        def add_target(name_or_target, **args)
          return @targets.push(name_or_target) unless name_or_target.is_a?(Symbol)

          target = TARGETS.fetch(name_or_target) do
            raise Telemetry::Error, "Unknown Target: #{name_or_target.inspect}, #{args.inspect}"
          end

          @targets.push(target.new(**args))
        end
      end
    end
  end
end
