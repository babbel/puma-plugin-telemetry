# frozen_string_literal: true

# Measures the queue time (= time between receiving the request in downstream
# load balancer and starting request in ruby process)
class RequestQueueTimeMiddleware
  ENV_KEY = 'rack.request_queue_time'

  def initialize(app, statsd:, process: Process)
    @app = app
    @statsd = statsd
    @process = process
  end

  def call(env)
    queue_time = measure_queue_time(env)

    report_queue_time(queue_time)

    env[ENV_KEY] = queue_time

    @app.call(env)
  end

  private

  def measure_queue_time(env)
    start_time = queue_start(env)

    return unless start_time

    queue_time = request_start.to_f - start_time.to_f

    queue_time unless queue_time.negative?
  end

  # Get the content of the x-amzn-trace-id header, the epoch time in seconds.
  # see also: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-request-tracing.html
  def queue_start(env)
    value = env['HTTP_X_AMZN_TRACE_ID']
    value&.split('Root=')&.last&.split('-')&.fetch(1)&.to_i(16)
  end

  def request_start
    @process.clock_gettime(Process::CLOCK_REALTIME)
  end

  def report_queue_time(queue_time)
    return if queue_time.nil?

    @statsd.timing('queue.time', queue_time)

    return unless defined?(Datadog) && Datadog.respond_to?(:tracer)

    span = Datadog.tracer.active_root_span
    span&.set_tag('request.queue_time', queue_time)
  end
end
