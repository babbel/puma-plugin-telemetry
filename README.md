# Puma::Plugin::Telemetry

Puma plugin which should be able to handle all your metric needs regarding your webserver:

- ability to publish basic puma statistics (like queue backlog) to both logs and Datadog
- ability to add custom target whenever you need it
- ability to monitor puma socket listen queue (!)
- ability to report requests queue time via custom rack middleware - the time request spent between being accepted by Load Balancer and start of its processing by Puma worker

## Install

Add this line to your application's Gemfile:

```ruby
gem "puma-plugin-telemetry"
```

And then execute:

```console
$ bundle install
```

Or install it yourself as:

```console
$ gem install puma-plugin-telemetry
```

## Usage

In your puma configuration file (i.e. `config/puma.rb` or `config/puma/<env>.rb`):

```ruby
plugin "telemetry"

Puma::Plugin::Telemetry.configure do |config|
  config.enabled = true

  # << here rest of the configuration, examples below
end
```

### Basic IO Target

A basic I/O target will emit telemetry data to `STDOUT`, formatted in JSON.

```ruby
config.add_target :io
```

#### Options

This target has configurable `formatter:` and `transform:` options.
The `formatter:` options are

* `:json` _(default)_ - Print the logs in JSON.
* `:logfmt` - Print the logs in key/value pairs, as per `logfmt`.
* `:noop` - A NOOP formatter which returns the telemetry `Hash` unaltered, passing it directly to the `io:` instance.

The `transform:` options are

* `:cloud_watch` _(default)_ - Transforms telemetry keys, replacing dots with dashes to support AWS CloudWatch Log Metrics filters.
* `:logfmt` - Transforms telemetry keys, prepending `sample#` for [L2Met][l2met] consumption.
* `:noop` -  A NOOP transform which returns the telemetry `Hash` unaltered.

### Log target

Emitting to `STDOUT` via the basic `IOTarget` can work for getting telemetry into logs, we also provide an explicit `LogTarget`.
This target will defaults to emitting telemetry at the `INFO` log level via a [standard library `::Logger`][logger] instance.
That default logger will print to `STDOUT` in [the `logfmt` format][logfmt].

```ruby
config.add_target :log
```

You can pass an explicit `logger:` option if you wanted to, for example, use the same logger as Rails.

```ruby
config.add_target :log, logger: Rails.logger
```

This target also has configurable `formatter:` and `transform:` options.
The [possible options are the same as for the `IOTarget`](#options), but the defaults are different.
The `LogTarget` defaults to `formatter: :logfmt`, and `transform: :noop`

[l2met]: https://github.com/ryandotsmith/l2met?tab=readme-ov-file#l2met "l2met - Logs to Metrics"
[logfmt]: https://brandur.org/logfmt "logfmt - Structured log format"
[logger]: https://rubyapi.org/o/logger "Ruby's Logger, from the stdlib"

### Datadog StatsD target

A target for the Datadog StatsD client, that uses batch operation to publish metrics.

**NOTE** Be sure to have the `dogstatsd` gem installed.

```ruby
config.add_target :dogstatsd, client: Datadog::Statsd.new
```

You can provide all the tags, namespaces, and other configuration options as always to `Datadog::Statsd.new` method.

### All available options

For detailed documentation checkout [`Puma::Plugin::Telemetry::Config`](./lib/puma/plugin/telemetry/config.rb) class.

```ruby
Puma::Plugin::Telemetry.configure do |config|
  config.enabled = true
  config.initial_delay = 10
  config.frequency = 30
  config.puma_telemetry = %w[workers.requests_count queue.backlog queue.capacity]
  config.socket_telemetry!
  config.socket_parser = :inspect
  config.add_target :io, formatter: :json, io: StringIO.new
  config.add_target :dogstatsd, client: Datadog::Statsd.new(tags: { env: ENV["RAILS_ENV"] })
  config.add_target :log, logger: Rails.logger, formatter: :logfmt, transform: :l2met)
end
```

### Custom Targets

Target is a simple object that implements `call` methods that accepts `telemetry` hash object. This means it can be super simple `proc` or some sophisticated class calling some external API.

Just be mindful that if the API takes long to call, it will slow down frequency with which telemetry will get reported.

```ruby
  # Example key/value log to `STDOUT` target
  config.add_target ->(telemetry) { puts telemetry.map { |k, v| "#{k}=#{v.inspect}" }.join(" ") }
```

## Extra middleware

This gems comes together with middleware for measuring request queue time, which will be reported in `request.env` and published to given StatsD client.

Example configuration:

```ruby
# in Gemfile add `require` part
gem "puma-plugin-telemetry", require: ["rack/request_queue_time_middleware"]

# in initializer, i.e. `request_queue_time.rb`
Rails.application.config.middleware.insert_after(
  0,
  RequestQueueTimeMiddleware,
  statsd: Datadog::Statsd.new(namespace: "ruby.puma", tags: { "app" => "accounts" })
)

Rails.application.config.log_tags ||= {}
Rails.application.config.log_tags[:queue_time] = ->(req) { req.env[::RequestQueueTimeMiddleware::ENV_KEY] }
```

This will provide proper metric in Datadog and in logs as well. Logs can be transformed into log metrics and used for auto scaling purposes.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Release

All gem releases are manual, in order to create a new release follow:

1. Create new PR (this could be included in feature PR, if it's meant to be released)
   - update `VERSION`, we use [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
   - update `CHANGELOG`
   - merge
2. Draft new release via Github Releases
   - use `v#{VERSION}` as a tag, i.e. `v0.1.0`
   - add release notes based on the Changelog
   - create
3. Gem will get automatically published to given rubygems server

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/babbel/puma-plugin-telemetry.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the puma-plugin-telemetry project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/babbel/puma-plugin-telemetry/blob/master/CODE_OF_CONDUCT.md).
