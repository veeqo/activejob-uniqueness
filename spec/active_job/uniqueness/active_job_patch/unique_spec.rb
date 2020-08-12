# frozen_string_literal: true

describe ActiveJob::Uniqueness::ActiveJobPatch, '.unique' do
  context 'when an custom strategy is given' do
    context 'when matching custom strategy is configured' do
      class self::Job < ActiveJob::Base; end
      class self::CustomStrategy < ActiveJob::Uniqueness::Strategies::Base; end

      subject { self.class::Job.unique :custom, foo: 'bar' }

      before { allow(ActiveJob::Uniqueness.config).to receive(:lock_strategies).and_return({ custom: self.class::CustomStrategy }) }

      it 'sets proper values for lock variables' do
        expect { subject }.to change { self.class::Job.lock_strategy_class }.from(nil).to(self.class::CustomStrategy)
                          .and change { self.class::Job.lock_options }.from(nil).to({ foo: 'bar' })
      end
    end

    context 'whem no matching custom strategy is configured' do
      class self::Job < ActiveJob::Base; end

      subject { self.class::Job.unique :string }

      it 'raises error ActiveJob::Uniqueness::StrategyNotFound' do
        expect { subject }.to raise_error(ActiveJob::Uniqueness::StrategyNotFound, "Strategy 'string' is not found. Is it declared in the configuration?")
      end
    end
  end

  context 'when no options given' do
    class self::Job < ActiveJob::Base; end

    subject { self.class::Job.unique :until_executed }

    it 'sets proper values for lock variables' do
      expect { subject }.to change { self.class::Job.lock_strategy_class }.from(nil).to(ActiveJob::Uniqueness::Strategies::UntilExecuted)
                        .and change { self.class::Job.lock_options }.from(nil).to({})
    end
  end

  context 'when on_conflict: :log action is given' do
    class self::Job < ActiveJob::Base; end

    subject { self.class::Job.unique :until_executed, on_conflict: :log }

    it 'sets proper values for lock variables' do
      expect { subject }.to change { self.class::Job.lock_strategy_class }.from(nil).to(ActiveJob::Uniqueness::Strategies::UntilExecuted)
                        .and change { self.class::Job.lock_options }.from(nil).to({ on_conflict: :log })
    end
  end

  context 'when on_conflict: :raise action is given' do
    class self::Job < ActiveJob::Base; end

    subject { self.class::Job.unique :until_executed, on_conflict: :raise }

    it 'sets proper values for lock variables' do
      expect { subject }.to change { self.class::Job.lock_strategy_class }.from(nil).to(ActiveJob::Uniqueness::Strategies::UntilExecuted)
                        .and change { self.class::Job.lock_options }.from(nil).to({ on_conflict: :raise })
    end
  end

  context 'when on_conflict: Proc action is given' do
    class self::Job < ActiveJob::Base; end

    subject { self.class::Job.unique :until_executed, on_conflict: ->(job) { job.logger.info('Oops') } }

    it 'sets proper values for lock variables' do
      expect { subject }.to change { self.class::Job.lock_strategy_class }.from(nil).to(ActiveJob::Uniqueness::Strategies::UntilExecuted)
                        .and change { self.class::Job.lock_options }.from(nil).to({ on_conflict: Proc })
    end
  end

  context 'when invalid on_conflict is given' do
    class self::Job < ActiveJob::Base; end

    subject { self.class::Job.unique :until_executed, on_conflict: :panic }

    it 'raises InvalidOnConflictAction error' do
      expect { subject }.to raise_error(ActiveJob::Uniqueness::InvalidOnConflictAction, "Unexpected 'panic' action on conflict")
    end
  end

  context 'when on_runtime_conflict: :log action is given' do
    class self::Job < ActiveJob::Base; end

    subject { self.class::Job.unique :until_executed, on_runtime_conflict: :log }

    it 'sets proper values for lock variables' do
      expect { subject }.to change { self.class::Job.lock_strategy_class }.from(nil).to(ActiveJob::Uniqueness::Strategies::UntilExecuted)
                        .and change { self.class::Job.lock_options }.from(nil).to({ on_runtime_conflict: :log })
    end
  end

  context 'when on_runtime_conflict: :raise action is given' do
    class self::Job < ActiveJob::Base; end

    subject { self.class::Job.unique :until_executed, on_runtime_conflict: :raise }

    it 'sets proper values for lock variables' do
      expect { subject }.to change { self.class::Job.lock_strategy_class }.from(nil).to(ActiveJob::Uniqueness::Strategies::UntilExecuted)
                        .and change { self.class::Job.lock_options }.from(nil).to({ on_runtime_conflict: :raise })
    end
  end

  context 'when on_runtime_conflict: Proc action is given' do
    class self::Job < ActiveJob::Base; end

    subject { self.class::Job.unique :until_executed, on_runtime_conflict: ->(job) { job.logger.info('Oops') } }

    it 'sets proper values for lock variables' do
      expect { subject }.to change { self.class::Job.lock_strategy_class }.from(nil).to(ActiveJob::Uniqueness::Strategies::UntilExecuted)
                        .and change { self.class::Job.lock_options }.from(nil).to({ on_runtime_conflict: Proc })
    end
  end

  context 'when invalid on_runtime_conflict is given' do
    class self::Job < ActiveJob::Base; end

    subject { self.class::Job.unique :until_executed, on_runtime_conflict: :panic }

    it 'raises InvalidOnConflictAction error' do
      expect { subject }.to raise_error(ActiveJob::Uniqueness::InvalidOnConflictAction, "Unexpected 'panic' action on conflict")
    end
  end

  describe 'inheritance' do
    class self::BaseJob < ActiveJob::Base
      unique :until_executing, lock_ttl: 2.hours
    end

    class self::InheritedJob < self::BaseJob
    end

    class self::NotInheritedJob < ActiveJob::Base
    end

    it 'preserves lock_strategy_class for inherited classes' do
      expect(self.class::InheritedJob.lock_strategy_class).to eq(ActiveJob::Uniqueness::Strategies::UntilExecuting)
    end

    it 'preserves lock_options for inherited classes' do
      expect(self.class::InheritedJob.lock_options).to eq(lock_ttl: 2.hours)
    end

    it 'does not impact lock_strategy_class of not inherited classes' do
      expect(self.class::NotInheritedJob.lock_strategy_class).to eq(nil)
    end

    it 'does not impact lock_options of not inherited classes' do
      expect(self.class::NotInheritedJob.lock_options).to eq(nil)
    end
  end
end
