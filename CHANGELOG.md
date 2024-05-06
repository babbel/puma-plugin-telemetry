# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] TBD

### Added
- Add new `LogTarget`
- Introduce new `formatter:` options: `:json`, `:logfmt`, and `:noop`
- Introduce new `transform:` options: `:cloud_watch`, `:l2met`, and `:noop`

## [1.1.4] 2024-05-29

### Changed
- Updated gems in the lockfile

## [1.1.3] 2024-05-13

### Changed
- Updated gems in the lockfile

### Added
- Support for Ruby 3.2 and 3.3

### Dropped
- Check for support for 'ubuntu-18.04'

## [1.1.2] 2022-12-28

- Add Puma 6 compatibility

## [1.1.1] 2022-06-22

Public release.

## [1.1.0] 2022-06-22

Out of beta testing, reading for usage. Following is a recap from Alpha & Beta releases.

### Added
- new metric: `sockets.backlog` (disabled by default), pulls information from Puma
  sockets about the state of their backlogs. This together with `queue.backlog`
  allows for full insights into total number of requests waiting to be processed
- `config.sockets_telemetry!` option to enable sockets telemetry
- `config.socket_parser` option to allow custom parser implementation as needed
- Datadog widgets examples under `docs/examples.md`

## [1.1.0 Beta] ???
### Added

Different ways to parse `Socket::Option`. Mainly due to the fact that `#inspect` can't
generate proper data on AWS Fargate, which runs Amazon Linux 2 with 4.14 kernel. So now
besides `#inspect` there's also `#unpack` that parses binary data and picks proper field.

It depends on the kernel, but new fields are usually added at the end of the `tcp_info`
struct, so it should more or less stay stable.

You can configure it by passing in `config.socket_parser = :inspect` or
`config.socket_parser = ->(opt) { your implementation }`.

## [1.1.0 Alpha] ???
### Added

Socket telemetry, and to be more precise new metric: `sockets.backlog`. If enabled it will
pull information from Puma sockets about the state of their backlogs (requests waiting to
be acknowledged by Puma). It will be exposed under `sockets-backlog` metric.

You can enable and test it via `config.sockets_telemetry!` option.

## [1.0.0] 2021-09-08
### Added
- Release to GitHub Packages
- Explicitly flush Datadog metrics after publishing them
- Middleware for measuring and tracking request queue time

### Changed
- Replace `statsd.batch` with direct calls, as it aggregates metrics internally by default now.
  Also `#batch` method is deprecated and will be removed in version 6 of Datadog Statsd client.

## [0.3.1] 2021-03-26
### Changed
- IO target replaces dots in telemetry keys with dashes for better integration with AWS CloudWatch

## [0.3.0] 2020-12-21
### Added
- Datadog Target integration tests

### Fixed
- Datadog Target

## [0.2.0] 2020-12-21
### Fixed
- Removed debugging information

## [0.1.0] 2020-12-18
### Added
- Core Plugin
- Telemetry generation
- IO Target with JSON formatter
- Datadog Statsd Target
