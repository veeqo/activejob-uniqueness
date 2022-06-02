# frozen_string_literal: true

require 'active_support/log_subscriber'

module ActiveJob
  class LogSubscriber < ActiveSupport::LogSubscriber # :nodoc:
    def lock(event)
      job = event.payload[:job]
      resource = event.payload[:resource]

      debug do
        "Locked #{lock_info(job, resource)}" + args_info(job)
      end
    end

    def runtime_lock(event)
      job = event.payload[:job]
      resource = event.payload[:resource]

      debug do
        "Locked runtime #{lock_info(job, resource)}" + args_info(job)
      end
    end

    def unlock(event)
      job = event.payload[:job]
      resource = event.payload[:resource]

      debug do
        "Unlocked #{lock_info(job, resource)}"
      end
    end

    def runtime_unlock(event)
      job = event.payload[:job]
      resource = event.payload[:resource]

      debug do
        "Unlocked runtime #{lock_info(job, resource)}"
      end
    end

    def conflict(event)
      job = event.payload[:job]
      resource = event.payload[:resource]

      info do
        "Not unique #{lock_info(job, resource)}" + args_info(job)
      end
    end

    def runtime_conflict(event)
      job = event.payload[:job]
      resource = event.payload[:resource]

      info do
        "Not unique runtime #{lock_info(job, resource)}" + args_info(job)
      end
    end

    private

    def lock_info(job, resource)
      "#{job.class.name} (Job ID: #{job.job_id}) (Lock key: #{resource})"
    end

    def args_info(job)
      if job.arguments.any? && log_arguments?(job)
        " with arguments: #{job.arguments.map { |arg| format(arg).inspect }.join(', ')}"
      else
        ''
      end
    end

    def log_arguments?(job)
      return true unless job.class.respond_to?(:log_arguments?)

      job.class.log_arguments?
    end

    def format(arg)
      case arg
      when Hash
        arg.transform_values { |value| format(value) }
      when Array
        arg.map { |value| format(value) }
      when GlobalID::Identification
        arg.to_global_id rescue arg
      else
        arg
      end
    end

    def logger
      ActiveJob::Base.logger
    end
  end
end

ActiveJob::LogSubscriber.attach_to :active_job_uniqueness
