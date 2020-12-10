# frozen_string_literal: true

app { |_env| [200, {}, ["embedded app"]] }
lowlevel_error_handler { |_err| [200, {}, ["error page"]] }

threads 1, 1
plugin "telemetry"
