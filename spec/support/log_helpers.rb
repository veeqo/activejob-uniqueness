# frozen_string_literal: true

RSpec::Matchers.define :log do |expected|
  match do |actual|
    log     = StringIO.new
    logger  = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(log))

    allow(ActiveJob::Base).to receive(:logger).and_return(logger)
    allow_any_instance_of(ActiveJob::Base).to receive(:logger).and_return(logger)

    actual.call

    @log_content = log.tap(&:rewind).read

    expect(@log_content).to match(expected)
  end

  failure_message do
    "expected that '#{expected}' would be in log: \n#{@log_content}"
  end

  supports_block_expectations
end
