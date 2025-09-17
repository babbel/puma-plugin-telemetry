# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Targets
        RSpec.describe IOTarget do
          subject(:target) { described_class.new(io: io, formatter: logfmt) }
          let(:io) { StringIO.new }
          let(:telemetry) { { foo: 'bar' } }
          let(:logfmt) { ->(telemetry) { telemetry.map { |k, v| "#{k}=#{v}" }.join(' ') } }

          it 'puts to the io object' do
            target.call(telemetry)

            expect(io.string).to include('foo=bar')
          end
        end
      end
    end
  end
end
