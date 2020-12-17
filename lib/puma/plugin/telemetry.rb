# frozen_string_literal: true

require "puma"
require "puma/plugin"

require "puma/plugin/telemetry/version"
require "puma/plugin/telemetry/config"
require "puma/plugin/telemetry/data"
require "puma/plugin/telemetry/targets/datadog_statsd_target"
require "puma/plugin/telemetry/targets/io_target"

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
          puma_telemetry
        end

        private

        def puma_telemetry
          stats = ::Puma.stats_hash
          File.write("foo.json", JSON.generate(stats))
          data_class = if stats.key?(:workers)
                         ClusteredData
                       else
                         WorkerData
                       end
          data_class
            .new(stats)
            .metrics(config.puma_telemetry)
        end
      end

      # Contents of actual Puma Plugin
      #
      module PluginInstanceMethods
        def start(launcher)
          unless Puma::Plugin::Telemetry.config.enabled?
            launcher.events.log "plugin=telemetry msg=\"disabled, exiting...\""
            return
          end

          @launcher = launcher
          @launcher.events.log "plugin=telemetry msg=\"enabled, setting up runner...\""

          in_background do
            sleep Puma::Plugin::Telemetry.config.initial_delay
            run!
          end
        end

        def run!
          loop do
            @launcher.events.debug "plugin=telemetry msg=\"publish\""

            call(Puma::Plugin::Telemetry.build)
          rescue Errno::EPIPE
            # Occurs when trying to output to STDOUT while puma is shutting down
          rescue StandardError => e
            @launcher.events.error "plugin=telemetry err=#{e.class} msg=#{e.message.inspect}"
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
    end
  end
end

Puma::Plugin.create do
  include Puma::Plugin::Telemetry::PluginInstanceMethods
end
