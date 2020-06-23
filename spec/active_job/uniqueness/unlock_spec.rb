# frozen_string_literal: true

describe ActiveJob::Uniqueness, '.unlock!', type: :integration do
  class self::Job < ActiveJob::Base
    unique :until_expired
  end

  class self::OtherJob < ActiveJob::Base
    unique :until_expired
  end

  before do
    self.class::Job.perform_later(1, 2)
    self.class::Job.perform_later(2, 1)
    self.class::OtherJob.perform_later(1, 2)
  end

  context 'when no params are given' do
    subject { described_class.unlock! }

    it 'unlocks all jobs of all job classes' do
      expect { subject }.to change { locks.count }.by(-3)
    end
  end

  context 'when job_class_name is given' do
    shared_examples 'of other job classes' do
      it 'does not unlock jobs of other job classes' do
        expect { subject }.not_to change { locks(job_class_name: self.class::OtherJob.name).count }
      end
    end

    context 'when no arguments are given' do
      subject { described_class.unlock!(job_class_name: self.class::Job.name) }

      it 'unlocks all jobs of the job class' do
        expect { subject }.to change { locks(job_class_name: self.class::Job.name).count }.by(-2)
      end

      include_examples 'of other job classes'
    end

    context 'when arguments are given' do
      subject { described_class.unlock!(job_class_name: self.class::Job.name, arguments: arguments) }

      context 'when there are matching locks for arguments' do
        let(:arguments) { [2, 1] }

        it 'unlocks matching jobs' do
          expect { subject }.to change { locks(job_class_name: self.class::Job.name).count }.by(-1)
        end

        include_examples 'of other job classes'
      end

      context 'when there are no matching locks for arguments' do
        let(:arguments) { [1, 3] }

        it 'does not unlock jobs of the job class' do
          expect { subject }.not_to change { locks(job_class_name: self.class::Job.name).count }
        end

        include_examples 'of other job classes'
      end
    end
  end
end
