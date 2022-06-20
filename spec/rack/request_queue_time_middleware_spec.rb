# frozen_string_literal: true

require_relative '../../lib/rack/request_queue_time_middleware'
require 'rack'
require 'datadog/statsd'

# Provide mock as Timecop doesn't support such case
class MockedProcess
  def initialize
    @clock = Process.clock_gettime(Process::CLOCK_REALTIME)
  end

  def microseconds
    @clock - @clock.floor
  end

  def amz_ago(ago)
    (@clock - ago).to_i.to_s(16)
  end

  def clock_gettime(_arg)
    @clock
  end
end

RSpec.describe RequestQueueTimeMiddleware do
  subject(:make_request) { request.get('/some/path', headers) }

  let(:request) do
    Rack::MockRequest.new(described_class.new(->(env) { [200, env, 'Bazinga!'] },
                                              statsd: statsd,
                                              process: process))
  end

  let(:process) { MockedProcess.new }
  let(:statsd) { instance_double(Datadog::Statsd) }
  let(:headers) { { 'HTTP_X_AMZN_TRACE_ID' => header } }
  let(:header) do
    %W[
      Self=1-#{process.amz_ago(expected_duration - 6)}-12456789abcdef012345678
      Root=1-#{process.amz_ago(expected_duration)}-abcdef012345678912345678
    ].join(';')
  end

  let(:expected_duration) { 12 + process.microseconds }

  context 'when correct header' do
    it 'reports queue time' do
      expect(statsd).to receive(:timing).with('queue.time', expected_duration)
      expect(make_request.status).to eq(200)
    end
  end

  context 'when header missing' do
    let(:headers) { {} }

    it "doesn't report anything" do
      expect(statsd).not_to receive(:timing)
      expect(make_request.status).to eq(200)
    end
  end

  context 'when header in the future' do
    let(:expected_duration) { -(12 + process.microseconds) }

    it "doesn't report anything" do
      expect(statsd).not_to receive(:timing)
      expect(make_request.status).to eq(200)
    end
  end
end
