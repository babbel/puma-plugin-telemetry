# frozen_string_literal: true

require 'logger'
require_relative 'json_formatter'

module Puma
  class Plugin
    module Telemetry
      module Targets
        # Simple Log Target, publishing metrics to a Ruby ::Logger at stdout
        # at the INFO log level
        #
        class LogTarget
          def initialize(logger: ::Logger.new($stdout), formatter: :json)
            @logger = logger
            @formatter = case formatter
                         when :json then JSONFormatter
                         else formatter
                         end
          end

          def call(telemetry)
            logger.info(formatter.call(telemetry))
          end

          private

          attr_reader :formatter, :logger
        end
      end
    end
  end
end
