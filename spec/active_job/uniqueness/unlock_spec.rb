# frozen_string_literal: true

describe ActiveJob::Uniqueness, '.unlock!', type: :integration do
  let(:job_class) do
    stub_active_job_class('MyJob') do
      unique :until_expired
    end
  end

  let(:other_job_class) do
    stub_active_job_class('MyOtherJob') do
      unique :until_expired
    end
  end

  before do
    job_class.perform_later(1, 2)
    job_class.perform_later(2, 1)
    other_job_class.perform_later(1, 2)
  end

  context 'when no params are given' do
    subject(:unlock!) { described_class.unlock! }

    it 'unlocks all jobs of all job classes' do
      expect { unlock! }.to change { locks_count }.by(-3)
    end
  end

  context 'when job_class_name is given' do
    shared_examples 'of other job classes' do
      it 'does not unlock jobs of other job classes' do
        expect { unlock! }.not_to change { locks(job_class_name: 'MyOtherJob').count }
      end
    end

    context 'when no arguments are given' do
      subject(:unlock!) { described_class.unlock!(job_class_name: 'MyJob') }

      it 'unlocks all jobs of the job class' do
        expect { unlock! }.to change { locks(job_class_name: 'MyJob').count }.by(-2)
      end

      include_examples 'of other job classes'
    end

    context 'when arguments are given' do
      subject(:unlock!) { described_class.unlock!(job_class_name: 'MyJob', arguments: arguments) }

      context 'when there are matching locks for arguments' do
        let(:arguments) { [2, 1] }

        it 'unlocks matching jobs' do
          expect { unlock! }.to change { locks(job_class_name: 'MyJob').count }.by(-1)
        end

        include_examples 'of other job classes'
      end

      context 'when there are no matching locks for arguments' do
        let(:arguments) { [1, 3] }

        it 'does not unlock jobs of the job class' do
          expect { unlock! }.not_to change { locks(job_class_name: 'MyJob').count }
        end

        include_examples 'of other job classes'
      end
    end
  end

  describe 'bulk deletion' do
    subject(:unlock!) { described_class.unlock! }

    let(:expected_initial_number_of_locks) { 1_103 } # 1_100 + 2 + 1
    let(:expected_number_of_unlink_commands) { 2 } # 1103 / 1000 (ActiveJob::Uniqueness::LockManager::DELETE_LOCKS_SCAN_COUNT)

    before { 1_100.times.each { |i| job_class.perform_later(3, i) } }

    it 'removes locks efficiently' do
      expect { unlock! }.to change { locks_count }.from(expected_initial_number_of_locks).to(0)
                        .and change { unlink_commands_calls }.by(expected_number_of_unlink_commands)
    end

    def unlink_commands_calls
      info = redis.call('INFO', 'commandstats')
      unlink_stats = info.split("\n").find { |line| line.start_with?('cmdstat_unlink:') }
      return 0 unless unlink_stats

      unlink_stats.match(/cmdstat_unlink:calls=(\d+)/)[1].to_i
    end
  end
end
