# frozen_string_literal: true

require 'spec_helper'
require 'socket'

module Puma
  class Plugin
    module Telemetry
      module Targets
        RSpec.describe DatadogStatsdTarget do
          subject(:target) { described_class.new(client: client) }

          let(:client) { instance_double('Datadog::Statsd') }

          before do
            allow(client).to receive(:gauge)
            allow(client).to receive(:flush)
            allow(Socket).to receive(:gethostname).and_return('test-host')
          end

          describe '#call' do
            context 'with workers.busy_threads metric' do
              let(:telemetry) { { 'workers.busy_threads' => 5 } }

              it 'emits with process hostname tag' do
                target.call(telemetry)
                expect(client).to have_received(:gauge).with(
                  'workers.busy_threads',
                  5,
                  tags: ['process:test-host']
                )
              end
            end

            context 'with other metrics' do
              let(:telemetry) { { 'queue.backlog' => 10 } }

              it 'emits without tags' do
                target.call(telemetry)
                expect(client).to have_received(:gauge).with('queue.backlog', 10)
              end
            end

            context 'with mixed metrics' do
              let(:telemetry) do
                {
                  'workers.busy_threads' => 5,
                  'queue.backlog' => 10,
                  'workers.spawned_threads' => 8
                }
              end

              it 'tags only workers.busy_threads' do
                target.call(telemetry)

                expect(client).to have_received(:gauge).with(
                  'workers.busy_threads', 5, tags: ['process:test-host']
                )
                expect(client).to have_received(:gauge).with('queue.backlog', 10)
                expect(client).to have_received(:gauge).with('workers.spawned_threads', 8)
              end
            end

            it 'flushes after emitting all metrics' do
              target.call({ 'queue.backlog' => 1 })
              expect(client).to have_received(:flush).with(sync: true)
            end
          end

          describe 'hostname caching' do
            before { target } # Force subject instantiation before assertions

            it 'retrieves hostname once during initialization' do
              expect(Socket).to have_received(:gethostname).once
            end

            it 'does not call gethostname on each call' do
              target.call({ 'workers.busy_threads' => 1 })
              target.call({ 'workers.busy_threads' => 2 })
              expect(Socket).to have_received(:gethostname).once
            end
          end
        end
      end
    end
  end
end
