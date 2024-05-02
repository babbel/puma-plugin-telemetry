# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Transforms
        RSpec.describe L2metTransform do
          subject(:transform) { described_class }

          it 'transforms the telemetry key to an L2Met sample' do
            data = transform.call('widgets.size' => 2, 'speed' => 10.5)

            expect(data).to include('sample#widgets.size' => 2, 'sample#speed' => 10.5)
          end

          it 'handles symbol keys' do
            data = transform.call('queue.depth': 2)

            expect(data).to include('sample#queue.depth' => 2)
          end
        end
      end
    end
  end
end
