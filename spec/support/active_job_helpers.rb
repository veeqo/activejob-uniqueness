# frozen_string_literal: true

module ActiveJobHelpers
  def clear_enqueued_jobs
    enqueued_jobs.clear
  end

  def perform_enqueued_jobs
    enqueued_jobs.each do |job|
      job[:job].new(*job[:args]).perform_now
    end
  end

  def enqueued_jobs
    ActiveJob::Base.queue_adapter.enqueued_jobs
  end
end

RSpec.configure do |config|
  config.include ActiveJobHelpers
  config.before(:each, type: :integration) { clear_enqueued_jobs }
end
