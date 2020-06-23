# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    module Strategies
      # Locks the job when it is pushed to the queue.
      # Unlocks the job before the job is started.
      class UntilExecuting < Base
        include LockingOnEnqueue

        def before_perform
          unlock(resource: lock_key)
        end
      end
    end
  end
end
