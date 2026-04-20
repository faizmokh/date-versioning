module Fastlane
  module Actions
    class SetMarketingVersionFromDateAction < Action
      def self.run(params)
        target_names = normalize_target_names(params[:target_name])
        candidate = params[:override_version] || Fastlane::DateVersioning::DateVersionFormatter.call(timezone: params[:timezone])
        Fastlane::DateVersioning::MarketingVersionValidator.validate!(candidate)

        current_versions = read_current_versions(xcodeproj_path: params[:xcodeproj], target_names: target_names)

        current_versions.each do |target_name, current|
          UI.message("Current MARKETING_VERSION (#{target_name}): #{current}")
        end
        UI.message("Candidate MARKETING_VERSION: #{candidate}")

        comparisons = current_versions.transform_values do |current|
          Fastlane::DateVersioning::MarketingVersionComparer.compare(candidate, current)
        end

        if params[:skip_if_same] && comparisons.values.all?(&:zero?)
          UI.message("MARKETING_VERSION already #{candidate} for all targets; skipping write")
          return candidate
        end

        decreasing_targets = comparisons.select { |_target_name, comparison| comparison.negative? }
        if params[:fail_if_version_decreases] && decreasing_targets.any?
          details = decreasing_targets.map do |target_name, _comparison|
            "#{target_name} (#{current_versions.fetch(target_name)} -> #{candidate})"
          end.join(', ')
          UI.user_error!("Refusing to decrease MARKETING_VERSION for #{details}")
        end

        if params[:dry_run]
          UI.message('Dry run enabled; skipping write')
          return candidate
        end

        write_version(xcodeproj_path: params[:xcodeproj], target_names: target_names, version: candidate)

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
          FastlaneCore::ConfigItem.new(key: :target_name, optional: false, is_string: false,
                                       description: 'Target or targets whose MARKETING_VERSION will be set',
                                       verify_block: proc do |value|
                                         next if value.is_a?(String)
                                         next if value.is_a?(Array) && value.all? { |item| item.is_a?(String) }

                                         UI.user_error!('target_name must be a String or Array<String>')
                                       end),
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

      def self.normalize_target_names(value)
        names = Array(value).map do |name|
          raise ArgumentError, 'target_name must be a String or Array<String>' unless name.is_a?(String)

          name.strip
        end.reject(&:empty?).uniq

        raise ArgumentError, 'target_name must include at least one target' if names.empty?

        names
      end
      private_class_method :normalize_target_names

      def self.read_current_versions(xcodeproj_path:, target_names:)
        if target_names.length == 1
          target_name = target_names.first
          current = Fastlane::DateVersioning::TargetMarketingVersionReader.call(
            xcodeproj_path: xcodeproj_path,
            target_name: target_name
          )

          { target_name => current }
        else
          Fastlane::DateVersioning::TargetMarketingVersionProjectEditor.read_versions(
            xcodeproj_path: xcodeproj_path,
            target_names: target_names
          )
        end
      end
      private_class_method :read_current_versions

      def self.write_version(xcodeproj_path:, target_names:, version:)
        if target_names.length == 1
          Fastlane::DateVersioning::TargetMarketingVersionWriter.call(
            xcodeproj_path: xcodeproj_path,
            target_name: target_names.first,
            version: version
          )
        else
          Fastlane::DateVersioning::TargetMarketingVersionProjectEditor.write_version(
            xcodeproj_path: xcodeproj_path,
            target_names: target_names,
            version: version
          )
        end
      end
      private_class_method :write_version
    end
  end
end
