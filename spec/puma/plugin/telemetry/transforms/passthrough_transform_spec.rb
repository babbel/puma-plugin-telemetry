# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Transforms
        RSpec.describe PassthroughTransform do
          subject(:transform) { described_class }

          it 'returns the telemetry, unalterted' do
            telmetry_data = { 'foo' => 'bar' }
            transformed_data = transform.call(telmetry_data)

            expect(transformed_data).to eq(telmetry_data)
          end
        end
      end
    end
  end
end
