# frozen_string_literal: true

module ActiveJob
  module Uniqueness
    module Generators
      class InstallGenerator < Rails::Generators::Base
        desc 'Copy ActiveJob::Uniqueness default files'
        source_root File.expand_path('templates', __dir__)

        def copy_config
          template 'config/initializers/active_job_uniqueness.rb'
        end
      end
    end
  end
end
