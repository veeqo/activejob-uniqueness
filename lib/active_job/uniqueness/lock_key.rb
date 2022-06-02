# frozen_string_literal: true

require 'active_job/arguments'

module ActiveJob
  module Uniqueness
    class LockKey
      FALLBACK_ARGUMENTS_STRING = 'no_arguments'

      delegate :lock_prefix, :digest_method, to: :'ActiveJob::Uniqueness.config'

      attr_reader :job_class_name, :arguments

      def initialize(job_class_name: nil, arguments: nil)
        if arguments.present? && job_class_name.blank?
          raise ArgumentError, 'job_class_name is required if arguments given'
        end

        @job_class_name = job_class_name
        @arguments = arguments || []
      end

      def lock_key
        [
          lock_prefix,
          normalized_job_class_name,
          arguments_key_part
        ].join(':')
      end

      # used only by :until_and_while_executing strategy
      def runtime_lock_key
        [
          lock_key,
          'runtime'
        ].join(':')
      end

      def wildcard_key
        [
          lock_prefix,
          normalized_job_class_name,
          arguments.any? ? "#{arguments_key_part}*" : '*'
        ].compact.join(':')
      end

      private

      def arguments_key_part
        arguments.any? ? arguments_digest : FALLBACK_ARGUMENTS_STRING
      end

      # ActiveJob::Arguments is used to reflect the way ActiveJob serializes arguments in order to
      # serialize ActiveRecord models with GlobalID uuids instead of as_json which could give undesired artifacts
      def serialized_arguments
        ActiveSupport::JSON.encode(ActiveJob::Arguments.serialize(arguments))
      end

      def arguments_digest
        digest_method.hexdigest(serialized_arguments)
      end

      def normalized_job_class_name
        job_class_name&.underscore
      end
    end
  end
end
