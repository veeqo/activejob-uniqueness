# frozen_string_literal: true

if defined?(Sidekiq)
  describe 'Sidekiq patch', type: :integration do
    shared_examples_for 'locks release' do
      class self::SidekiqWorker
        include Sidekiq::Worker
      end

      context 'when queue adapter is Sidekiq', active_job_adapter: :sidekiq do
        context 'when job class has unique strategy enabled' do
          class self::Job < ActiveJob::Base
            unique :until_executed
          end

          it 'releases the lock' do
            expect { subject }.to change { locks(job_class_name: self.class::Job.name).count }.by(-1)
          end
        end

        context 'when job class has no unique strategy enabled' do
          class self::Job < ActiveJob::Base
          end

          include_examples 'no unlock attempts'
        end
      end

      context 'when queue adapter is not Sidekiq', active_job_adapter: :test do
        context 'when job class has unique strategy enabled' do
          class self::Job < ActiveJob::Base
            unique :until_executed
          end

          include_examples 'no unlock attempts'
        end
      end
    end

    describe 'scheduled set item delete' do
      subject { Sidekiq::ScheduledSet.new.each(&:delete) }

      before do
        Sidekiq::ScheduledSet.new.clear
        self.class::SidekiqWorker.perform_in(3.minutes, 123)
        self.class::Job.set(wait: 3.minutes).perform_later(321)
      end

      include_examples 'locks release'
    end

    describe 'scheduled set item remove_job' do
      subject { Sidekiq::ScheduledSet.new.each { |entry| entry.send(:remove_job) { |_| } } }

      before do
        Sidekiq::ScheduledSet.new.clear
        self.class::SidekiqWorker.perform_in(3.minutes, 123)
        self.class::Job.set(wait: 3.minutes).perform_later(321)
      end

      include_examples 'locks release'
    end

    describe 'scheduled set clear' do
      subject { Sidekiq::ScheduledSet.new.clear }

      before do
        Sidekiq::ScheduledSet.new.clear
        self.class::SidekiqWorker.perform_in(3.minutes, 123)
        self.class::Job.set(wait: 3.minutes).perform_later(321)
      end

      include_examples 'locks release'
    end

    describe 'job delete' do
      subject { Sidekiq::Queue.new('default').each(&:delete) }

      before do
        Sidekiq::Queue.new('default').clear
        self.class::SidekiqWorker.perform_async(123)
        self.class::Job.perform_later(321)
      end

      include_examples 'locks release'
    end

    describe 'queue clear' do
      subject { Sidekiq::Queue.new('default').clear }

      before do
        Sidekiq::Queue.new('default').clear
        self.class::SidekiqWorker.perform_async(123)
        self.class::Job.perform_later(321)
      end

      include_examples 'locks release'
    end

    describe 'job set clear' do
      subject { Sidekiq::JobSet.new('schedule').clear }

      before do
        Sidekiq::JobSet.new('schedule').clear
        self.class::SidekiqWorker.perform_in(3.minutes, 123)
        self.class::Job.set(wait: 3.minutes).perform_later(321)
      end

      include_examples 'locks release'
    end

    describe 'job delete' do
      subject { Sidekiq::Queue.new('default').each(&:delete) }

      before do
        self.class::SidekiqWorker.perform_async(123)
        self.class::Job.perform_later(321)
      end

      include_examples 'locks release'
    end

    if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('5.1')
      describe 'job death' do
        subject do
          Sidekiq::Queue.new('default').each do |job|
            Sidekiq::DeadSet.new.kill(job.value)
          end
        end

        before do
          Sidekiq::Queue.new('default').clear
          self.class::SidekiqWorker.perform_async(123)
          self.class::Job.perform_later(321)
        end

        include_examples 'locks release'
      end
    end
  end
end
