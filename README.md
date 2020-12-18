# Puma::Plugin::Telemetry

Puma plugin adding ability to publish various metrics to your prefered targets.

## Install

Add this line to your application's Gemfile:

```ruby
gem "puma-plugin-telemetry"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install puma-plugin-telemetry

## Usage

In your puma configuration file (i.e. `config/puma.rb` or `config/puma/<env>.rb`):

```ruby
plugin "telemetry"

Puma::Plugin::Telemetry.configure do |config|
  config.enabled = true

  # << here rest of the configuration, examples below
end
```

### Basic

Output telemetry as JSON to STDOUT

```ruby
  config.add_target :io
```

### Datadog statsd target

Given gem provides built in target for Datadog Statsd client, that uses batch operation to publish metrics.

**NOTE** Be sure to have `dogstatsd` gem installed.

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
  config.add_target :io, formatter: :json, io: StringIO.new
  config.add_target :dogstatsd, client: Datadog::Statsd.new(tags: { env: ENV["RAILS_ENV"] })
end
```

### Custom Targets

Target is a simple object that implements `call` methods that accepts `telemetry` hash object. This means it can be super simple `proc` or some sofisticated class calling some external API.

Just be mindful that if the API takes long to call, it will slow down frequency with which telemetry will get reported.

```ruby
  # Example logfmt to stdout target
  config.add_target proc { |telemetry| puts telemetry.map { |k, v| "#{k}=#{v.inspect}" }.join(" ") }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

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

Bug reports and pull requests are welcome on GitHub at https://github.com/lessonnine/puma-plugin-telemetry.

## License

UNLICENSED © Lesson Nine GmbH
