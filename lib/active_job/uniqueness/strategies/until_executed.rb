# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    module Strategies
      # Locks the job when it is pushed to the queue.
      # Unlocks the job when the job is finished.
      class UntilExecuted < Base
        include LockingOnEnqueue

        def after_perform
          unlock(resource: lock_key)
        end
      end
    end
  end
end
