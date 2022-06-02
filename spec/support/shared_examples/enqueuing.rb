# frozen_string_literal: true

shared_examples_for 'a strategy with unique jobs in the queue' do
  describe 'enqueuing' do
    subject { job_class.perform_later(*arguments) }

    let(:arguments) { [1, 2] }

    let(:job_class) { stub_active_job_class }

    context 'when enqueuing has succeed' do
      shared_examples 'of an enqueued and locked job' do
        it 'enqueues the job' do
          expect { subject }.to change(enqueued_jobs, :count).by(1)
        end

        it 'locks the job' do
          expect { subject }.to lock(job_class).by_args(*arguments)
        end

        it 'logs the lock event' do
          expect { subject }.to log(/Locked/)
        end
      end

      context 'when no custom lock_ttl is set' do
        before { job_class.unique strategy }

        include_examples 'of an enqueued and locked job'

        it 'expires the lock properly' do
          subject
          expect(locks_expirations(job_class_name: job_class.name, arguments: arguments).first).to be_within(1.second).of(1.day)
        end
      end

      context 'when custom lock_ttl is set' do
        before { job_class.unique strategy, lock_ttl: 3.hours }

        include_examples 'of an enqueued and locked job'

        it 'expires the lock properly' do
          subject
          expect(locks_expirations(job_class_name: job_class.name, arguments: arguments).first).to be_within(1.second).of(3.hours)
        end
      end
    end

    context 'when enqueuing has failed' do
      before do
        job_class.unique strategy
        allow_any_instance_of(ActiveJob::QueueAdapters::TestAdapter).to receive(:enqueue).and_raise(IOError)
      end

      it 'does not persist the lock' do
        expect { suppress(IOError) { subject } }.not_to lock(job_class)
      end

      it 'logs the lock event' do
        expect { suppress(IOError) { subject } }.to log(/Locked/)
      end

      it 'logs the unlock event' do
        expect { suppress(IOError) { subject } }.to log(/Unlocked/)
      end
    end

    context 'when the lock exists' do
      before do
        job_class.unique strategy

        set_lock(job_class, arguments: arguments)
      end

      shared_examples 'of no jobs enqueued' do
        it 'does not enqueue the job' do
          expect { suppress(ActiveJob::Uniqueness::JobNotUnique) { subject } }.not_to change(enqueued_jobs, :count)
        end

        it 'does not remove the existing lock' do
          expect { suppress(ActiveJob::Uniqueness::JobNotUnique) { subject } }.not_to change(locks, :count)
        end
      end

      context 'when no options given' do
        include_examples 'of no jobs enqueued'

        it 'raises a ActiveJob::Uniqueness::JobNotUnique error' do
          expect { subject }.to raise_error ActiveJob::Uniqueness::JobNotUnique, /Not unique/
        end
      end

      context 'when on_conflict: :raise given' do
        before { job_class.unique strategy, on_conflict: :raise }

        include_examples 'of no jobs enqueued'

        it 'raises a ActiveJob::Uniqueness::JobNotUnique error' do
          expect { subject }.to raise_error ActiveJob::Uniqueness::JobNotUnique, /Not unique/
        end
      end

      context 'when on_conflict: :log given' do
        before { job_class.unique strategy, on_conflict: :log }

        it 'logs the skipped job' do
          expect { subject }.to log(/Not unique/)
        end
      end

      context 'when on_conflict: Proc given' do
        before { job_class.unique strategy, on_conflict: ->(job) { job.logger.info('Oops') } }

        include_examples 'of no jobs enqueued'

        it 'calls the Proc' do
          expect { subject }.to log(/Oops/)
        end
      end
    end
  end
end

shared_examples_for 'a strategy with non unique jobs in the queue' do
  describe 'enqueuing' do
    subject { job_class.perform_later(*arguments) }

    let(:arguments) { [1, 2] }

    let(:job_class) { stub_active_job_class }

    before { job_class.unique strategy }

    context 'when the lock does not exist' do
      it 'enqueues the job' do
        expect { subject }.to change(enqueued_jobs, :count).by(1)
      end

      it 'does not lock the job' do
        expect { suppress(RuntimeError) { subject } }.not_to lock(job_class)
      end
    end

    context 'when the lock exists' do
      before { set_lock(job_class, arguments: arguments) }

      it 'enqueues the job' do
        expect { subject }.to change(enqueued_jobs, :count).by(1)
      end

      it 'does not unlock the job' do
        expect { subject }.not_to change { locks(job_class_name: job_class.name, arguments: arguments).count }.from(1)
      end
    end
  end
end
