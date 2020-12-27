# frozen_string_literal: true

ActiveJob::Base.queue_adapter = :test

ActiveJob::Base.logger = ActiveSupport::TaggedLogging.new(Logger.new(nil))

# Silence noisy deprecation warnings
case ActiveJob::VERSION::STRING.to_f
when 6.0
  ActiveJob::Base.return_false_on_aborted_enqueue = true
when 6.1
  ActiveJob::Base.skip_after_callbacks_if_terminated = true
end
