# frozen_string_literal: true

require 'active_job'
require 'redlock'

require 'active_job/uniqueness/version'
require 'active_job/uniqueness/errors'
require 'active_job/uniqueness/log_subscriber'
require 'active_job/uniqueness/active_job_patch'

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
        return @config if defined?(@config)

        @config = ActiveJob::Uniqueness::Configuration.new
      end

      def lock_manager
        return @lock_manager if defined?(@lock_manager)

        servers = if config.pool.present?
                    [connection_pool]
                  else
                    config.redlock_servers
                  end
        @lock_manager = ActiveJob::Uniqueness::LockManager.new(servers, config.redlock_options)
      end

      def connection_pool
        url = config.pool[:url] || ENV.fetch('REDIS_URL', 'redis://localhost:6379')
        ConnectionPool.new(size: config.pool[:size] || 5, timeout: config.pool[:timeout] || 1) do
          Redis.new(url: url)
        end
      end

      def unlock!(**args)
        lock_manager.delete_locks(ActiveJob::Uniqueness::LockKey.new(**args).wildcard_key)
      end

      def test_mode!
        @lock_manager = ActiveJob::Uniqueness::TestLockManager.new
      end

      def reset_manager!
        remove_instance_variable(:@lock_manager)
      end

      def reset_config!
        remove_instance_variable(:@config)
      end
    end
  end
end
