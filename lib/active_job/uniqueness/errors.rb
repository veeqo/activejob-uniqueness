# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    class Error < ::RuntimeError; end

    # Raised when unknown strategy is referenced in the job class
    #
    # class MyJob < ActiveJob::Base
    #   unique :invalid_strategy # exception raised
    # end
    #
    class StrategyNotFound < Error; end

    # Raised on attempt to enqueue a not unique job with :raise on_conflict.
    # Also raised when the runtime lock is taken by some other job.
    #
    # class MyJob < ActiveJob::Base
    #   unique :until_expired, on_conflict: :raise
    # end
    #
    # MyJob.perform_later(1)
    # MyJob.perform_later(1) # exception raised
    #
    class JobNotUnique < Error; end

    # Raised when unsupported on_conflict action is used
    #
    # class MyJob < ActiveJob::Base
    #   unique :until_expired, on_conflict: :die # exception raised
    # end
    #
    class InvalidOnConflictAction < Error; end
  end
end
