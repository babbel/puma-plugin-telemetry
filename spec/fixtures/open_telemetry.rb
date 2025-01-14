# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry-metrics-sdk'

# Custom console exporter to support flushing metrics. Console _pull_ exporter doesn't have a force_flush method like the typical exporters
class ConsoleMetricExporter < OpenTelemetry::SDK::Metrics::Export::ConsoleMetricPullExporter
  def force_flush(timeout: nil)
    pull
  end
end

OpenTelemetry::SDK.configure

console_metric_exporter = ConsoleMetricExporter.new
OpenTelemetry.meter_provider.add_metric_reader(console_metric_exporter)

app { |_env| [200, {}, ['embedded app']] }
lowlevel_error_handler { |_err| [500, {}, ['error page']] }

threads 1, 1

bind "unix://#{ENV.fetch('BIND_PATH', nil)}"

plugin 'telemetry'

Puma::Plugin::Telemetry.configure do |config|
  config.add_target :open_telemetry, meter_provider: OpenTelemetry.meter_provider
  config.frequency = 0.2
  config.enabled = true
  config.initial_delay = 2
end
