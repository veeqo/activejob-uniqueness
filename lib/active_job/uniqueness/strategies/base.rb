# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    module Strategies
      # Base strategy is not supposed to actually be used as uniqueness strategy.
      class Base
        # https://github.com/rails/rails/pull/17227
        # https://groups.google.com/g/rubyonrails-core/c/mhD4T90g0G4
        ACTIVEJOB_SUPPORTS_THROW_ABORT = ActiveJob.gem_version >= Gem::Version.new('5.0')

        delegate :lock_manager, :config, to: :'ActiveJob::Uniqueness'

        attr_reader :lock_key, :lock_ttl, :on_conflict, :job

        def initialize(job:)
          @lock_key = job.lock_key
          @lock_ttl = (job.lock_options[:lock_ttl] || config.lock_ttl).to_i * 1000 # ms
          @on_conflict = job.lock_options[:on_conflict] || config.on_conflict
          @job = job
        end

        def lock(resource:, ttl:, event: :lock)
          lock_manager.lock(resource, ttl).tap do |result|
            instrument(event, resource: resource, ttl: ttl) if result
          end
        end

        def unlock(resource:, event: :unlock)
          lock_manager.delete_lock(resource).tap do
            instrument(event, resource: resource)
          end
        end

        def before_enqueue
          # Expected to be overriden in the descendant strategy
        end

        def before_perform
          # Expected to be overriden in the descendant strategy
        end

        def around_enqueue(block)
          # Expected to be overriden in the descendant strategy
          block.call
        end

        def around_perform(block)
          # Expected to be overriden in the descendant strategy
          block.call
        end

        def after_perform
          # Expected to be overriden in the descendant strategy
        end

        module LockingOnEnqueue
          def before_enqueue
            return if lock(resource: lock_key, ttl: lock_ttl)

            handle_conflict(resource: lock_key, on_conflict: on_conflict)
            abort_job
          end

          def around_enqueue(block)
            return if @job_aborted # ActiveJob 4.2 workaround

            enqueued = false

            block.call

            enqueued = true
          ensure
            unlock(resource: lock_key) unless @job_aborted || enqueued
          end
        end

        private

        def handle_conflict(on_conflict:, resource:, event: :conflict)
          case on_conflict
          when :log then instrument(event, resource: resource)
          when :raise then raise_not_unique_job_error(resource: resource, event: event)
          else
            on_conflict.call(job)
          end
        end

        def abort_job
          @job_aborted = true # ActiveJob 4.2 workaround

          ACTIVEJOB_SUPPORTS_THROW_ABORT ? throw(:abort) : false
        end

        def instrument(action, payload = {})
          ActiveSupport::Notifications.instrument "#{action}.active_job_uniqueness", payload.merge(job: job)
        end

        def raise_not_unique_job_error(resource:, event:)
          message = [
            job.class.name,
            "(Job ID: #{job.job_id})",
            "(Lock key: #{resource})",
            job.arguments.inspect
          ]

          message.unshift(event == :runtime_conflict ? 'Not unique runtime' : 'Not unique')

          raise JobNotUnique, message.join(' ')
        end
      end
    end
  end
end
