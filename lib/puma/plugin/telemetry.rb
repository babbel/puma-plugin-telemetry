# frozen_string_literal: true

require "puma"
require "puma/plugin"

require "puma/plugin/telemetry/version"
require "puma/plugin/telemetry/config"

module Puma
  class Plugin
    # Telemetry plugin for puma, supporting:
    #
    # - multiple targets, decide where to push puma telemetry information, i.e. datadog, cloudwatch, logs
    # - filtering, select which metrics are interesting for you, extend when necessery
    #
    module Telemetry
      class Error < StandardError; end

      class << self
        attr_writer :config

        def config
          @config ||= Config.new
        end

        def configure
          yield(config)
        end

        def build
          {}
        end
      end
    end
  end
end

Puma::Plugin.create do
  def start(launcher)
    unless Puma::Plugin::Telemetry.config.enabled?
      launcher.events.debug "telemetry: disabled, exiting..."
      return
    end

    @launcher = launcher
    @launcher.events.debug "telemetry: enabled, setting up runner..."

    in_background(&method(:runner))
  end

  def runner
    loop do
      @launcher.events.debug "telemetry: publish"

      call(Puma::Plugin::Telemetry.build)
    rescue Errno::EPIPE
      # Occurs when trying to output to STDOUT while puma is shutting down
    rescue StandardError => e
      @launcher.events.error "telemetry: failed with #{e.class}<#{e.message.inspect}>"
    ensure
      sleep Puma::Plugin::Telemetry.config.frequency
    end
  end

  def call(telemetry)
    Puma::Plugin::Telemetry.config.targets.each do |target|
      target.call(telemetry)
    end
  end
end
