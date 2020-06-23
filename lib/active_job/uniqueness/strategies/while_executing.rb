# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    module Strategies
      # Locks the job when the job starts.
      # Unlocks the job when the job is finished.
      class WhileExecuting < Base
        def before_perform
          return if lock(resource: lock_key, ttl: lock_ttl, event: :runtime_lock)

          handle_conflict(resource: lock_key, event: :runtime_conflict, on_conflict: on_conflict)
          abort_job
        end

        def around_perform(block)
          return if @job_aborted # ActiveJob 4.2 workaround

          block.call
        ensure
          unlock(resource: lock_key, event: :runtime_unlock) unless @job_aborted
        end
      end
    end
  end
end
