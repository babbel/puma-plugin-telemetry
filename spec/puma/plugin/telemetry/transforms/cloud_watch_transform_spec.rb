# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Transforms
        RSpec.describe CloudWatchTranform do
          subject(:transform) { described_class }

          it 'replaces dots with dashes in keys' do
            data = transform.call('the.foo' => 'the.bar')

            expect(data.fetch('the-foo')).to eq('the.bar')
          end

          it 'handles symbol keys' do
            data = transform.call(foo: 'bar')

            expect(data.fetch('foo')).to eq('bar')
          end
        end
      end
    end
  end
end
