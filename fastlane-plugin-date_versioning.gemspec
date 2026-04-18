require_relative 'lib/fastlane/plugin/date_versioning/version'

Gem::Specification.new do |spec|
  spec.name = 'fastlane-plugin-date_versioning'
  spec.version = Fastlane::DateVersioning::VERSION
  spec.author = 'Date Versioning Contributors'
  spec.email = 'noreply@example.com'
  spec.summary = 'Set MARKETING_VERSION from the current date'
  spec.license = 'MIT'

  spec.files = Dir['lib/**/*', 'spec/**/*', 'README.md', 'LICENSE', '*.gemspec', 'Rakefile', 'Gemfile']
  spec.require_paths = ['lib']

  spec.add_dependency 'fastlane', '>= 2.0.0'
  spec.add_dependency 'tzinfo', '>= 2.0'
  spec.add_dependency 'xcodeproj', '>= 1.27'
  spec.add_development_dependency 'rspec', '>= 3.0'
end
