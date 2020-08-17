# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'redlock'
require 'openssl'
require 'active_job/uniqueness/version'
require 'active_job/uniqueness/errors'
require 'active_job/uniqueness/log_subscriber'
require 'active_job/uniqueness/active_job_patch'

begin
  require 'sidekiq/api'
rescue LoadError
  # ¯\_(ツ)_/¯
else
  require 'active_job/uniqueness/sidekiq_patch'
end

module ActiveJob
  module Uniqueness
    extend ActiveSupport::Autoload

    autoload :Configuration
    autoload :LockKey
    autoload :Strategies
    autoload :LockManager
    autoload :TestLockManager

    class << self
      def configure
        yield config
      end

      def config
        @config ||= ActiveJob::Uniqueness::Configuration.new
      end

      def lock_manager
        @lock_manager ||= ActiveJob::Uniqueness::LockManager.new(config.redlock_servers, config.redlock_options)
      end

      def unlock!(*args)
        lock_manager.delete_locks(ActiveJob::Uniqueness::LockKey.new(*args).wildcard_key)
      end

      def test_mode!
        @lock_manager = ActiveJob::Uniqueness::TestLockManager.new
      end
    end
  end
end
