module RedisHelpers
  def redis
    @redis ||= Redis.new
  end
end

RSpec.configure do |config|
  config.include RedisHelpers
end
