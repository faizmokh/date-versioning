require 'tmpdir'
require 'xcodeproj'

module SpecSupport
  module ProjectFactory
    def self.create!(target_name: nil, version: nil, build_settings: nil, targets: nil)
      directory = Dir.mktmpdir
      xcodeproj_path = File.join(directory, 'Demo.xcodeproj')
      project = Xcodeproj::Project.new(xcodeproj_path)

      target_definitions = targets || { target_name => build_settings || version }

      target_definitions.each do |name, target_settings|
        target = project.new_target(:application, name, :ios, '17.0')
        settings = if target_settings.is_a?(Hash)
                     target_settings
                   else
                     { 'Debug' => target_settings, 'Release' => target_settings }
                   end

        target.build_configurations.each do |config|
          config.build_settings['MARKETING_VERSION'] = settings.fetch(config.name)
        end
      end

      project.save
      xcodeproj_path
    end
  end
end
