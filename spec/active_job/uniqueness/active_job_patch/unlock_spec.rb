# frozen_string_literal: true

describe ActiveJob::Uniqueness::ActiveJobPatch, '.unlock!', type: :integration do
  let(:job_class) do
    stub_active_job_class('MyJob') do
      unique :until_expired
    end
  end

  let(:another_job_class) do
    stub_active_job_class('MyAnotherJob') do
      unique :until_expired
    end
  end

  before do
    job_class.perform_later(1, 2)
    job_class.perform_later(2, 1)
    another_job_class.perform_later(1, 2)
  end

  shared_examples 'of other job classes' do
    it 'does not unlock jobs of other job classes' do
      expect { subject }.not_to change { locks(job_class_name: 'MyAnotherJob').count }
    end
  end

  context 'when no params given' do
    subject { job_class.unlock! }

    it 'unlocks all jobs of the job class' do
      expect { subject }.to change { locks(job_class_name: 'MyJob').count }.by(-2)
    end

    include_examples 'of other job classes'
  end

  context 'when arguments given' do
    subject { job_class.unlock!(*arguments) }

    context 'when there are matching locks for arguments' do
      let(:arguments) { [2, 1] }

      it 'unlocks matching jobs' do
        expect { subject }.to change { locks(job_class_name: 'MyJob').count }.by(-1)
      end

      include_examples 'of other job classes'
    end

    context 'when there are no matching locks for arguments' do
      let(:arguments) { [1, 3] }

      it 'does not unlock jobs of the job class' do
        expect { subject }.not_to change { locks(job_class_name: 'MyJob').count }
      end

      include_examples 'of other job classes'
    end
  end
end
