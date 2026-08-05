# frozen_string_literal: true

module Puma
  class Plugin
    module Telemetry
      module Targets
        RSpec.describe OpenTelemetryTarget do
          subject(:target) { described_class.new(meter_provider: meter_provider) }

          let(:meter) { double('otel meter', create_gauge: gauge) }
          let(:meter_provider) { double('otel meter provider', meter: meter) }
          let(:gauge) { double('otel gauge', record: nil) }

          it 'prefixes metric names with puma by default' do
            target.call('workers.booted' => 1)

            expect(meter).to have_received(:create_gauge).with('puma.workers.booted')
          end

          it 'records the value on the instrument' do
            target.call('workers.booted' => 1)

            expect(gauge).to have_received(:record).with(1, attributes: {})
          end

          context 'with prefix: nil' do
            subject(:target) { described_class.new(meter_provider: meter_provider, prefix: nil) }

            it 'does not prefix metric names' do
              target.call('workers.booted' => 1)

              expect(meter).to have_received(:create_gauge).with('workers.booted')
            end
          end

          context 'with a custom prefix and suffix' do
            subject(:target) { described_class.new(meter_provider: meter_provider, prefix: 'web', suffix: 'v1') }

            it 'builds the metric name from prefix, metric and suffix' do
              target.call('workers.booted' => 1)

              expect(meter).to have_received(:create_gauge).with('web.workers.booted.v1')
            end
          end
        end
      end
    end
  end
end
