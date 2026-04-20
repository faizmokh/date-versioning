require 'fastlane/action'
require_relative 'date_versioning/version'
require_relative 'date_versioning/date_version_formatter'
require_relative 'date_versioning/marketing_version_validator'
require_relative 'date_versioning/marketing_version_comparer'
require_relative 'date_versioning/target_marketing_version_reader'
require_relative 'date_versioning/target_marketing_version_writer'
require_relative 'date_versioning/target_marketing_version_project_editor'
require_relative 'date_versioning/actions/set_marketing_version_from_date_action'
require_relative 'date_versioning/helper/date_versioning_helper'

module Fastlane
  module DateVersioning
    def self.all_classes
      @all_classes ||= Dir[File.expand_path('date_versioning/**/*.rb', __dir__)]
    end
  end
end
