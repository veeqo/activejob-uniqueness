# frozen_string_literal: true

describe ':until_expired strategy', type: :integration do
  it_behaves_like 'a strategy with unique jobs in the queue' do
    let(:strategy) { :until_expired }
  end

  describe 'performing' do
    subject { perform_enqueued_jobs }

    let(:job_class) do
      stub_active_job_class do
        unique :until_expired

        def perform(number1, number2)
          number1 / number2
        end
      end
    end

    before { job_class.perform_later(*arguments) }

    context 'when performing has failed' do
      let(:arguments) { [1, 0] }

      it 'does not release the lock' do
        expect { suppress(ZeroDivisionError) { subject } }.not_to unlock(job_class).by_args(*arguments)
      end

      it 'does not log the unlock event' do
        expect { suppress(ZeroDivisionError) { subject } }.not_to log(/Unlocked/)
      end
    end

    context 'when performing has succeed' do
      let(:arguments) { [1, 1] }

      it 'does not release the lock' do
        expect { subject }.not_to unlock(job_class).by_args(*arguments)
      end

      it 'does not log the unlock event' do
        expect { subject }.not_to log(/Unlocked/)
      end
    end
  end
end
