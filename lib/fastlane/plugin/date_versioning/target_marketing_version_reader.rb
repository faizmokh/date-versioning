require 'xcodeproj'

module Fastlane
  module DateVersioning
    class TargetMarketingVersionReader
      def self.call(xcodeproj_path:, target_name:)
        project = Xcodeproj::Project.open(xcodeproj_path)
        target = project.targets.find { |item| item.name == target_name }

        raise ArgumentError, "Target not found: #{target_name}" unless target

        versions = target.build_configurations.to_h do |config|
          [config.name, config.build_settings['MARKETING_VERSION']]
        end

        raise ArgumentError, 'MARKETING_VERSION is missing' if versions.values.any? do |value|
          value.nil? || value.empty?
        end
        raise ArgumentError, "Build configurations do not agree: #{versions}" if versions.values.uniq.length != 1

        versions.values.first
      rescue RuntimeError => e
        raise ArgumentError, e.message
      end
    end
  end
end
