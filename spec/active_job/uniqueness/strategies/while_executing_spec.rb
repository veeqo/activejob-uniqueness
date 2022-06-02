# frozen_string_literal: true

describe ':while_executing strategy', type: :integration do
  it_behaves_like 'a strategy with non unique jobs in the queue' do
    let(:strategy) { :while_executing }
  end

  describe 'processing' do
    subject(:process) { perform_enqueued_jobs }

    let(:job_class) do
      stub_active_job_class do
        unique :while_executing

        def perform(number1, number2)
          number1 / number2
        end
      end
    end

    before { job_class.perform_later(*arguments) }

    context 'when processing has failed' do
      let(:arguments) { [1, 0] }

      it 'does not persist the runtime lock' do
        expect { suppress(ZeroDivisionError) { process } }.not_to lock(job_class)
      end

      it 'logs the runtime lock event' do
        expect { suppress(ZeroDivisionError) { process } }.to log(/Locked runtime/)
      end

      it 'logs the runtime unlock event' do
        expect { suppress(ZeroDivisionError) { process } }.to log(/Unlocked runtime/)
      end
    end

    context 'when processing has succeed' do
      let(:arguments) { [1, 1] }

      it 'does not persist the lock' do
        expect { process }.not_to lock(job_class)
      end

      it 'logs the runtime lock event' do
        expect { process }.to log(/Locked/)
      end

      it 'logs the runtime unlock event' do
        expect { process }.to log(/Unlocked/)
      end
    end

    context 'when simultaneous job controls the runtime lock' do
      let(:arguments) { [1, 1] }

      before { set_lock(job_class, arguments: arguments) }

      shared_examples 'of a not unique job processing' do
        it 'does not release the existing runtime lock' do
          expect { suppress(ActiveJob::Uniqueness::JobNotUnique) { process } }.not_to unlock(job_class).by_args(*arguments)
        end

        it 'does not log the runtime lock event' do
          expect { suppress(ActiveJob::Uniqueness::JobNotUnique) { process } }.not_to log(/Locked runtime/)
        end

        it 'does not log the runtime unlock event' do
          expect { suppress(ActiveJob::Uniqueness::JobNotUnique) { process } }.not_to log(/Unlocked runtime/)
        end

        it 'does not remove the existing lock' do
          expect { suppress(ActiveJob::Uniqueness::JobNotUnique) { process } }.not_to change(locks, :count)
        end
      end

      context 'when no options are given' do
        let(:job_class) do
          stub_active_job_class do
            unique :while_executing
          end
        end

        include_examples 'of a not unique job processing'

        it 'raises ActiveJob::Uniqueness::JobNotUnique' do
          expect { process }.to raise_error(ActiveJob::Uniqueness::JobNotUnique, /Not unique/)
        end
      end

      context 'when on_conflict: :raise given' do
        let(:job_class) do
          stub_active_job_class do
            unique :while_executing, on_conflict: :raise
          end
        end

        include_examples 'of a not unique job processing'

        it 'raises ActiveJob::Uniqueness::JobNotUnique' do
          expect { process }.to raise_error(ActiveJob::Uniqueness::JobNotUnique, /Not unique runtime/)
        end
      end

      context 'when on_conflict: :log given' do
        let(:job_class) do
          stub_active_job_class do
            unique :while_executing, on_conflict: :log
          end
        end

        include_examples 'of a not unique job processing'

        it 'logs the skipped job' do
          expect { process }.to log(/Not unique/)
        end
      end

      context 'when on_conflict: Proc given' do
        let(:job_class) do
          stub_active_job_class do
            unique :while_executing, on_conflict: ->(job) { job.logger.info('Oops') }
          end
        end

        include_examples 'of a not unique job processing'

        it 'calls the Proc' do
          expect { process }.to log(/Oops/)
        end
      end
    end
  end

  describe 'lock key' do
    let(:job) { job_class.new(2, 1) }

    before { job.lock_strategy.before_perform }

    context 'when the job has no custom #lock_key defined' do
      let(:job_class) do
        stub_active_job_class do
          unique :while_executing

          def perform(number1, number2)
            number1 / number2
          end
        end
      end

      it 'locks the job with the default lock key', :aggregate_failures do
        job.lock_strategy.around_perform lambda {
          expect(locks.size).to eq 1
          expect(locks.first).to match(/\Aactivejob_uniqueness:my_job:[^:]+\z/)
        }
      end
    end

    context 'when the job has a custom #lock_key defined' do
      let(:job_class) do
        stub_active_job_class do
          unique :while_executing

          def perform(number1, number2)
            number1 / number2
          end

          def lock_key
            'activejob_uniqueness:whatever'
          end
        end
      end

      it 'locks the job with the custom lock key', :aggregate_failures do
        job.lock_strategy.around_perform lambda {
          expect(locks.size).to eq 1
          expect(locks.first).to eq 'activejob_uniqueness:whatever'
        }
      end
    end
  end
end
