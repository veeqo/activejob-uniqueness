# frozen_string_literal: true

describe ':until_executed strategy', type: :integration do
  it_behaves_like 'a strategy with unique jobs in the queue' do
    let(:strategy) { :until_executed }
  end

  describe 'performing' do
    class self::Job < ActiveJob::Base
      unique :until_executed

      def perform(number1, number2)
        number1 / number2
      end
    end

    subject { perform_enqueued_jobs }

    let(:job_class) { self.class::Job }

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

      it 'releases the lock' do
        expect { subject }.to unlock(job_class).by_args(*arguments)
      end

      it 'logs the unlock event' do
        expect { subject }.to log(/Unlocked/)
      end
    end
  end
end
