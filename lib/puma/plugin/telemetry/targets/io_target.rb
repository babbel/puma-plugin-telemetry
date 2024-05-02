# frozen_string_literal: true

require_relative '../formatters/json_formatter'
require_relative '../transforms/cloud_watch_transform'

module Puma
  class Plugin
    module Telemetry
      module Targets
        # Simple IO Target, publishing metrics to STDOUT or logs
        #
        class IOTarget
          def initialize(io: $stdout, formatter: :json, transform: :cloud_watch)
            @io = io
            @transform = case transform
                         when :cloud_watch then Transforms::CloudWatchTranform
                         else transform
                         end
            @formatter = case formatter
                         when :json then Formatters::JSONFormatter
                         else formatter
                         end
          end

          def call(telemetry)
            io.puts(formatter.call(transform.call(telemetry)))
          end

          private

          attr_reader :formatter, :io, :transform
        end
      end
    end
  end
end
