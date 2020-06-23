# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    module Strategies
      # Locks the job when it is pushed to the queue.
      # Unlocks the job before the job is started.
      # Then creates runtime lock to prevent simultaneous jobs from being executed.
      class UntilAndWhileExecuting < Base
        include LockingOnEnqueue

        attr_reader :runtime_lock_ttl, :on_runtime_conflict

        def initialize(runtime_lock_ttl: nil, on_runtime_conflict: nil, **params)
          super(params)
          @runtime_lock_ttl = runtime_lock_ttl.present? ? runtime_lock_ttl.to_i * 1000 : lock_ttl
          @on_runtime_conflict = on_runtime_conflict || on_conflict
        end

        def before_perform
          unlock(resource: lock_key)

          return if lock(resource: runtime_lock_key, ttl: runtime_lock_ttl, event: :runtime_lock)

          handle_conflict(on_conflict: on_runtime_conflict, resource: runtime_lock_key, event: :runtime_conflict)
          abort_job
        end

        def around_perform(block)
          return if @job_aborted # ActiveJob 4.2 workaround

          block.call
        ensure
          unlock(resource: runtime_lock_key, event: :runtime_unlock) unless @job_aborted
        end

        def runtime_lock_key
          [lock_key, 'runtime'].join(':')
        end
      end
    end
  end
end
