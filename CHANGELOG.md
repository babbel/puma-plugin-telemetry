# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
