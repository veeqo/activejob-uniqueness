# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    # See Configuration#lock_strategies if you want to define custom strategy
    module Strategies
      extend ActiveSupport::Autoload

      autoload :Base
      autoload :UntilExpired
      autoload :UntilExecuted
      autoload :UntilExecuting
      autoload :UntilAndWhileExecuting
      autoload :WhileExecuting

      class << self
        def lookup(strategy)
          matching_strategy(strategy.to_s.camelize) ||
            ActiveJob::Uniqueness.config.lock_strategies[strategy] ||
            raise(StrategyNotFound, "Strategy '#{strategy}' is not found. Is it declared in the configuration?")
        end

        private

        def matching_strategy(const)
          const_get(const, false) if const_defined?(const, false)
        end
      end
    end
  end
end
