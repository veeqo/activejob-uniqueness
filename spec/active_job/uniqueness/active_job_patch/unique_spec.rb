# frozen_string_literal: true

describe ActiveJob::Uniqueness::ActiveJobPatch, '.unique' do
  let(:job_class) { stub_active_job_class }

  context 'when an custom strategy is given' do
    context 'when matching custom strategy is configured' do
      subject { job_class.unique :custom, foo: 'bar' }

      let(:custom_strategy) { stub_strategy_class('MyCustomStrategy') }

      before { allow(ActiveJob::Uniqueness.config).to receive(:lock_strategies).and_return({ custom: custom_strategy }) }

      it 'sets proper values for lock variables' do
        expect { subject }.to change { job_class.lock_strategy_class }.from(nil).to(custom_strategy)
                          .and change { job_class.lock_options }.from(nil).to({ foo: 'bar' })
      end
    end

    context 'whem no matching custom strategy is configured' do
      subject { job_class.unique :string }

      it 'raises error ActiveJob::Uniqueness::StrategyNotFound' do
        expect { subject }.to raise_error(ActiveJob::Uniqueness::StrategyNotFound, "Strategy 'string' is not found. Is it declared in the configuration?")
      end
    end
  end

  context 'when no options given' do
    subject { job_class.unique :until_executed }

    it 'sets proper values for lock variables' do
      expect { subject }.to change { job_class.lock_strategy_class }.from(nil).to(ActiveJob::Uniqueness::Strategies::UntilExecuted)
                        .and change { job_class.lock_options }.from(nil).to({})
    end
  end

  context 'when on_conflict: :log action is given' do
    subject { job_class.unique :until_executed, on_conflict: :log }

    it 'sets proper values for lock variables' do
      expect { subject }.to change { job_class.lock_strategy_class }.from(nil).to(ActiveJob::Uniqueness::Strategies::UntilExecuted)
                        .and change { job_class.lock_options }.from(nil).to({ on_conflict: :log })
    end
  end

  context 'when on_conflict: :raise action is given' do
    subject { job_class.unique :until_executed, on_conflict: :raise }

    it 'sets proper values for lock variables' do
      expect { subject }.to change { job_class.lock_strategy_class }.from(nil).to(ActiveJob::Uniqueness::Strategies::UntilExecuted)
                        .and change { job_class.lock_options }.from(nil).to({ on_conflict: :raise })
    end
  end

  context 'when on_conflict: Proc action is given' do
    subject { job_class.unique :until_executed, on_conflict: ->(job) { job.logger.info('Oops') } }

    it 'sets proper values for lock variables' do
      expect { subject }.to change { job_class.lock_strategy_class }.from(nil).to(ActiveJob::Uniqueness::Strategies::UntilExecuted)
                        .and change { job_class.lock_options }.from(nil).to({ on_conflict: Proc })
    end
  end

  context 'when invalid on_conflict is given' do
    subject { job_class.unique :until_executed, on_conflict: :panic }

    it 'raises InvalidOnConflictAction error' do
      expect { subject }.to raise_error(ActiveJob::Uniqueness::InvalidOnConflictAction, "Unexpected 'panic' action on conflict")
    end
  end

  context 'when on_runtime_conflict: :log action is given' do
    subject { job_class.unique :until_executed, on_runtime_conflict: :log }

    it 'sets proper values for lock variables' do
      expect { subject }.to change { job_class.lock_strategy_class }.from(nil).to(ActiveJob::Uniqueness::Strategies::UntilExecuted)
                        .and change { job_class.lock_options }.from(nil).to({ on_runtime_conflict: :log })
    end
  end

  context 'when on_runtime_conflict: :raise action is given' do
    subject { job_class.unique :until_executed, on_runtime_conflict: :raise }

    it 'sets proper values for lock variables' do
      expect { subject }.to change { job_class.lock_strategy_class }.from(nil).to(ActiveJob::Uniqueness::Strategies::UntilExecuted)
                        .and change { job_class.lock_options }.from(nil).to({ on_runtime_conflict: :raise })
    end
  end

  context 'when on_runtime_conflict: Proc action is given' do
    subject { job_class.unique :until_executed, on_runtime_conflict: ->(job) { job.logger.info('Oops') } }

    it 'sets proper values for lock variables' do
      expect { subject }.to change { job_class.lock_strategy_class }.from(nil).to(ActiveJob::Uniqueness::Strategies::UntilExecuted)
                        .and change { job_class.lock_options }.from(nil).to({ on_runtime_conflict: Proc })
    end
  end

  context 'when invalid on_runtime_conflict is given' do
    subject { job_class.unique :until_executed, on_runtime_conflict: :panic }

    it 'raises InvalidOnConflictAction error' do
      expect { subject }.to raise_error(ActiveJob::Uniqueness::InvalidOnConflictAction, "Unexpected 'panic' action on conflict")
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
      expect(not_inherited_job_class.lock_strategy_class).to eq(nil)
    end

    it 'does not impact lock_options of not inherited classes' do
      expect(not_inherited_job_class.lock_options).to eq(nil)
    end
  end
end
