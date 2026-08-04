# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Formatters
        RSpec.describe PassthroughFormatter do
          subject(:formatter) { described_class }

          it 'returns the telemetry, unaltered' do
            telemetry_data = { 'foo' => 'bar' }
            formatted_data = formatter.call(telemetry_data)

            expect(formatted_data).to eq(telemetry_data)
          end
        end
      end
    end
  end
end
