# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    # Provides ability to make ActiveJob job unique.
    #
    # For example:
    #
    # class FooJob < ActiveJob::Base
    #   queue_as :foo
    #
    #   unique :until_executed, lock_ttl: 3.hours
    #
    #   def perform(params)
    #     #...
    #   end
    # end
    #
    module ActiveJobPatch
      extend ActiveSupport::Concern

      class_methods do
        # Enables the uniqueness strategy for the job
        # Params:
        # +strategy+:: the uniqueness strategy.
        # +options+:: uniqueness strategy options. For example: lock_ttl.
        def unique(strategy, options = {})
          validate_on_conflict_action!(options[:on_conflict])
          validate_on_conflict_action!(options[:on_runtime_conflict])

          self.lock_strategy_class = ActiveJob::Uniqueness::Strategies.lookup(strategy)
          self.lock_options = options
        end

        # Unlocks all jobs of the job class if no arguments given
        # Unlocks particular job if job arguments given
        def unlock!(*arguments)
          ActiveJob::Uniqueness.unlock!(job_class_name: name, arguments: arguments)
        end

        private

        delegate :validate_on_conflict_action!, to: :'ActiveJob::Uniqueness.config'
      end

      included do
        class_attribute :lock_strategy_class, instance_writer: false
        class_attribute :lock_options, instance_writer: false

        before_enqueue { |job| job.lock_strategy.before_enqueue if job.lock_strategy_class }
        before_perform { |job| job.lock_strategy.before_perform if job.lock_strategy_class }
        after_perform  { |job| job.lock_strategy.after_perform if job.lock_strategy_class }
        around_enqueue { |job, block| job.lock_strategy_class ? job.lock_strategy.around_enqueue(block) : block.call }
        around_perform { |job, block| job.lock_strategy_class ? job.lock_strategy.around_perform(block) : block.call }
      end

      def lock_strategy
        @lock_strategy ||= lock_strategy_class.new(job: self)
      end

      # Override in your job class if you want to customize arguments set for a digest.
      def lock_key_arguments
        arguments
      end

      # Override lock_key method in your job class if you want to build completely custom lock key.
      delegate :lock_key, :runtime_lock_key, to: :lock_key_generator

      def lock_key_generator
        @lock_key_generator ||= ActiveJob::Uniqueness::LockKey.new job_class_name: self.class.name,
                                                                   arguments: lock_key_arguments
      end
    end

    ActiveSupport.on_load(:active_job) do
      ActiveJob::Base.include ActiveJob::Uniqueness::ActiveJobPatch
    end
  end
end
