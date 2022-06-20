# frozen_string_literal: true

app { |_env| [200, {}, ['embedded app']] }
lowlevel_error_handler { |_err| [500, {}, ['error page']] }

threads 1, 2
workers 2

bind "unix://#{ENV.fetch('BIND_PATH', nil)}"

plugin 'telemetry'

Puma::Plugin::Telemetry.configure do |config|
  config.add_target :io, formatter: :json
  config.frequency = 0.2
  config.enabled = true

  # Delay first metric, so puma has time to bootup workers
  config.initial_delay = 2

  config.puma_telemetry = %w[
    queue.backlog
    workers.spawned_threads
    workers.max_threads
  ]
end
