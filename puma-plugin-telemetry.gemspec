# frozen_string_literal: true

require_relative 'lib/puma/plugin/telemetry/version'

Gem::Specification.new do |spec| # rubocop:disable Metrics/BlockLength
  spec.name    = 'puma-plugin-telemetry'
  spec.version = Puma::Plugin::Telemetry::VERSION
  spec.authors = ['Leszek Zalewski']
  spec.email   = ['tnt@babbel.com']

  spec.license = 'MIT'

  spec.summary     = 'Puma plugin, adding ability to publish various metrics to your prefered targets.'
  spec.description = <<~TXT
    Puma plugin which should be able to handle all your metric needs regarding your webserver:

    - ability to publish basic puma statistics (like queue backlog) to both logs and datadog
    - ability to add custom target whenever you need it
    - ability to monitor puma socket listen queue (!)
    - ability to report requests queue time via custom rack middleware - the time request spent between being accepted by Load Balancer and start of its processing by Puma worker
  TXT

  spec.homepage = 'https://github.com/babbel/puma-plugin-telemetry'

  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['github_repo'] = 'ssh://github.com/babbel/puma-plugin-telemetry'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ spec/ .git .github Gemfile])
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'puma', '< 8'
end
