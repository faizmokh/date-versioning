require 'tmpdir'
require 'xcodeproj'

module SpecSupport
  module ProjectFactory
    def self.create!(target_name:, version: nil, build_settings: nil)
      directory = Dir.mktmpdir
      xcodeproj_path = File.join(directory, 'Demo.xcodeproj')
      project = Xcodeproj::Project.new(xcodeproj_path)
      target = project.new_target(:application, target_name, :ios, '17.0')

      settings = build_settings || { 'Debug' => version, 'Release' => version }

      target.build_configurations.each do |config|
        config.build_settings['MARKETING_VERSION'] = settings.fetch(config.name)
      end

      project.save
      xcodeproj_path
    end
  end
end
