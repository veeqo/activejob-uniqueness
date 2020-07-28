# frozen_string_literal: true

RSpec.configure do |config|
  config.around sidekiq: true do |example|
    adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :sidekiq

    example.run

    ActiveJob::Base.queue_adapter = adapter
  end
end
