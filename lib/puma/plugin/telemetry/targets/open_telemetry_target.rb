# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Targets
        # Target wrapping OpenTelemetry Metrics client.
        #
        # ## Example
        #
        #     require 'opentelemetry-metrics-sdk'
        #
        #     OpenTelemetryTarget.new(meter_provider: OpenTelemetry.meter_provider, prefix: 'puma')
        #
        class OpenTelemetryTarget
          def initialize(meter_provider:, prefix: nil, suffix: nil, force_flush: false, attributes: {})
            @meter_provider = meter_provider
            @meter          = meter_provider.meter('puma.telemetry')
            @prefix         = prefix
            @suffix         = suffix
            @force_flush    = force_flush
            @attributes     = attributes
            @instruments    = {}
          end

          # We are using `gauge` metric type, which means that only the last value will get exported
          # since the OpenTelemetry exporter aggregates metrics before sending them.
          #
          # This means that we could publish metrics from here several times
          # before they get flushed from the aggregation thread, and when they
          # do, only the last values will get sent.
          #
          # That's why we provide the option to explicitly call force_flush here, in order to persist
          # all metrics, and not only the most recent ones.
          #
          # Note: Force flushing metrics every time can significantly impact performance
          #
          def call(telemetry)
            telemetry.each do |metric, value|
              instrument(metric).record(value, attributes: @attributes)
            end

            @meter_provider.force_flush if @force_flush
          end

          def instrument(metric)
            @instruments[metric] ||= @meter.create_gauge([@prefix, metric, @suffix].compact.join('.'))
          end
        end
      end
    end
  end
end
