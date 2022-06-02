# frozen_string_literal: true

require 'redis'

module LocksHelpers
  def cleanup_locks(**args)
    ActiveJob::Uniqueness.unlock!(**args)
  end

  def locks(**args)
    redis.keys(ActiveJob::Uniqueness::LockKey.new(**args).wildcard_key)
  end

  def locks_count
    locks.count
  end

  def locks_expirations(**args)
    locks(**args).map { |key| redis.ttl(key) }
  end

  def set_lock(job_class, arguments:)
    lock_strategy = job_class.new(*arguments).lock_strategy

    lock_strategy.lock_manager.lock(lock_strategy.lock_key, lock_strategy.lock_ttl)
  end

  def set_runtime_lock(job_class, arguments:)
    lock_strategy = job_class.new(*arguments).lock_strategy

    lock_strategy.lock_manager.lock(lock_strategy.runtime_lock_key, lock_strategy.runtime_lock_ttl)
  end
end

RSpec::Matchers.define :lock do |job_class|
  match do |actual|
    lock_params = { job_class_name: job_class.name }
    lock_params[:arguments] = @lock_arguments if @lock_arguments

    expect { actual.call }.to change { locks(**lock_params).count }.by(1)
  end

  chain :by_args do |*lock_arguments|
    @lock_arguments = Array(lock_arguments)
  end

  supports_block_expectations

  failure_message do
    "expected that '#{job_class}' to be locked by #{@lock_arguments ? @lock_arguments.join(', ') : 'no arguments'}"
  end
end

RSpec::Matchers.define :unlock do |job_class|
  match do |actual|
    lock_params = { job_class_name: job_class.name }
    lock_params[:arguments] = @lock_arguments if @lock_arguments

    expect { actual.call }.to change { locks(**lock_params).count }.by(-1)
  end

  chain :by_args do |*lock_arguments|
    @lock_arguments = Array(lock_arguments)
  end

  supports_block_expectations

  failure_message do
    "expected that '#{job_class}' to be unlocked by #{@lock_arguments ? @lock_arguments.join(', ') : 'no arguments'}"
  end
end

RSpec.configure do |config|
  config.include LocksHelpers
  config.before(:each, type: :integration) { cleanup_locks }
end
