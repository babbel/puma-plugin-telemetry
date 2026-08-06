# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      RSpec.describe Config do
        subject(:config) { described_class.new }

        describe '#enabled?' do
          context 'when default' do
            it { expect(config.enabled?).to eq false }
          end

          context 'when enabled' do
            before { config.enabled = true }

            it { expect(config.enabled?).to eq true }
          end
        end

        describe '#puma_telemetry' do
          context 'when puma reports busy threads' do
            before { stub_const('::Puma::Const::PUMA_VERSION', '6.6.0') }

            it 'includes workers.busy_threads by default' do
              expect(config.puma_telemetry).to include('workers.busy_threads')
            end

            it 'accepts workers.busy_threads' do
              config.puma_telemetry = ['workers.busy_threads']

              expect(config.puma_telemetry).to eq ['workers.busy_threads']
            end
          end

          context 'when puma is too old to report busy threads' do
            before { stub_const('::Puma::Const::PUMA_VERSION', '6.5.0') }

            it 'drops workers.busy_threads from the defaults' do
              expect(config.puma_telemetry).not_to include('workers.busy_threads')
            end

            it 'keeps the remaining default telemetry' do
              expect(config.puma_telemetry).to eq(described_class::DEFAULT_PUMA_TELEMETRY - ['workers.busy_threads'])
            end

            it 'raises when workers.busy_threads is selected explicitly' do
              expect { config.puma_telemetry = ['workers.busy_threads'] }
                .to raise_error(Telemetry::Error, /requires puma >= 6\.6, but puma 6\.5\.0 is installed/)
            end

            it 'allows selecting other telemetry' do
              config.puma_telemetry = ['queue.backlog']

              expect(config.puma_telemetry).to eq ['queue.backlog']
            end
          end
        end

        describe '#socket_telemetry!' do
          context 'when TCP_INFO is available' do
            before do
              stub_const('Socket::SOL_TCP', 6)
              stub_const('Socket::TCP_INFO', 11)
            end

            it 'enables socket telemetry' do
              config.socket_telemetry!

              expect(config.socket_telemetry?).to eq true
            end
          end

          context 'when TCP_INFO is not available' do
            before { hide_const('Socket::TCP_INFO') }

            it 'warns and keeps socket telemetry disabled' do
              expect { config.socket_telemetry! }
                .to output(/socket_telemetry is disabled/).to_stderr

              expect(config.socket_telemetry?).to eq false
            end

            it 'disables socket telemetry when previously enabled' do
              config.socket_telemetry = true

              expect { config.socket_telemetry! }
                .to output(/socket_telemetry is disabled/).to_stderr

              expect(config.socket_telemetry?).to eq false
            end
          end
        end

        describe '#add_target' do
          context 'when built in: IO' do
            it 'adds new target' do
              expect { config.add_target(:io) }.to change(config.targets, :size).by(1)
            end

            it 'adds new IO Target' do
              config.add_target(:io)
              expect(config.targets.first).to be_a(Telemetry::Targets::IOTarget)
            end
          end

          context 'when built in: Datadog' do
            let(:client) { instance_double('statsd') }

            it 'adds new target' do
              expect do
                config.add_target(:dogstatsd, client: client)
              end.to change(config.targets, :size).by(1)
            end

            it 'adds new Datadog Target' do
              config.add_target(:dogstatsd, client: client)
              expect(config.targets.first).to be_a(Telemetry::Targets::DatadogStatsdTarget)
            end
          end

          context 'when built in: Open Telemetry' do
            let(:meter_provider) { double('otel meter provider', meter: double('otel meter')) }

            it 'adds new target' do
              expect do
                config.add_target(:open_telemetry, meter_provider: meter_provider)
              end.to change(config.targets, :size).by(1)
            end

            it 'adds new Open Telemetry Target' do
              config.add_target(:open_telemetry, meter_provider: meter_provider)
              expect(config.targets.first).to be_a(Telemetry::Targets::OpenTelemetryTarget)
            end
          end

          context 'when custom' do
            let(:target) { proc { |telemetry| puts telemetry.inspect } }

            it 'adds new target' do
              expect do
                config.add_target(target)
              end.to change(config.targets, :size).by(1)
            end

            it 'adds new Custom Target' do
              config.add_target(target)
              expect(config.targets.first).to be_a(Proc)
            end
          end

          context 'when multiple targets' do
            it 'adds new targets' do
              expect do
                config.add_target(proc { |telemetry| puts telemetry.inspect })
                config.add_target(:io)
                config.add_target(:io)
              end.to change(config.targets, :size).by(3)
            end
          end
        end
      end
    end
  end
end
