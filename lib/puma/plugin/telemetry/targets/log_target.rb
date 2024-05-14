# frozen_string_literal: true

require 'logger'
require_relative 'base_formatting_target'

module Puma
  class Plugin
    module Telemetry
      module Targets
        # Simple Log Target, publishing metrics to a Ruby ::Logger at stdout
        # at the INFO log level
        #
        class LogTarget < BaseFormattingTarget
          def initialize(logger: ::Logger.new($stdout), formatter: :logfmt, transform: :noop)
            super(formatter: formatter, transform: transform)
            @logger = logger
          end

          def call(telemetry)
            logger.info(formatter.call(transform.call(telemetry)))
          end

          private

          attr_reader :logger
        end
      end
    end
  end
end
