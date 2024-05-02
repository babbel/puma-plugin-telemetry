# frozen_string_literal: true

require_relative '../formatters/json_formatter'
require_relative '../formatters/logfmt_formatter'
require_relative '../transforms/l2met_transform'
require_relative '../transforms/cloud_watch_transform'

module Puma
  class Plugin
    module Telemetry
      module Targets
        # A base class for other Targets concerned with formatting telemetry
        #
        class BaseFormattingTarget
          def initialize(formatter: :json, transform: :cloud_watch)
            @transform = case transform
                         when :cloud_watch then Transforms::CloudWatchTranform
                         when :l2met then Transforms::L2metTransform
                         else transform
                         end
            @formatter = case formatter
                         when :json then Formatters::JSONFormatter
                         when :logfmt then Formatters::LogfmtFormatter
                         else formatter
                         end
          end

          def call(_telemetry)
            raise "#{__method__} must be implemented by #{self.class.name}"
          end

          private

          attr_reader :formatter, :transform
        end
      end
    end
  end
end

