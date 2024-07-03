# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Formatters
        RSpec.describe LogfmtFormatter do
          subject(:formatter) { described_class }

          it 'formats the telemetry in key/value pairs' do
            string = formatter.call('foo' => 'bar', 'count' => 2)

            expect(string).to include('foo="bar"').and(include('count=2'))
          end

          it 'handles symbol keys' do
            string = formatter.call(foo: 'bar')

            expect(string).to include('foo="bar"')
          end
        end
      end
    end
  end
end
