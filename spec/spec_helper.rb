# frozen_string_literal: true

require 'bundler/setup'
require 'active_job'
require 'active_job/uniqueness'
require 'pry-byebug'

ActiveJob::Base.queue_adapter = :test

ActiveJob::Base.logger = ActiveSupport::TaggedLogging.new(Logger.new(nil))

ActiveJob::Uniqueness.configure do |c|
  c.redlock_options = { redis_timeout: 0.01, retry_count: 0 } # no reason to wait in tests
end

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end

RSpec::Matchers.define_negated_matcher :not_change, :change
