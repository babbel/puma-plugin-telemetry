# frozen_string_literal: true

require 'logger'
require_relative '../formatters/json_formatter'
require_relative '../transforms/noop_transform'

module Puma
  class Plugin
    module Telemetry
      module Targets
        # Simple Log Target, publishing metrics to a Ruby ::Logger at stdout
        # at the INFO log level
        #
        class LogTarget
          def initialize(logger: ::Logger.new($stdout), formatter: :json, transform: :noop)
            @logger = logger
            @transform = case transform
                         when :noop then Transforms::NoopTransform
                         else transform
                         end
            @formatter = case formatter
                         when :json then Formatters::JSONFormatter
                         else formatter
                         end
          end

          def call(telemetry)
            logger.info(formatter.call(transform.call(telemetry)))
          end

          private

          attr_reader :formatter, :logger, :transform
        end
      end
    end
  end
end
