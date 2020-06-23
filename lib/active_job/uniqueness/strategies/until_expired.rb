# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    module Strategies
      # Locks the job when it is pushed to the queue.
      # Does not allow new jobs enqueued until lock is expired.
      class UntilExpired < Base
        include LockingOnEnqueue
      end
    end
  end
end
