# frozen_string_literal: true

app { |_env| [200, {}, ['embedded app']] }
lowlevel_error_handler { |_err| [500, {}, ['error page']] }

threads 1, 1

bind "unix://#{ENV.fetch('BIND_PATH', nil)}"

plugin 'telemetry'

Target = Struct.new(:name) do
  def call(telemetry)
    puts "target=#{name} telemetry=#{telemetry.inspect}"
  end
end

Puma::Plugin::Telemetry.configure do |config|
  config.add_target Target.new('01')
  config.add_target Target.new('02')
  config.frequency = 0.2
  config.enabled = true
  config.initial_delay = 2
end
