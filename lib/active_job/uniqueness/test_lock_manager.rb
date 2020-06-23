# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    # Mocks ActiveJob::Uniqueness::LockManager methods.
    # See ActiveJob::Uniqueness.test_mode!
    class TestLockManager
      def lock(*_args)
        true
      end

      alias delete_lock lock
      alias delete_locks lock
    end
  end
end
