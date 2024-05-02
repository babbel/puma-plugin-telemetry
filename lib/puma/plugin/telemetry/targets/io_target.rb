# frozen_string_literal: true

require_relative 'json_formatter'

module Puma
  class Plugin
    module Telemetry
      module Targets
        # Simple IO Target, publishing metrics to STDOUT or logs
        #
        class IOTarget
          def initialize(io: $stdout, formatter: :json)
            @io = io
            @formatter = case formatter
                         when :json then JSONFormatter
                         else formatter
                         end
          end

          def call(telemetry)
            io.puts(formatter.call(telemetry))
          end

          private

          attr_reader :formatter, :io
        end
      end
    end
  end
end
