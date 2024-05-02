# frozen_string_literal: true

require 'puma'
require 'puma/plugin'

require 'puma/plugin/telemetry/version'
require 'puma/plugin/telemetry/data'
require 'puma/plugin/telemetry/targets/datadog_statsd_target'
require 'puma/plugin/telemetry/targets/io_target'
require 'puma/plugin/telemetry/targets/log_target'
require 'puma/plugin/telemetry/targets/open_telemetry_target'
require 'puma/plugin/telemetry/config'

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

        def build(launcher = nil)
          socket_telemetry(puma_telemetry, launcher)
        end

        private

        def puma_telemetry
          stats = ::Puma.stats_hash
          data_class = if stats.key?(:workers)
                         ClusteredData
                       else
                         WorkerData
                       end
          data_class
            .new(stats)
            .metrics(config.puma_telemetry)
        end

        def socket_telemetry(telemetry, launcher)
          return telemetry if launcher.nil?
          return telemetry unless config.socket_telemetry?

          telemetry.merge! SocketData.new(launcher.binder.ios, config.socket_parser)
                                     .metrics

          telemetry
        end
      end

      # Contents of actual Puma Plugin
      #
      module PluginInstanceMethods
        def start(launcher)
          @launcher = launcher
          @stopped = false

          unless Puma::Plugin::Telemetry.config.enabled?
            log_writer.log 'plugin=telemetry msg="disabled, exiting..."'
            return
          end

          log_writer.log 'plugin=telemetry msg="enabled, setting up runner..."'

          setup_runner
        end

        def run!
          loop do
            break if stopped?

            break unless try_publish

            sleep Puma::Plugin::Telemetry.config.frequency
          end
        end

        def stop!
          @stopped = true
        end

        def stopped?
          !!@stopped
        end

        def call(telemetry)
          Puma::Plugin::Telemetry.config.targets.each do |target|
            target.call(telemetry)
          end
        end

        private

        def setup_runner
          @launcher.events.on_stopped { stop! }

          in_background do
            sleep Puma::Plugin::Telemetry.config.initial_delay
            run!
          end
        end

        def try_publish
          publish
          true
        rescue IOError, Errno::EPIPE
          # Puma closes the IO streams during shutdown, stop publishing
          log_safely 'plugin=telemetry msg="IO stream closed, stopping the runner"'
          false
        rescue StandardError => e
          log_writer.unknown_error(e, nil, 'plugin=telemetry')
          true
        end

        def publish
          log_writer.debug 'plugin=telemetry msg="publish"'

          call(Puma::Plugin::Telemetry.build(@launcher))
        end

        def log_safely(message)
          log_writer.log(message)
        rescue IOError, Errno::EPIPE
          nil
        end

        def log_writer
          if Puma::Const::PUMA_VERSION.to_i < 6
            @launcher.events
          else
            @launcher.log_writer
          end
        end
      end
    end
  end
end

Puma::Plugin.create do
  include Puma::Plugin::Telemetry::PluginInstanceMethods
end
