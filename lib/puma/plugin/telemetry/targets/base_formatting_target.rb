# frozen_string_literal: true

require_relative '../formatters/json_formatter'
require_relative '../formatters/logfmt_formatter'
require_relative '../formatters/passthrough_formatter'
require_relative '../transforms/cloud_watch_transform'
require_relative '../transforms/passthrough_transform'

module Puma
  class Plugin
    module Telemetry
      module Targets
        # A base class for other Targets concerned with formatting telemetry
        class BaseFormattingTarget
          def initialize(formatter: :json, transform: :cloud_watch)
            @formatter = FORMATTERS.fetch(formatter) { formatter }
            @transform = TRANSFORMS.fetch(transform) { transform }
          end

          def call(_telemetry)
            raise "#{__method__} must be implemented by #{self.class.name}"
          end

          private

          attr_reader :formatter, :transform

          FORMATTERS = {
            json: Formatters::JSONFormatter,
            logfmt: Formatters::LogfmtFormatter,
            passthrough: Formatters::PassthroughFormatter
          }.freeze
          private_constant :FORMATTERS

          TRANSFORMS = {
            cloud_watch: Transforms::CloudWatchTranform,
            passthrough: Transforms::PassthroughTransform
          }.freeze
          private_constant :TRANSFORMS
        end
      end
    end
  end
end
