# frozen_string_literal: true

ActiveJob::Base.queue_adapter = :test

ActiveJob::Base.logger = ActiveSupport::TaggedLogging.new(Logger.new(nil))

# ActiveJob 6.0 prints noizy deprecation warning
ActiveJob::Base.return_false_on_aborted_enqueue = true if ActiveJob::VERSION::STRING.start_with?('6.0')
