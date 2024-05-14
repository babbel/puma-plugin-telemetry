# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Targets
        RSpec.describe LogTarget do
          subject(:target) { described_class.new(logger: logger, formatter: logfmt) }
          let(:logger) { ::Logger.new(io) }
          let(:io) { StringIO.new }
          let(:telemetry) { { foo: 'bar' } }
          let(:logfmt) { ->(telemetry) { telemetry.map { |k, v| "#{k}=#{v}" }.join(' ') } }

          it 'logs the telemetry at the INFO level' do
            target.call(telemetry)

            expect(io.string).to include('INFO').and(include('foo=bar'))
          end
        end
      end
    end
  end
end
