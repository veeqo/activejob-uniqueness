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
          server.instance_variable_get(:@redis).with do |conn|
            conn.del resource
          end
        end

        true
      end

      # Unlocks multiple resources by key wildcard.
      def delete_locks(wildcard)
        @servers.each do |server|
          server.instance_variable_get(:@redis).with do |conn|
            conn.scan_each(match: wildcard).each { |key| conn.del key }
          end
        end

        true
      end
    end
  end
end
