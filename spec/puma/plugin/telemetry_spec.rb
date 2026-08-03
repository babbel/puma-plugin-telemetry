# frozen_string_literal: true

require 'timeout'

require 'puma/events'

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

        describe '#run!' do
          let(:log_writer) do
            instance_double(Puma::LogWriter, debug: nil, log: nil, unknown_error: nil).tap do |writer|
              allow(writer).to receive(:error) { exit(1) }
            end
          end

          let(:launcher) { instance_double(Puma::Launcher, log_writer: log_writer) }

          let(:config) do
            Telemetry::Config.new.tap do |c|
              c.frequency = 0
              c.targets = [target]
            end
          end

          let(:calls) { [] }

          before do
            allow(described_class).to receive_messages(config: config, build: {})
            plugin.instance_variable_set(:@launcher, launcher)
          end

          context 'when the target raises IOError' do
            let(:target) do
              proc do
                calls << 1
                raise IOError, 'closed stream'
              end
            end

            it 'stops the loop without raising' do
              expect { Timeout.timeout(1) { plugin.run! } }.not_to raise_error
            end

            it 'stops publishing' do
              Timeout.timeout(1) { plugin.run! }

              expect(calls.size).to eq(1)
            end
          end

          context 'when the target raises Errno::EPIPE' do
            let(:target) do
              proc do
                calls << 1
                raise Errno::EPIPE
              end
            end

            it 'stops the loop' do
              Timeout.timeout(1) { plugin.run! }

              expect(calls.size).to eq(1)
            end
          end

          context 'when the target raises other StandardError' do
            let(:target) do
              proc do
                calls << 1
                raise 'boom' if calls.size == 1

                raise IOError, 'closed stream'
              end
            end

            it 'logs the error without exiting puma and keeps the loop running' do
              Timeout.timeout(1) { plugin.run! }

              expect(log_writer).to have_received(:unknown_error)
                .with(instance_of(RuntimeError), nil, 'plugin=telemetry')
              expect(calls.size).to eq(2)
            end
          end

          context 'when the plugin is stopped' do
            let(:target) { proc { calls << 1 } }

            it 'does not publish' do
              plugin.stop!

              Timeout.timeout(1) { plugin.run! }

              expect(calls).to be_empty
            end
          end
        end

        describe '#start' do
          let(:log_writer) { instance_double(Puma::LogWriter, log: nil) }
          let(:events) { instance_double(Puma::Events) }
          let(:launcher) { instance_double(Puma::Launcher, log_writer: log_writer, events: events) }

          let(:config) do
            Telemetry::Config.new.tap do |c|
              c.enabled = true
              c.initial_delay = 0
            end
          end

          let(:hooks) { [] }

          before do
            allow(described_class).to receive(:config).and_return(config)
            allow(events).to receive(:on_stopped) { |&block| hooks << block }
            allow(plugin).to receive(:in_background)
          end

          it 'registers an on_stopped hook' do
            plugin.start(launcher)

            expect(hooks.size).to eq(1)
          end

          it 'stops the runner when the hook fires' do
            plugin.start(launcher)

            hooks.each(&:call)

            expect(plugin).to be_stopped
          end

          context 'when disabled' do
            before { config.enabled = false }

            it 'does not register an on_stopped hook' do
              plugin.start(launcher)

              expect(hooks).to be_empty
            end
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
