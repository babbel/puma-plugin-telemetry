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

        it "runs telemetry" do
          expect(@server.lines).to include(/plugin=telemetry msg="enabled, setting up runner\.\.\."/)
        end

        it "executes the first target" do
          true while (line = @server.next_line) !~ /target=01/
          expect(line).to start_with "target=01 telemetry={}"
        end

        it "executes the second target" do
          true while (line = @server.next_line) !~ /target=02/
          expect(line).to start_with "target=02 telemetry={}"
        end
      end
    end
  end
end
