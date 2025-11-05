# frozen_string_literal: true

require 'bigdecimal'

ActiveJob::Base.queue_adapter = :test

ActiveJob::Base.logger = ActiveSupport::TaggedLogging.new(Logger.new(nil))

# Silence noisy deprecation warnings
case ActiveJob::VERSION::STRING.to_f
when BigDecimal('6.0')
  ActiveJob::Base.return_false_on_aborted_enqueue = true
when BigDecimal('6.1')
  ActiveJob::Base.skip_after_callbacks_if_terminated = true
end
