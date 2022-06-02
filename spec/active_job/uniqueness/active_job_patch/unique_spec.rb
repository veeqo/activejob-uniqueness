# frozen_string_literal: true

describe ActiveJob::Uniqueness::ActiveJobPatch, '.unique' do
  let(:job_class) { stub_active_job_class }

  context 'when an custom strategy is given' do
    context 'when matching custom strategy is configured' do
      subject(:make_job_unique) { job_class.unique :custom, foo: 'bar' }

      let(:custom_strategy) { stub_strategy_class('MyCustomStrategy') }

      before { allow(ActiveJob::Uniqueness.config).to receive(:lock_strategies).and_return({ custom: custom_strategy }) }

      it 'sets proper values for lock variables', :aggregate_failures do
        make_job_unique

        expect(job_class.lock_strategy_class).to eq(custom_strategy)
        expect(job_class.lock_options).to eq({ foo: 'bar' })
      end
    end

    context 'when no matching custom strategy is configured' do
      subject(:make_job_unique) { job_class.unique :string }

      it 'raises error ActiveJob::Uniqueness::StrategyNotFound' do
        expect { make_job_unique }.to raise_error(ActiveJob::Uniqueness::StrategyNotFound, "Strategy 'string' is not found. Is it declared in the configuration?")
      end
    end
  end

  context 'when no options given' do
    subject(:make_job_unique) { job_class.unique :until_executed }

    it 'sets proper values for lock variables', :aggregate_failures do
      make_job_unique

      expect(job_class.lock_strategy_class).to eq(ActiveJob::Uniqueness::Strategies::UntilExecuted)
      expect(job_class.lock_options).to eq({})
    end
  end

  context 'when on_conflict: :log action is given' do
    subject(:make_job_unique) { job_class.unique :until_executed, on_conflict: :log }

    it 'sets proper values for lock variables', :aggregate_failures do
      make_job_unique

      expect(job_class.lock_strategy_class).to eq(ActiveJob::Uniqueness::Strategies::UntilExecuted)
      expect(job_class.lock_options).to eq({ on_conflict: :log })
    end
  end

  context 'when on_conflict: :raise action is given' do
    subject(:make_job_unique) { job_class.unique :until_executed, on_conflict: :raise }

    it 'sets proper values for lock variables', :aggregate_failures do
      make_job_unique

      expect(job_class.lock_strategy_class).to eq(ActiveJob::Uniqueness::Strategies::UntilExecuted)
      expect(job_class.lock_options).to eq({ on_conflict: :raise })
    end
  end

  context 'when on_conflict: Proc action is given' do
    subject(:make_job_unique) { job_class.unique :until_executed, on_conflict: custom_proc }

    let(:custom_proc) { ->(job) { job.logger.info('Oops') } }

    it 'sets proper values for lock variables', :aggregate_failures do
      make_job_unique

      expect(job_class.lock_strategy_class).to eq(ActiveJob::Uniqueness::Strategies::UntilExecuted)
      expect(job_class.lock_options).to eq({ on_conflict: custom_proc })
    end
  end

  context 'when invalid on_conflict is given' do
    subject(:make_job_unique) { job_class.unique :until_executed, on_conflict: :panic }

    it 'raises InvalidOnConflictAction error' do
      expect { make_job_unique }.to raise_error(ActiveJob::Uniqueness::InvalidOnConflictAction, "Unexpected 'panic' action on conflict")
    end
  end

  context 'when on_runtime_conflict: :log action is given' do
    subject(:make_job_unique) { job_class.unique :until_executed, on_runtime_conflict: :log }

    it 'sets proper values for lock variables', :aggregate_failures do
      make_job_unique

      expect(job_class.lock_strategy_class).to eq(ActiveJob::Uniqueness::Strategies::UntilExecuted)
      expect(job_class.lock_options).to eq({ on_runtime_conflict: :log })
    end
  end

  context 'when on_runtime_conflict: :raise action is given' do
    subject(:make_job_unique) { job_class.unique :until_executed, on_runtime_conflict: :raise }

    it 'sets proper values for lock variables', :aggregate_failures do
      make_job_unique

      expect(job_class.lock_strategy_class).to eq(ActiveJob::Uniqueness::Strategies::UntilExecuted)
      expect(job_class.lock_options).to eq({ on_runtime_conflict: :raise })
    end
  end

  context 'when on_runtime_conflict: Proc action is given' do
    subject(:make_job_unique) { job_class.unique :until_executed, on_runtime_conflict: custom_proc }

    let(:custom_proc) { ->(job) { job.logger.info('Oops') } }

    it 'sets proper values for lock variables', :aggregate_failures do
      make_job_unique

      expect(job_class.lock_strategy_class).to eq(ActiveJob::Uniqueness::Strategies::UntilExecuted)
      expect(job_class.lock_options).to eq({ on_runtime_conflict: custom_proc })
    end
  end

  context 'when invalid on_runtime_conflict is given' do
    subject(:make_job_unique) { job_class.unique :until_executed, on_runtime_conflict: :panic }

    it 'raises InvalidOnConflictAction error' do
      expect { make_job_unique }.to raise_error(ActiveJob::Uniqueness::InvalidOnConflictAction, "Unexpected 'panic' action on conflict")
    end
  end

  describe 'inheritance' do
    let(:base_job_class) { stub_active_job_class('MyBaseJob') { unique :until_executing, lock_ttl: 2.hours } }
    let(:inherited_job_class) { Class.new(base_job_class) }
    let(:not_inherited_job_class) { Class.new(ActiveJob::Base) }

    it 'preserves lock_strategy_class for inherited classes' do
      expect(inherited_job_class.lock_strategy_class).to eq(ActiveJob::Uniqueness::Strategies::UntilExecuting)
    end

    it 'preserves lock_options for inherited classes' do
      expect(inherited_job_class.lock_options).to eq(lock_ttl: 2.hours)
    end

    it 'does not impact lock_strategy_class of not inherited classes' do
      expect(not_inherited_job_class.lock_strategy_class).to be_nil
    end

    it 'does not impact lock_options of not inherited classes' do
      expect(not_inherited_job_class.lock_options).to be_nil
    end
  end
end
