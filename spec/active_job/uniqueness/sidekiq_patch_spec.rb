# frozen_string_literal: true

describe 'Sidekiq patch', :sidekiq, type: :integration do
  shared_examples_for 'locks release' do
    let(:sidekiq_worker) do
      stub_const('MySidekiqWorker', Class.new { include Sidekiq::Worker })
    end

    after { Sidekiq::Queue.all.each(&:clear) }

    context 'when queue adapter is Sidekiq', active_job_adapter: :sidekiq do
      context 'when job class has unique strategy enabled' do
        let!(:activejob_worker) do
          stub_const('MyActiveJob', Class.new(ActiveJob::Base) { unique :until_executed })
        end

        it 'releases the lock' do
          expect { subject }.to change { locks(job_class_name: activejob_worker.name).count }.by(-1)
        end
      end

      context 'when job class has no unique strategy enabled' do
        let!(:activejob_worker) do
          stub_const('MyActiveJob', Class.new(ActiveJob::Base))
        end

        include_examples 'no unlock attempts'
      end
    end

    context 'when queue adapter is not Sidekiq', active_job_adapter: :test do
      context 'when job class has unique strategy enabled' do
        let!(:activejob_worker) do
          stub_const('MyActiveJob', Class.new(ActiveJob::Base) { unique :until_executed })
        end

        include_examples 'no unlock attempts'
      end
    end
  end

  describe 'scheduled set item delete' do
    subject { Sidekiq::ScheduledSet.new.each(&:delete) }

    before do
      Sidekiq::ScheduledSet.new.clear
      sidekiq_worker.perform_in(3.minutes, 123)
      activejob_worker.set(wait: 3.minutes).perform_later(321)
    end

    include_examples 'locks release'
  end

  describe 'scheduled set item remove_job' do
    subject { Sidekiq::ScheduledSet.new.each { |entry| entry.send(:remove_job) { |_| } } }

    before do
      Sidekiq::ScheduledSet.new.clear
      sidekiq_worker.perform_in(3.minutes, 123)
      activejob_worker.set(wait: 3.minutes).perform_later(321)
    end

    include_examples 'locks release'
  end

  describe 'scheduled set clear' do
    subject { Sidekiq::ScheduledSet.new.clear }

    before do
      Sidekiq::ScheduledSet.new.clear
      sidekiq_worker.perform_in(3.minutes, 123)
      activejob_worker.set(wait: 3.minutes).perform_later(321)
    end

    include_examples 'locks release'
  end

  describe 'job delete' do
    subject { Sidekiq::Queue.new('default').each(&:delete) }

    before do
      Sidekiq::Queue.new('default').clear
      sidekiq_worker.perform_async(123)
      activejob_worker.perform_later(321)
    end

    include_examples 'locks release'
  end

  describe 'queue clear' do
    subject { Sidekiq::Queue.new('default').clear }

    before do
      Sidekiq::Queue.new('default').clear
      sidekiq_worker.perform_async(123)
      activejob_worker.perform_later(321)
    end

    include_examples 'locks release'
  end

  describe 'job set clear' do
    subject { Sidekiq::JobSet.new('schedule').clear }

    before do
      Sidekiq::JobSet.new('schedule').clear
      sidekiq_worker.perform_in(3.minutes, 123)
      activejob_worker.set(wait: 3.minutes).perform_later(321)
    end

    include_examples 'locks release'
  end

  describe 'job delete' do
    subject { Sidekiq::Queue.new('default').each(&:delete) }

    before do
      sidekiq_worker.perform_async(123)
      activejob_worker.perform_later(321)
    end

    include_examples 'locks release'
  end

  describe 'job death', sidekiq: :job_death do
    subject do
      Sidekiq::Queue.new('default').each do |job|
        Sidekiq::DeadSet.new.kill(job.value)
      end
    end

    before do
      Sidekiq::Queue.new('default').clear
      sidekiq_worker.perform_async(123)
      activejob_worker.perform_later(321)
    end

    include_examples 'locks release'
  end
end
