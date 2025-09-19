# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Transforms
        RSpec.describe L2metTransform do
          subject(:transform) { described_class.new(host_env: fake_env, socket: fake_socket) }

          let(:fake_env) { {} }
          let(:fake_socket) { class_double('Socket', gethostname: 'GIBSON') }

          it 'transforms the telemetry key to an L2Met sample' do
            data = transform.call('widgets.size' => 2, 'speed' => 10.5)

            expect(data).to include('sample#widgets.size' => 2, 'sample#speed' => 10.5)
          end

          it 'handles symbol keys' do
            data = transform.call('queue.depth': 2)

            expect(data).to include('sample#queue.depth' => 2)
          end

          it 'adds source from L2MET_SOURCE in ENV' do
            fake_env['L2MET_SOURCE'] = 'some-machine'

            data = transform.call('queue.depth' => 2)

            expect(data).to include('source' => 'some-machine')
          end

          it 'adds source from DYNO in ENV' do
            fake_env['DYNO'] = 'web.10'

            data = transform.call('queue.depth' => 2)

            expect(data).to include('source' => 'web.10')
          end

          it 'adds source from $PROGRAM_NAME when L2MET_SOURCE nor DYNO are in ENV' do
            data = transform.call('queue.depth' => 2)

            expect(data).to include('source' => 'GIBSON/rspec')
          end
        end
      end
    end
  end
end
