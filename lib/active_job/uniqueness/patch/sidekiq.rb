# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    module Patch
      def self.delete_sidekiq_job!(job)
        ActiveJob::Uniqueness.unlock!(
          job_class_name: job.fetch('wrapped'),
          arguments: job.fetch('args').first.fetch('arguments')
        )
      end
    end
  end
end

require 'sidekiq/api'

Sidekiq.configure_server do |config|
  config.death_handlers << ->(job, _ex) do
    ActiveJob::Uniqueness::Patch.delete_sidekiq_job!(job)
  end
end

module Sidekiq
  class SortedEntry
    module UniqueExtension
      def delete
        ActiveJob::Uniqueness::Patch.delete_sidekiq_job!(item) if super
        item
      end

      private

      def remove_job
        super do |message|
          ActiveJob::Uniqueness::Patch.delete_sidekiq_job!(Sidekiq.load_json(message))
          yield message
        end
      end
    end

    prepend UniqueExtension
  end

  class ScheduledSet
    module UniqueExtension
      def delete(score, job_id)
        entry = find_job(job_id)
        ActiveJob::Uniqueness::Patch.delete_sidekiq_job!(entry.item) if super(score, job_id)
        entry
      end
    end

    prepend UniqueExtension
  end

  class Job
    module UniqueExtension
      def delete
        ActiveJob::Uniqueness::Patch.delete_sidekiq_job!(item)
        super
      end
    end

    prepend UniqueExtension
  end

  class Queue
    module UniqueExtension
      def clear
        each(&:delete)
        super
      end
    end

    prepend UniqueExtension
  end

  class JobSet
    module UniqueExtension
      def clear
        each(&:delete)
        super
      end

      def delete_by_value(name, value)
        ActiveJob::Uniqueness::Patch.delete_sidekiq_job!(Sidekiq.load_json(value)) if super(name, value)
      end
    end

    prepend UniqueExtension
  end
end
