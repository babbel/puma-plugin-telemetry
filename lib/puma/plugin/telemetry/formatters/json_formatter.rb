# frozen_string_literal: true

require 'json'

module Puma
  class Plugin
    module Telemetry
      module Formatters
        # JSON formatter, expects `call` method accepting telemetry hash
        #
        class JSONFormatter
          def self.call(telemetry)
            ::JSON.dump(telemetry)
          end
        end
      end
    end
  end
end
