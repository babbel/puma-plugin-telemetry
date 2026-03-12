# frozen_string_literal: true

require 'spec_helper'

module Puma
  class Plugin
    module Telemetry
      RSpec.describe WorkerData do
        subject(:data) { described_class.new(stats) }

        describe '#workers_busy_threads' do
          context 'when busy_threads is present' do
            let(:stats) { { busy_threads: 5 } }

            it 'returns the busy_threads value' do
              expect(data.workers_busy_threads).to eq(5)
            end
          end

          context 'when busy_threads is missing' do
            let(:stats) { {} }

            it 'returns 0' do
              expect(data.workers_busy_threads).to eq(0)
            end
          end
        end
      end

      RSpec.describe ClusteredData do
        subject(:data) { described_class.new(stats) }

        describe '#workers_busy_threads' do
          context 'when workers have busy_threads' do
            let(:stats) do
              {
                worker_status: [
                  { last_status: { busy_threads: 3 } },
                  { last_status: { busy_threads: 2 } }
                ]
              }
            end

            it 'sums busy_threads across all workers' do
              expect(data.workers_busy_threads).to eq(5)
            end
          end

          context 'when some workers are missing busy_threads' do
            let(:stats) do
              {
                worker_status: [
                  { last_status: { busy_threads: 3 } },
                  { last_status: {} }
                ]
              }
            end

            it 'treats missing values as 0' do
              expect(data.workers_busy_threads).to eq(3)
            end
          end

          context 'when no workers have busy_threads' do
            let(:stats) do
              {
                worker_status: [
                  { last_status: {} },
                  { last_status: {} }
                ]
              }
            end

            it 'returns 0' do
              expect(data.workers_busy_threads).to eq(0)
            end
          end
        end
      end
    end
  end
end
