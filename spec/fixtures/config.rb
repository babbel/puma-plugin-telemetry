# frozen_string_literal: true

app { |_env| [200, {}, ["embedded app"]] }
lowlevel_error_handler { |_err| [200, {}, ["error page"]] }

threads 1, 1
plugin "telemetry"

Target = Struct.new(:name) do
  def call(telemetry)
    puts "target=#{name} telemetry=#{telemetry.inspect}"
  end
end

Puma::Plugin::Telemetry.configure do |config|
  config.targets << Target.new("01")
  config.targets << Target.new("02")
  config.frequency = 0.2
  config.enabled = true
  config.initial_delay = 0
end
