# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    # Use /config/initializer/activejob_uniqueness.rb to configure ActiveJob::Uniqueness
    #
    # ActiveJob::Uniqueness.configure do |c|
    #   c.lock_ttl = 3.hours
    # end
    #
    class Configuration
      include ActiveSupport::Configurable

      config_accessor(:lock_ttl) { 86_400 } # 1.day
      config_accessor(:lock_prefix) { 'activejob_uniqueness' }
      config_accessor(:on_conflict) { :raise }
      config_accessor(:redlock_servers) { [ENV.fetch('REDIS_URL', 'redis://localhost:6379')] }
      config_accessor(:redlock_options) { { retry_count: 0 } }
      config_accessor(:lock_strategies) { {} }

      config_accessor(:digest_method) do
        require 'openssl'
        OpenSSL::Digest::MD5
      end

      def on_conflict=(action)
        validate_on_conflict_action!(action)

        config.on_conflict = action
      end

      def validate_on_conflict_action!(action)
        return if action.nil? || %i[log raise].include?(action) || action.respond_to?(:call)

        raise ActiveJob::Uniqueness::InvalidOnConflictAction, "Unexpected '#{action}' action on conflict"
      end
    end
  end
end
