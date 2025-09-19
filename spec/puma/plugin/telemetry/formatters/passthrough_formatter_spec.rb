# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Formatters
        RSpec.describe PassthroughFormatter do
          subject(:formatter) { described_class }

          it 'returns the telemetry, unalterted' do
            telmetry_data = { 'foo' => 'bar' }
            formatted_data = formatter.call(telmetry_data)

            expect(formatted_data).to eq(telmetry_data)
          end
        end
      end
    end
  end
end
