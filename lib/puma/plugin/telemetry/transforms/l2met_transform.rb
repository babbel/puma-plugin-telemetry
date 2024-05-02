# frozen_string_literal: true

require 'English'
require 'pathname'

module Puma
  class Plugin
    module Telemetry
      module Transforms
        # L2Met (Logs to Metrics) transform that makes all keys a `sample#` in the L2Met format.
        class L2metTransform
          def self.call(telemetry)
            new.call(telemetry)
          end

          def initialize(host_env: ENV, program_name: $PROGRAM_NAME, socket: Socket)
            @host_env = host_env
            @program_name = program_name
            @socket = socket
          end

          def call(telemetry)
            telemetry.transform_keys { |k| "sample##{k}" }.tap do |data|
              data['name'] ||= 'Puma::Plugin::Telemetry'
              data['source'] ||= source
            end
          end

          private

          attr_reader :host_env, :program_name, :socket

          def source
            @source ||= host_env['L2MET_SOURCE'] ||
                        host_env['DYNO'] || # For Heroku
                        host_with_exe_name # Last-ditch effort
          end

          def host_with_exe_name
            "#{socket.gethostname}/#{Pathname(program_name).basename}"
          end
        end
      end
    end
  end
end
