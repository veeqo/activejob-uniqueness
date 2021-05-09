# frozen_string_literal: true

require 'bundler/setup'
require 'pry-byebug'

begin
  require 'sidekiq/api'
rescue LoadError
  require 'active_job/uniqueness'
else
  require 'active_job/uniqueness/sidekiq_patch'
end

Dir['./spec/support/**/*.rb'].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  if defined?(Sidekiq)
    config.filter_run_excluding(sidekiq: :job_death) if Gem::Version.new(Sidekiq::VERSION) < Gem::Version.new('5.1')
  else
    config.filter_run_excluding(:sidekiq)
  end
end

RSpec::Matchers.define_negated_matcher :not_change, :change
