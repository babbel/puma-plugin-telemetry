# frozen_string_literal: true

begin
  require 'opentelemetry-metrics-sdk'
rescue LoadError
  # Gracefully handle the case when OpenTelemetry Metrics SDK is not installed
end

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
          def self.available?
            !defined?(OpenTelemetry::SDK::Metrics).nil?
          end

          def initialize(meter_provider:, prefix: nil, suffix: nil, attributes: {})
            raise ArgumentError, ':open_telemetry target can only be used when the `opentelemetry-metrics-sdk` and `opentelemetry-exporter-otlp-metrics` gems are installed' unless self.class.available?

            @meter_provider = meter_provider
            @meter          = meter_provider.meter('puma.telemetry')
            @prefix         = prefix
            @suffix         = suffix
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
          # That's why we are explicitly calling force_flush here, in order to persist
          # all metrics, and not only the most recent ones.
          #
          def call(telemetry)
            telemetry.each do |metric, value|
              instrument(metric).record(value, attributes: @attributes)
            end

            @meter_provider.try(:force_flush)
          end

          def instrument(metric)
            @instruments[metric] ||= @meter.create_gauge([@prefix, metric, @suffix].compact.join('.'))
          end
        end
      end
    end
  end
end
