# frozen_string_literal: true

app { |_env| [200, {}, ["embedded app"]] }
lowlevel_error_handler { |_err| [500, {}, ["error page"]] }

threads 1, 1
plugin "telemetry"

Puma::Plugin::Telemetry.configure do |config|
  config.initial_delay = 0
end
