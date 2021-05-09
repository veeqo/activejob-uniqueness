# frozen_string_literal: true

describe ':until_and_while_executing strategy', type: :integration do
  it_behaves_like 'a strategy with unique jobs in the queue' do
    let(:strategy) { :until_and_while_executing }
  end

  describe 'processing' do
    subject { perform_enqueued_jobs }

    let(:job_class) do
      stub_active_job_class do
        unique :until_and_while_executing

        def perform(number1, number2)
          number1 / number2
        end
      end
    end

    before { job_class.perform_later(*arguments) }

    context 'when processing has failed' do
      let(:arguments) { [1, 0] }

      it 'releases the lock' do
        expect { suppress(ZeroDivisionError) { subject } }.to unlock(job_class).by_args(*arguments)
      end

      it 'logs the unlock event' do
        expect { suppress(ZeroDivisionError) { subject } }.to log(/Unlocked/)
      end

      it 'does not persist the runtime lock' do
        expect { suppress(ZeroDivisionError) { subject } }.not_to lock(job_class)
      end

      it 'logs the runtime lock event' do
        expect { suppress(ZeroDivisionError) { subject } }.to log(/Locked runtime/)
      end

      it 'logs the runtime unlock event' do
        expect { suppress(ZeroDivisionError) { subject } }.to log(/Unlocked runtime/)
      end
    end

    context 'when processing has succeed' do
      let(:arguments) { [1, 1] }

      it 'releases the lock' do
        expect { subject }.to unlock(job_class).by_args(*arguments)
      end

      it 'logs the unlock event' do
        expect { subject }.to log(/Unlocked/)
      end

      it 'does not persist the lock' do
        expect { subject }.not_to lock(job_class)
      end

      it 'logs the runtime lock event' do
        expect { subject }.to log(/Locked runtime/)
      end

      it 'logs the runtime unlock event' do
        expect { subject }.to log(/Unlocked runtime/)
      end
    end

    context 'when simultaneous job controls the runtime lock' do
      let(:arguments) { [1, 1] }

      before { set_runtime_lock(job_class, arguments: arguments) }

      shared_examples 'of a not unique job processing' do
        it 'releases the lock' do
          expect { suppress(ActiveJob::Uniqueness::JobNotUnique) { subject } }.to change { locks.grep_v(/:runtime/).count }.by(-1)
        end

        it 'logs the unlock event' do
          expect { suppress(ActiveJob::Uniqueness::JobNotUnique) { subject } }.to log(/Unlocked/)
        end

        it 'does not release the existing runtime lock' do
          expect { suppress(ActiveJob::Uniqueness::JobNotUnique) { subject } }.not_to change { locks.grep(/:runtime/).count }.from(1)
        end

        it 'does not log the runtime lock event' do
          expect { suppress(ActiveJob::Uniqueness::JobNotUnique) { subject } }.not_to log(/Locked runtime/)
        end

        it 'does not log the runtime unlock event' do
          expect { suppress(ActiveJob::Uniqueness::JobNotUnique) { subject } }.not_to log(/Unlocked runtime/)
        end
      end

      context 'when no options are given' do
        let(:job_class) do
          stub_active_job_class do
            unique :until_and_while_executing
          end
        end

        include_examples 'of a not unique job processing'

        it 'raises ActiveJob::Uniqueness::JobNotUnique' do
          expect { subject }.to raise_error(ActiveJob::Uniqueness::JobNotUnique, /Not unique/)
        end
      end

      context 'when on_conflict: :raise given' do
        let(:job_class) do
          stub_active_job_class do
            unique :until_and_while_executing, on_conflict: :raise
          end
        end

        include_examples 'of a not unique job processing'

        it 'raises ActiveJob::Uniqueness::JobNotUnique' do
          expect { subject }.to raise_error(ActiveJob::Uniqueness::JobNotUnique, /Not unique/)
        end
      end

      context 'when on_conflict: :log given' do
        let(:job_class) do
          stub_active_job_class do
            unique :until_and_while_executing, on_conflict: :log
          end
        end

        include_examples 'of a not unique job processing'

        it 'logs the skipped job' do
          expect { subject }.to log(/Not unique/)
        end
      end

      context 'when on_conflict: Proc given' do
        let(:job_class) do
          stub_active_job_class do
            unique :until_and_while_executing, on_conflict: ->(job) { job.logger.info('Oops') }
          end
        end

        include_examples 'of a not unique job processing'

        it 'calls the Proc' do
          expect { subject }.to log(/Oops/)
        end
      end

      context 'when on_runtime_conflict: :raise given' do
        let(:job_class) do
          stub_active_job_class do
            unique :until_and_while_executing, on_conflict: :log, on_runtime_conflict: :raise
          end
        end

        include_examples 'of a not unique job processing'

        it 'raises ActiveJob::Uniqueness::JobNotUnique' do
          expect { subject }.to raise_error(ActiveJob::Uniqueness::JobNotUnique, /Not unique/)
        end
      end

      context 'when on_runtime_conflict: :log given' do
        let(:job_class) do
          stub_active_job_class do
            unique :until_and_while_executing, on_conflict: :raise, on_runtime_conflict: :log
          end
        end

        include_examples 'of a not unique job processing'

        it 'logs the skipped job' do
          expect { subject }.to log(/Not unique/)
        end
      end

      context 'when on_runtime_conflict: Proc given' do
        let(:job_class) do
          stub_active_job_class do
            unique :until_and_while_executing, on_conflict: :raise, on_runtime_conflict: ->(job) { job.logger.info('Oops') }
          end
        end

        include_examples 'of a not unique job processing'

        it 'calls the Proc' do
          expect { subject }.to log(/Oops/)
        end
      end
    end
  end
end
