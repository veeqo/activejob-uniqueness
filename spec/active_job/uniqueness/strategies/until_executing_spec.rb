# frozen_string_literal: true

describe ':until_executing strategy', type: :integration do
  it_behaves_like 'a strategy with unique jobs in the queue' do
    let(:strategy) { :until_executing }
  end

  describe 'performing' do
    subject(:process) { perform_enqueued_jobs }

    let(:job_class) do
      stub_active_job_class do
        unique :until_executing

        def perform(number1, number2)
          number1 / number2
        end
      end
    end

    before { job_class.perform_later(*arguments) }

    context 'when performing has failed' do
      let(:arguments) { [1, 0] }

      it 'releases the lock' do
        expect { suppress(ZeroDivisionError) { process } }.to unlock(job_class).by_args(*arguments)
      end

      it 'logs the unlock event' do
        expect { suppress(ZeroDivisionError) { process } }.to log(/Unlocked/)
      end
    end

    context 'when performing has succeed' do
      let(:arguments) { [1, 1] }

      it 'releases the lock' do
        expect { process }.to unlock(job_class).by_args(*arguments)
      end

      it 'logs the unlock event' do
        expect { process }.to log(/Unlocked/)
      end
    end
  end

  describe 'lock key' do
    let(:job) { job_class.new(2, 1) }

    before { job.lock_strategy.before_enqueue }

    context 'when the job has no custom #lock_key defined' do
      let(:job_class) do
        stub_active_job_class do
          unique :until_executing

          def perform(number1, number2)
            number1 / number2
          end
        end
      end

      it 'locks the job with the default lock key', :aggregate_failures do
        expect(locks.size).to eq 1
        expect(locks.first).to match(/\Aactivejob_uniqueness:my_job:[^:]+\z/)
      end
    end

    context 'when the job has a custom #lock_key defined' do
      let(:job_class) do
        stub_active_job_class do
          unique :until_executing

          def perform(number1, number2)
            number1 / number2
          end

          def lock_key
            'activejob_uniqueness:whatever'
          end
        end
      end

      it 'locks the job with the custom lock key', :aggregate_failures do
        expect(locks.size).to eq 1
        expect(locks.first).to eq 'activejob_uniqueness:whatever'
      end
    end
  end
end
