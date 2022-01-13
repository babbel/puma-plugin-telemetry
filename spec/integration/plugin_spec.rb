# frozen_string_literal: true

require "timeout"

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

      context "when defaults" do
        let(:config) { "default" }

        it "doesn't run telemetry" do
          expect(@server.lines).to include(/plugin=telemetry msg="disabled, exiting\.\.\."/)
        end
      end

      describe "with targets" do
        let(:config) { "config" }
        let(:expected_telemetry) do
          {
            "workers.booted" => 1,
            "workers.total" => 1,
            "workers.spawned_threads" => 1,
            "workers.max_threads" => 1,
            "workers.requests_count" => 0,
            "queue.backlog" => 0,
            "queue.capacity" => 1
          }
        end

        it "runs telemetry" do
          expect(@server.lines).to include(/plugin=telemetry msg="enabled, setting up runner\.\.\."/)
        end

        it "executes the first target" do
          true while (line = @server.next_line) !~ /target=01/
          expect(line).to start_with "target=01 telemetry=#{expected_telemetry.inspect}"
        end

        it "executes the second target" do
          true while (line = @server.next_line) !~ /target=02/
          expect(line).to start_with "target=02 telemetry=#{expected_telemetry.inspect}"
        end
      end

      context "when subset of telemetry" do
        let(:config) { "puma_telemetry_subset" }
        let(:expected_telemetry) do
          "{\"queue-backlog\":0,\"workers-spawned_threads\":2,\"workers-max_threads\":4,\"name\":\"Puma::Plugin::Telemetry\",\"message\":\"Publish telemetry\"}\n" # rubocop:disable Layout/LineLength
        end

        it "logs only selected telemetry" do
          true while (line = @server.next_line) !~ /Puma::Plugin::Telemetry/
          expect(line).to start_with expected_telemetry
        end
      end

      context "when dogstatsd target" do
        let(:config) { "dogstatsd" }
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
          true while (line = @server.next_line) !~ /DEBUG -- : Statsd/

          lines = ([line.slice(/workers.*/)] + Array.new(6) { @server.next_line.strip })

          expect(lines).to eq(expected_telemetry)
        end
      end

      context "when sockets telemetry" do
        let(:config) { "sockets" }

        it "logs only selected telemetry" do
          true while (line = @server.next_line) !~ /Puma::Plugin::Telemetry/
          expect(line).to include "\"sockets-backlog\":0"
        end
      end
    end
  end
end
