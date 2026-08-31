# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New `LogTarget` for logging metrics to any `::Logger` compatible logger
- New `formatter:` option `:logfmt`.

## [1.2.0]

### Added
- New `:open_telemetry` target. Metric names get the `puma` prefix by default. Requires the `opentelemetry-metrics-sdk` gem in the consumer project (#30)
- New `formatter:` options for the IO target: `:json` and `:passthrough` (#25)
- New `transform:` options for the IO target: `:cloud_watch` and `:passthrough` (#25)

### Changed
- A custom `formatter:` on the IO target now receives the transformed telemetry. Pass `transform: :passthrough` to get the same telemetry as before (#25)

### Dropped
- The `Targets::IOTarget::JSONFormatter` constant. Its behavior moved to `Formatters::JSONFormatter` and `Transforms::CloudWatchTransform` (#25)

### Fixed
- Stop the telemetry runner when puma shuts down or when the target IO stream is closed. This prevents `IOError: closed stream` errors during shutdown (#31, #45)
- Log target errors with `unknown_error` instead of `error`, so a failed publish does not make puma exit (#31, #45)

## [1.1.6]

### Changed
- Allow puma 8 (#42)

## [1.1.5]

### Changed
- Allow puma 7 (#40)
- Updated gems in the lockfile

### Added
- Check for support for 'ubuntu-24.04'
- Check for support for Ruby 3.4

### Dropped
- Check for support for 'ubuntu-20.04'
- Check for support for Ruby 2.6 and 2.7

## [1.1.4]

### Changed
- Updated gems in the lockfile

## [1.1.3]

### Changed
- Updated gems in the lockfile

### Added
- Support for Ruby 3.2 and 3.3

### Dropped
- Check for support for 'ubuntu-18.04'

## [1.1.2]

- Add Puma 6 compatibility
## [1.1.1]

Public release.

## [1.1.0]

Out of beta testing, reading for usage. Following is a recap from Alpha & Beta releases.

### Added
- new metric: `sockets.backlog` (disabled by default), pulls information from Puma
  sockets about the state of their backlogs. This together with `queue.backlog`
  allows for full insights into total number of requests waiting to be processed
- `config.sockets_telemetry!` option to enable sockets telemetry
- `config.socket_parser` option to allow custom parser implementation as needed
- Datadog widgets examples under `docs/examples.md`

## [1.1.0 Beta]

### Added

Different ways to parse `Socket::Option`. Mainly due to the fact that `#inspect` can't
generate proper data on AWS Fargate, which runs Amazon Linux 2 with 4.14 kernel. So now
besides `#inspect` there's also `#unpack` that parses binary data and picks proper field.

It depends on the kernel, but new fields are usually added at the end of the `tcp_info`
struct, so it should more or less stay stable.

You can configure it by passing in `config.socket_parser = :inspect` or
`config.socket_parser = ->(opt) { your implementation }`.

## [1.1.0 Alpha]

### Added

Socket telemetry, and to be more precise new metric: `sockets.backlog`. If enabled it will
pull information from Puma sockets about the state of their backlogs (requests waiting to
be acknowledged by Puma). It will be exposed under `sockets-backlog` metric.

You can enable and test it via `config.sockets_telemetry!` option.

## [1.0.0] - 2021-09-08
### Added
- Release to Github Packages
- Explicitly flush datadog metrics after publishing them
- Middleware for measuring and tracking request queue time

### Changed
- Replace `statsd.batch` with direct calls, as it aggregates metrics interally by default now.
  Also `#batch` method is deprecated and will be removed in version 6 of Datadog Statsd client.

## [0.3.1] - 2021-03-26
### Changed
- IO target replaces dots in telemetry keys with dashes for better integration with AWS CloudWatch

## [0.3.0] - 2020-12-21
### Added
- Datadog Target integration tests

### Fixed
- Datadog Target

## [0.2.0] - 2020-12-21
### Fixed
- Removed debugging information

## [0.1.0] - 2020-12-18
### Added
- Core Plugin
- Telemetry generation
- IO Target with JSON formatter
- Datadog Statsd Target
