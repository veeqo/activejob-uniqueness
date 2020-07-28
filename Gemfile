# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in activejob-uniqueness.gemspec
gemspec

gem 'activejob', ENV.fetch('ACTIVEJOB_VERSION', '~> 4.2.11')

if ENV['SIDEKIQ_VERSION']
  gem 'sidekiq', ENV.fetch('SIDEKIQ_VERSION')
  gem 'railties', ENV.fetch('ACTIVEJOB_VERSION')
end
