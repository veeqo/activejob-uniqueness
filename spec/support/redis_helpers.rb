# frozen_string_literal: true

module RedisHelpers
  def redis
    @redis ||= RedisClient.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
  end
end

RSpec.configure do |config|
  config.include RedisHelpers
end
