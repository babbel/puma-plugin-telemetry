# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      RSpec.describe WorkerData do
        describe '#metrics' do
          it 'emits busy threads from Puma stats' do
            data = described_class.new(busy_threads: 3)

            expect(data.metrics(['workers.busy_threads'])).to eq(
              'workers.busy_threads' => 3
            )
          end

          it 'falls back to 0 when puma does not expose busy threads' do
            data = described_class.new({})

            expect(data.metrics(['workers.busy_threads'])).to eq(
              'workers.busy_threads' => 0
            )
          end
        end
      end

      RSpec.describe ClusteredData do
        describe '#metrics' do
          it 'sums busy threads from worker statuses' do
            data = described_class.new(
              worker_status: [
                { last_status: { busy_threads: 2 } },
                { last_status: { busy_threads: 1 } }
              ]
            )

            expect(data.metrics(['workers.busy_threads'])).to eq(
              'workers.busy_threads' => 3
            )
          end
        end
      end
    end
  end
end
