require 'xcodeproj'

module Fastlane
  module DateVersioning
    class TargetMarketingVersionProjectEditor
      def self.read_versions(xcodeproj_path:, target_names:)
        project = Xcodeproj::Project.open(xcodeproj_path)

        target_names.to_h do |target_name|
          [target_name, version_for_target(project, target_name)]
        end
      rescue RuntimeError => e
        raise ArgumentError, e.message
      end

      def self.write_version(xcodeproj_path:, target_names:, version:)
        project = Xcodeproj::Project.open(xcodeproj_path)
        targets = target_names.map { |target_name| fetch_target(project, target_name) }

        targets.each do |target|
          target.build_configurations.each do |config|
            config.build_settings['MARKETING_VERSION'] = version
          end
        end

        project.save
      rescue RuntimeError => e
        raise ArgumentError, e.message
      end

      def self.version_for_target(project, target_name)
        versions = fetch_target(project, target_name).build_configurations.to_h do |config|
          [config.name, config.build_settings['MARKETING_VERSION']]
        end

        raise ArgumentError, 'MARKETING_VERSION is missing' if versions.values.any? do |value|
          value.nil? || value.empty?
        end
        raise ArgumentError, "Build configurations do not agree: #{versions}" if versions.values.uniq.length != 1

        versions.values.first
      end
      private_class_method :version_for_target

      def self.fetch_target(project, target_name)
        target = project.targets.find { |item| item.name == target_name }

        raise ArgumentError, "Target not found: #{target_name}" unless target

        target
      end
      private_class_method :fetch_target
    end
  end
end
