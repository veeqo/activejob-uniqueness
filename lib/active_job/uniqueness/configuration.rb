# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    # Use /config/initializer/activejob_uniqueness.rb to configure ActiveJob::Uniqueness
    #
    # ActiveJob::Uniqueness.configure do |c|
    #   c.lock_ttl = 3.hours
    # end
    #
    # Plain accessors instead of ActiveSupport::Configurable, which is
    # deprecated without replacement and removed in Rails 8.2. The gem only
    # ever reads configuration through the memoized instance
    # (ActiveJob::Uniqueness.config), so instance-level accessors are a
    # drop-in replacement.
    class Configuration
      attr_accessor :lock_ttl, :lock_prefix, :redlock_servers, :redlock_options,
                    :lock_strategies, :digest_method
      attr_reader :on_conflict, :on_redis_connection_error

      def initialize
        @lock_ttl = 86_400 # 1.day
        @lock_prefix = 'activejob_uniqueness'
        @on_conflict = :raise
        @on_redis_connection_error = :raise
        @redlock_servers = [ENV.fetch('REDIS_URL', 'redis://localhost:6379')]
        @redlock_options = { retry_count: 0 }
        @lock_strategies = {}
        require 'openssl'
        @digest_method = OpenSSL::Digest::MD5
      end

      def on_conflict=(action)
        validate_on_conflict_action!(action)

        @on_conflict = action
      end

      def validate_on_conflict_action!(action)
        return if action.nil? || %i[log raise].include?(action) || action.respond_to?(:call)

        raise ActiveJob::Uniqueness::InvalidOnConflictAction, "Unexpected '#{action}' action on conflict"
      end

      def on_redis_connection_error=(action)
        validate_on_redis_connection_error!(action)

        @on_redis_connection_error = action
      end

      def validate_on_redis_connection_error!(action)
        return if action.nil? || action == :raise || action.respond_to?(:call)

        raise ActiveJob::Uniqueness::InvalidOnConflictAction, "Unexpected '#{action}' action on_redis_connection_error"
      end
    end
  end
end
