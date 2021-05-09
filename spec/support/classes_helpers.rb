# frozen_string_literal: true

module ClassesHelpers
  def stub_active_job_class(name = 'MyJob', &block)
    klass = Class.new(ActiveJob::Base)
    klass.class_eval(&block) if block_given?
    stub_const(name, klass)
  end

  def stub_sidekiq_class(name = 'MySidekiqWorker', &block)
    klass = Class.new
    klass.include Sidekiq::Worker
    klass.class_eval(&block) if block_given?
    stub_const(name, klass)
  end

  def stub_strategy_class(name = 'MyStrategy', &block)
    klass = Class.new(ActiveJob::Uniqueness::Strategies::Base)
    klass.class_eval(&block) if block_given?
    stub_const(name, klass)
  end
end

RSpec.configure do |config|
  config.include ClassesHelpers
end
