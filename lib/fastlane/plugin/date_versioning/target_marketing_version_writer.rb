require 'xcodeproj'

module Fastlane
  module DateVersioning
    class TargetMarketingVersionWriter
      def self.call(xcodeproj_path:, target_name:, version:)
        project = Xcodeproj::Project.open(xcodeproj_path)
        target = project.targets.find { |item| item.name == target_name }

        raise ArgumentError, "Target not found: #{target_name}" unless target

        target.build_configurations.each do |config|
          config.build_settings['MARKETING_VERSION'] = version
        end

        project.save
      rescue RuntimeError => e
        raise ArgumentError, e.message
      end
    end
  end
end
