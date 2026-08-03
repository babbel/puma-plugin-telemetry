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
