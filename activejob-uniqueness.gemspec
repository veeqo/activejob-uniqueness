# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_job/uniqueness/version'

Gem::Specification.new do |spec|
  spec.name          = 'activejob-uniqueness'
  spec.version       = ActiveJob::Uniqueness::VERSION
  spec.authors       = ['Rustam Sharshenov']
  spec.email         = ['rustam@sharshenov.com']

  spec.summary       = 'Ensure uniqueness of your ActiveJob jobs'
  spec.description   = 'Ensure uniqueness of your ActiveJob jobs'
  spec.homepage      = 'https://github.com/veeqo/activejob-uniqueness'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = spec.homepage
    spec.metadata['changelog_uri'] = 'https://github.com/veeqo/activejob-uniqueness/blob/main/CHANGELOG.md'
    spec.metadata['rubygems_mfa_required'] = 'true'
  end

  spec.files = Dir['CHANGELOG.md', 'LICENSE.txt', 'README.md', 'lib/**/*']

  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.5'

  spec.add_dependency 'activejob', '>= 4.2', '< 8.1'
  spec.add_dependency 'redlock', '>= 2.0', '< 3'

  spec.add_development_dependency 'appraisal', '~> 2.3.0'
  spec.add_development_dependency 'bundler', '>= 2.0'
  spec.add_development_dependency 'pry-byebug', '> 3.6.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.28'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.10'
end
