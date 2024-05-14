# frozen_string_literal: true

require_relative 'base_formatting_target'

module Puma
  class Plugin
    module Telemetry
      module Targets
        # Simple IO Target, publishing metrics to STDOUT or logs
        #
        class IOTarget < BaseFormattingTarget
          def initialize(io: $stdout, formatter: :json, transform: :cloud_watch)
            super(formatter: formatter, transform: transform)
            @io = io
          end

          def call(telemetry)
            io.puts(formatter.call(transform.call(telemetry)))
          end

          private

          attr_reader :io
        end
      end
    end
  end
end
