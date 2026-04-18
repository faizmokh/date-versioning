module Fastlane
  module Actions
    class SetMarketingVersionFromDateAction < Action
      def self.run(params)
        candidate = params[:override_version] || Fastlane::DateVersioning::DateVersionFormatter.call(timezone: params[:timezone])
        Fastlane::DateVersioning::MarketingVersionValidator.validate!(candidate)

        current = Fastlane::DateVersioning::TargetMarketingVersionReader.call(
          xcodeproj_path: params[:xcodeproj],
          target_name: params[:target_name]
        )

        UI.message("Current MARKETING_VERSION: #{current}")
        UI.message("Candidate MARKETING_VERSION: #{candidate}")

        comparison = Fastlane::DateVersioning::MarketingVersionComparer.compare(candidate, current)

        if params[:skip_if_same] && comparison.zero?
          UI.message("MARKETING_VERSION already #{candidate}; skipping write")
          return candidate
        end

        if params[:fail_if_version_decreases] && comparison.negative?
          UI.user_error!("Refusing to decrease MARKETING_VERSION from #{current} to #{candidate}")
        end

        if params[:dry_run]
          UI.message('Dry run enabled; skipping write')
          return candidate
        end

        Fastlane::DateVersioning::TargetMarketingVersionWriter.call(
          xcodeproj_path: params[:xcodeproj],
          target_name: params[:target_name],
          version: candidate
        )

        candidate
      rescue ArgumentError => e
        UI.user_error!(e.message)
      end

      def self.description
        'Set an iOS target MARKETING_VERSION from the current date'
      end

      def self.authors
        ['OpenAI']
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcodeproj, optional: false, type: String,
                                       description: 'Path to the .xcodeproj to update'),
          FastlaneCore::ConfigItem.new(key: :target_name, optional: false, type: String,
                                       description: 'Target whose MARKETING_VERSION will be set'),
          FastlaneCore::ConfigItem.new(key: :timezone, optional: true, type: String, default_value: 'UTC',
                                       description: 'Timezone used when formatting the date version'),
          FastlaneCore::ConfigItem.new(key: :skip_if_same, optional: true, type: Boolean, default_value: true,
                                       description: 'Skip writing when the candidate matches the current version'),
          FastlaneCore::ConfigItem.new(key: :fail_if_version_decreases, optional: true, type: Boolean,
                                       default_value: true,
                                       description: 'Fail when the candidate version is lower than the current one'),
          FastlaneCore::ConfigItem.new(key: :dry_run, optional: true, type: Boolean, default_value: false,
                                       description: 'Compute and log the version without persisting it'),
          FastlaneCore::ConfigItem.new(key: :override_version, optional: true, type: String,
                                       description: 'Explicit version to use instead of formatting the current date')
        ]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
