# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Formatters
        # Logfmt formatter, expects `call` method accepting telemetry hash
        #
        class LogfmtFormatter
          def self.call(telemetry)
            telemetry.map { |k, v| "#{String(k)}=#{v.inspect}" }.join(' ')
          end
        end
      end
    end
  end
end
