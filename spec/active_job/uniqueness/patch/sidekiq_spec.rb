# frozen_string_literal: true

if ENV['SIDEKIQ_VERSION']
  require 'sidekiq'

  describe ActiveJob::Uniqueness::Patch, 'Sidekiq' do
    class self::Job < ActiveJob::Base
      unique :until_executed
    end

    def schedule_job
      self.class::Job.set(wait: 3.minutes).perform_later(11)
    end

    def activejob_uniquness_keys
      Sidekiq.redis { |c| c.keys.select { |k| k.starts_with?("activejob_uniqueness:") } }
    end

    context 'when sidekiq job is deleted' do
      it 'releases the lock', sidekiq: true do
        expect { schedule_job }
          .to change { activejob_uniquness_keys.count }
          .by 1

        expect { Sidekiq::ScheduledSet.new.each(&:delete) }
          .to change { activejob_uniquness_keys.count }
          .by(-1)
      end
    end
  end
end
