# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Targets
        RSpec.describe JSONFormatter do
          subject(:formatter) { described_class }

          it 'formats the telemetry as a JSON string' do
            string = formatter.call('foo' => 'bar')

            data = ::JSON.parse(string)
            expect(data.fetch('foo')).to eq('bar')
          end

          it 'handles symbol keys' do
            string = formatter.call(foo: 'bar')

            data = ::JSON.parse(string)
            expect(data.fetch('foo')).to eq('bar')
          end

          it 'replaces dots with dashes in keys' do
            string = formatter.call('the.foo' => 'the.bar')

            data = ::JSON.parse(string)
            expect(data.fetch('the-foo')).to eq('the.bar')
          end
        end
      end
    end
  end
end
