# frozen_string_literal: true

module Puma
  class Plugin
    RSpec.describe Telemetry do
      it 'has a version number' do
        expect(Telemetry::VERSION).not_to be_nil
      end

      describe '.config' do
        it 'has a default configuration' do
          expect(described_class.config).not_to be_nil
        end
      end

      describe '.build' do
        let(:default_telemetry) do
          {
            'workers.booted' => 1,
            'workers.total' => 1,
            'workers.max_threads' => 0,
            'workers.requests_count' => 0,
            'workers.spawned_threads' => 0,
            'queue.backlog' => 0,
            'queue.capacity' => 0
          }
        end

        it 'returns default telemetry hash' do
          allow(::Puma).to receive(:stats_hash).and_return({})
          expect(described_class.build).to eq(default_telemetry)
        end
      end

      context 'when Plugin' do
        subject(:plugin) { Puma::Plugins.find('telemetry').new }

        describe 'plugin registration' do
          it 'works' do
            expect(plugin).to respond_to(:start)
          end
        end

        describe '.call' do
          let(:config) do
            Telemetry::Config.new.tap do |c|
              c.targets = targets
            end
          end

          let(:targets) { [instance_spy(Proc), instance_spy(Proc)] }
          let(:telemetry) { { foo: :bar } }

          before do
            allow(described_class).to receive(:config).and_return(config)
          end

          it 'executes first target with telemetry' do
            plugin.call(telemetry)
            expect(targets[0]).to have_received(:call).with(telemetry)
          end

          it 'executes last target with telemetry' do
            plugin.call(telemetry)
            expect(targets[1]).to have_received(:call).with(telemetry)
          end

          it 'returns list of targets called' do
            expect(plugin.call(telemetry)).to eq(targets)
          end
        end
      end
    end
  end
end
