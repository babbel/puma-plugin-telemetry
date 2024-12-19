# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in puma-plugin-telemetry.gemspec
gemspec

group :development, :test do
  gem 'dogstatsd-ruby'
  gem 'opentelemetry-exporter-otlp'
  gem 'opentelemetry-exporter-otlp-metrics', github: 'joshwestbrook/opentelemetry-ruby', branch: 'gauge-encoding', glob: 'exporter/otlp-metrics/*.gemspec' # TODO: Once gauge exporting is released, we can switch back to released version: https://github.com/open-telemetry/opentelemetry-ruby/pull/1780
  gem 'opentelemetry-metrics-api', github: 'open-telemetry/opentelemetry-ruby', glob: 'metrics_api/*.gemspec' # TODO: Once gauges are released, we can switch back to released version: https://github.com/open-telemetry/opentelemetry-ruby/commit/bb5159598850b42e9da54608a8af2fbe422193b7
  gem 'opentelemetry-metrics-sdk', github: 'open-telemetry/opentelemetry-ruby', glob: 'metrics_sdk/*.gemspec' # TODO: Once gauges are released, we can switch back to released version: https://github.com/open-telemetry/opentelemetry-ruby/commit/bb5159598850b42e9da54608a8af2fbe422193b7
  gem 'opentelemetry-sdk'
end

gem 'rack'
gem 'rake', '~> 13.0'
gem 'rspec', '~> 3.0'
gem 'rubocop', '~> 1.5'
gem 'rubocop-performance', '~> 1.9'
