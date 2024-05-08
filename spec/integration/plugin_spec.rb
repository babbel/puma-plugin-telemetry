# frozen_string_literal: true

require 'timeout'
require 'net/http'

TestTakesTooLongError = Class.new(StandardError)

module Puma
  class Plugin
    RSpec.describe Telemetry do
      around do |example|
        @server = nil

        Timeout.timeout(10, TestTakesTooLongError) do
          example.run
        end
      ensure
        @server&.stop
      end

      before do
        @server = ::Server.new(config)
        @server.start
      end

      context 'when defaults' do
        let(:config) { 'default' }

        it "doesn't run telemetry" do
          expect(@server.lines).to include(/plugin=telemetry msg="disabled, exiting\.\.\."/)
        end
      end

      describe 'with targets' do
        let(:config) { 'config' }
        let(:expected_telemetry) do
          {
            'workers.booted' => 1,
            'workers.total' => 1,
            'workers.spawned_threads' => 1,
            'workers.max_threads' => 1,
            'workers.requests_count' => 0,
            'queue.backlog' => 0,
            'queue.capacity' => 1
          }
        end

        it 'runs telemetry' do
          expect(@server.lines).to include(/plugin=telemetry msg="enabled, setting up runner\.\.\."/)
        end

        it 'executes the first target' do
          true until (line = @server.next_line).include?('target=01')
          expect(line).to start_with "target=01 telemetry=#{expected_telemetry.inspect}"
        end

        it 'executes the second target' do
          true until (line = @server.next_line).include?('target=02')
          expect(line).to start_with "target=02 telemetry=#{expected_telemetry.inspect}"
        end
      end

      context 'when subset of telemetry' do
        let(:config) { 'puma_telemetry_subset' }
        let(:expected_telemetry) do
          "{\"queue-backlog\":0,\"workers-spawned_threads\":2,\"workers-max_threads\":4,\"name\":\"Puma::Plugin::Telemetry\",\"message\":\"Publish telemetry\"}\n" # rubocop:disable Layout/LineLength
        end

        it 'logs only selected telemetry' do
          true until (line = @server.next_line).include?('Puma::Plugin::Telemetry')
          expect(line).to start_with expected_telemetry
        end
      end

      context 'when dogstatsd target' do
        let(:config) { 'dogstatsd' }
        let(:expected_telemetry) do
          %w[
            workers.booted:1|g
            workers.total:1|g
            workers.spawned_threads:1|g
            workers.max_threads:1|g
            workers.requests_count:0|g
            queue.backlog:0|g
            queue.capacity:1|g
          ]
        end

        it "doesn't crash" do
          true until (line = @server.next_line).include?('DEBUG -- : Statsd')

          lines = ([line.slice(/workers.*/)] + Array.new(6) { @server.next_line.strip })

          expect(lines).to eq(expected_telemetry)
        end
      end

      context 'when sockets telemetry' do
        let(:config) { 'sockets' }

        def make_request
          Thread.new do
            Net::HTTP.get_response(URI('http://127.0.0.1:59292/'))
          end
        end

        it 'logs socket telemetry' do
          threads = Array.new(2) { make_request }

          sleep 0.1

          threads += Array.new(5) { make_request }

          true while (line = @server.next_line) !~ /sockets.backlog/

          line.strip!

          # either "queue.backlog=1 sockets.backlog=5"
          #     or "queue.backlog=0 sockets.backlog=6"
          #
          # depending on whenever the first 2 requests are
          # pulled at the same time by Puma from backlog
          possible_lines = ['queue.backlog=1 sockets.backlog=5',
                            'queue.backlog=0 sockets.backlog=6']

          expect(possible_lines.include?(line)).to eq(true)

          total = line.split.sum { |kv| kv.split('=').last.to_i }
          expect(total).to eq 6

          threads.each(&:join)
        end
      end
    end
  end
end
