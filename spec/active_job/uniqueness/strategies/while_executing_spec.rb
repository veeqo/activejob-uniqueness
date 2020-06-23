# frozen_string_literal: true

describe ':while_executing strategy', type: :integration do
  it_behaves_like 'a strategy with non unique jobs in the queue' do
    let(:strategy) { :while_executing }
  end

  describe 'processing' do
    class self::Job < ActiveJob::Base
      unique :while_executing

      def perform(number1, number2)
        number1 / number2
      end
    end

    subject { perform_enqueued_jobs }

    let(:job_class) { self.class::Job }

    before { job_class.perform_later(*arguments) }

    context 'when processing has failed' do
      let(:arguments) { [1, 0] }

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

      it 'does not persist the lock' do
        expect { subject }.not_to lock(job_class)
      end

      it 'logs the runtime lock event' do
        expect { subject }.to log(/Locked/)
      end

      it 'logs the runtime unlock event' do
        expect { subject }.to log(/Unlocked/)
      end
    end

    context 'when simultaneous job controls the runtime lock' do
      let(:arguments) { [1, 1] }

      before { set_lock(job_class, arguments: arguments) }

      shared_examples 'of a not unique job processing' do
        it 'does not release the existing runtime lock' do
          expect { suppress(ActiveJob::Uniqueness::JobNotUnique) { subject } }.not_to unlock(job_class).by_args(*arguments)
        end

        it 'does not log the runtime lock event' do
          expect { suppress(ActiveJob::Uniqueness::JobNotUnique) { subject } }.not_to log(/Locked runtime/)
        end

        it 'does not log the runtime unlock event' do
          expect { suppress(ActiveJob::Uniqueness::JobNotUnique) { subject } }.not_to log(/Unlocked runtime/)
        end

        it 'does not remove the existing lock' do
          expect { suppress(ActiveJob::Uniqueness::JobNotUnique) { subject } }.not_to change { locks.count }
        end
      end

      context 'when no options are given' do
        class self::Job < ActiveJob::Base
          unique :while_executing
        end

        include_examples 'of a not unique job processing'

        it 'raises ActiveJob::Uniqueness::JobNotUnique' do
          expect { subject }.to raise_error(ActiveJob::Uniqueness::JobNotUnique, /Not unique/)
        end
      end

      context 'when on_conflict: :raise given' do
        class self::Job < ActiveJob::Base
          unique :while_executing, on_conflict: :raise
        end

        include_examples 'of a not unique job processing'

        it 'raises ActiveJob::Uniqueness::JobNotUnique' do
          expect { subject }.to raise_error(ActiveJob::Uniqueness::JobNotUnique, /Not unique runtime/)
        end
      end

      context 'when on_conflict: :log given' do
        class self::Job < ActiveJob::Base
          unique :while_executing, on_conflict: :log
        end

        include_examples 'of a not unique job processing'

        it 'logs the skipped job' do
          expect { subject }.to log(/Not unique/)
        end
      end

      context 'when on_conflict: Proc given' do
        class self::Job < ActiveJob::Base
          unique :while_executing, on_conflict: ->(job) { job.logger.info('Oops') }
        end

        include_examples 'of a not unique job processing'

        it 'calls the Proc' do
          expect { subject }.to log(/Oops/)
        end
      end
    end
  end
end
