# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    # Redlock requires a value of the lock to release the resource by Redlock::Client#unlock method.
    # LockManager introduces LockManager#delete_lock to unlock by resource key only.
    # See https://github.com/leandromoreira/redlock-rb/issues/51 for more details.
    class LockManager < ::Redlock::Client
      # Unlocks a resource by resource only.
      def delete_lock(resource)
        @servers.each do |server|
          synced_redis_connection(server) do |conn|
            conn.call('DEL', resource)
          end
        end

        true
      end

      DELETE_LOCKS_SCAN_COUNT = 1000

      # Unlocks multiple resources by key wildcard.
      def delete_locks(wildcard)
        @servers.each do |server|
          synced_redis_connection(server) do |conn|
            cursor = 0
            while cursor != '0'
              cursor, keys = conn.call('SCAN', cursor, 'MATCH', wildcard, 'COUNT', DELETE_LOCKS_SCAN_COUNT)
              conn.call('UNLINK', *keys) unless keys.empty?
            end
          end
        end

        true
      end

      private

      def synced_redis_connection(server, &block)
        if server.respond_to?(:synchronize)
          server.synchronize(&block)
        else
          server.instance_variable_get(:@redis).with(&block)
        end
      end
    end
  end
end
