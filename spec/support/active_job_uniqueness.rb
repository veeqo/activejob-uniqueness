# frozen_string_literal: true

ActiveJob::Uniqueness.configure do |c|
  c.redlock_options = { redis_timeout: 0.01, retry_count: 0 } # no reason to wait in tests
end
