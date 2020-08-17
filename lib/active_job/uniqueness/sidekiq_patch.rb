# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    def self.unlock_sidekiq_job!(job_data)
      return unless job_data['class'] == 'ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper' # non ActiveJob jobs

      job = ActiveJob::Base.deserialize(job_data.fetch('args').first)

      return unless job.class.lock_strategy_class

      begin
        job.send(:deserialize_arguments_if_needed)
      rescue ActiveJob::DeserializationError
        # Most probably, GlobalID fails to locate AR record (record is deleted)
      else
        ActiveJob::Uniqueness.unlock!(job_class_name: job.class.name, arguments: job.arguments)
      end
    end

    module SidekiqPatch
      module SortedEntry
        def delete
          ActiveJob::Uniqueness.unlock_sidekiq_job!(item) if super
          item
        end

        private

        def remove_job
          super do |message|
            ActiveJob::Uniqueness.unlock_sidekiq_job!(Sidekiq.load_json(message))
            yield message
          end
        end
      end

      module ScheduledSet
        def delete(score, job_id)
          entry = find_job(job_id)
          ActiveJob::Uniqueness.unlock_sidekiq_job!(entry.item) if super(score, job_id)
          entry
        end
      end

      module Job
        def delete
          ActiveJob::Uniqueness.unlock_sidekiq_job!(item)
          super
        end
      end

      module Queue
        def clear
          each(&:delete)
          super
        end
      end

      module JobSet
        def clear
          each(&:delete)
          super
        end

        def delete_by_value(name, value)
          ActiveJob::Uniqueness.unlock_sidekiq_job!(Sidekiq.load_json(value)) if super(name, value)
        end
      end
    end
  end
end

Sidekiq::SortedEntry.prepend ActiveJob::Uniqueness::SidekiqPatch::SortedEntry
Sidekiq::ScheduledSet.prepend ActiveJob::Uniqueness::SidekiqPatch::ScheduledSet
Sidekiq::Job.prepend ActiveJob::Uniqueness::SidekiqPatch::Job
Sidekiq::Queue.prepend ActiveJob::Uniqueness::SidekiqPatch::Queue
Sidekiq::JobSet.prepend ActiveJob::Uniqueness::SidekiqPatch::JobSet

# Global death handlers are introduced in Sidekiq 5.1
# https://github.com/mperham/sidekiq/blob/e7acb124fbeb0bece0a7c3d657c39a9cc18d72c6/Changes.md#510
if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('5.1')
  Sidekiq.death_handlers << ->(job, _ex) { ActiveJob::Uniqueness.unlock_sidekiq_job!(job) }
end
