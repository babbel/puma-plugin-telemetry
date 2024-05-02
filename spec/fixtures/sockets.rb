# frozen_string_literal: true

@initial_delay = true

app do |_env|
  sleep(2) if @initial_delay

  # there's only 1 thread, so it should be fine
  @initial_delay = false

  [200, {}, ['embedded app']]
end

lowlevel_error_handler { |_err| [500, {}, ['error page']] }

threads 1, 1
plugin 'telemetry'

bind "unix://#{ENV.fetch('BIND_PATH', nil)}"
bind 'tcp://localhost:59292'

Puma::Plugin::Telemetry.configure do |config|
  # Simple `key=value` formatter
  config.add_target(:io, formatter: :logfmt, transform: :noop)
  config.frequency = 1
  config.enabled = true

  # Check how `queue.backlog` from puma behaves
  config.puma_telemetry = ['queue.backlog']

  # Delay first metric, so puma has time to bootup workers
  config.initial_delay = 2

  config.socket_telemetry!
end
