require 'spec_helper'

RSpec.describe Fastlane::Actions::SetMarketingVersionFromDateAction do
  describe '.run' do
    let(:project_path) { SpecSupport::ProjectFactory.create!(target_name: 'Demo', version: '2026.4.18') }

    def run_action(**overrides)
      described_class.run(
        {
          xcodeproj: project_path,
          target_name: 'Demo',
          timezone: 'UTC',
          skip_if_same: true,
          fail_if_version_decreases: true,
          dry_run: false,
          override_version: nil
        }.merge(overrides)
      )
    end

    it 'writes the computed date version on the happy path' do
      allow(Fastlane::DateVersioning::DateVersionFormatter).to receive(:call).and_return('2026.4.19')

      expect(run_action).to eq('2026.4.19')
      expect(
        Fastlane::DateVersioning::TargetMarketingVersionReader.call(xcodeproj_path: project_path, target_name: 'Demo')
      ).to eq('2026.4.19')
    end

    it 'does not persist when dry_run is true' do
      allow(Fastlane::DateVersioning::DateVersionFormatter).to receive(:call).and_return('2026.4.19')

      expect(run_action(dry_run: true)).to eq('2026.4.19')
      expect(
        Fastlane::DateVersioning::TargetMarketingVersionReader.call(xcodeproj_path: project_path, target_name: 'Demo')
      ).to eq('2026.4.18')
    end

    it 'short-circuits when the candidate matches the current version' do
      allow(Fastlane::DateVersioning::DateVersionFormatter).to receive(:call).and_return('2026.4.18')

      expect(Fastlane::DateVersioning::TargetMarketingVersionWriter).not_to receive(:call)

      expect(run_action).to eq('2026.4.18')
    end

    it 'fails when the candidate version decreases and the guard is enabled' do
      allow(Fastlane::DateVersioning::DateVersionFormatter).to receive(:call).and_return('2026.4.17')

      expect do
        run_action
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /Refusing to decrease MARKETING_VERSION/)
    end

    it 'uses override_version when present' do
      expect(Fastlane::DateVersioning::DateVersionFormatter).not_to receive(:call)

      expect(run_action(override_version: '2026.4.20')).to eq('2026.4.20')
      expect(
        Fastlane::DateVersioning::TargetMarketingVersionReader.call(xcodeproj_path: project_path, target_name: 'Demo')
      ).to eq('2026.4.20')
    end

    it 'fails when override_version is invalid' do
      expect do
        run_action(override_version: '2026.4.20-beta')
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /Invalid marketing version/)
    end

    it 'fails when the formatted candidate version is invalid' do
      allow(Fastlane::DateVersioning::DateVersionFormatter).to receive(:call).and_return('2026.4.20-beta')

      expect do
        run_action
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /Invalid marketing version/)
    end

    it 'fails with a user-facing error when the target is missing' do
      expect do
        run_action(target_name: 'Other')
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /Target not found/)
    end

    it 'fails with a user-facing error when the project path is invalid' do
      expect do
        run_action(xcodeproj: 'missing/Project.xcodeproj')
      end.to raise_error(FastlaneCore::Interface::FastlaneError)
    end

    it 'writes a lower candidate when fail_if_version_decreases is false' do
      allow(Fastlane::DateVersioning::DateVersionFormatter).to receive(:call).and_return('2026.4.17')

      expect(run_action(fail_if_version_decreases: false)).to eq('2026.4.17')
      expect(
        Fastlane::DateVersioning::TargetMarketingVersionReader.call(xcodeproj_path: project_path, target_name: 'Demo')
      ).to eq('2026.4.17')
    end

    it 'writes the same candidate when skip_if_same is false' do
      allow(Fastlane::DateVersioning::DateVersionFormatter).to receive(:call).and_return('2026.4.18')
      expect(Fastlane::DateVersioning::TargetMarketingVersionWriter).to receive(:call).with(
        xcodeproj_path: project_path,
        target_name: 'Demo',
        version: '2026.4.18'
      ).and_call_original

      expect(run_action(skip_if_same: false)).to eq('2026.4.18')
      expect(
        Fastlane::DateVersioning::TargetMarketingVersionReader.call(xcodeproj_path: project_path, target_name: 'Demo')
      ).to eq('2026.4.18')
    end

    it 'updates multiple targets when target_name is an array' do
      project_path = SpecSupport::ProjectFactory.create!(
        targets: {
          'App' => '2026.4.18',
          'Widget' => '2026.4.18'
        }
      )

      allow(Fastlane::DateVersioning::DateVersionFormatter).to receive(:call).and_return('2026.4.19')

      result = described_class.run(
        xcodeproj: project_path,
        target_name: %w[App Widget],
        timezone: 'UTC',
        skip_if_same: true,
        fail_if_version_decreases: true,
        dry_run: false,
        override_version: nil
      )

      expect(result).to eq('2026.4.19')
      expect(
        Fastlane::DateVersioning::TargetMarketingVersionReader.call(xcodeproj_path: project_path, target_name: 'App')
      ).to eq('2026.4.19')
      expect(
        Fastlane::DateVersioning::TargetMarketingVersionReader.call(xcodeproj_path: project_path, target_name: 'Widget')
      ).to eq('2026.4.19')
    end

    it 'skips only when every target already matches the candidate version' do
      project_path = SpecSupport::ProjectFactory.create!(
        targets: {
          'App' => '2026.4.18',
          'Widget' => '2026.4.18'
        }
      )

      allow(Fastlane::DateVersioning::DateVersionFormatter).to receive(:call).and_return('2026.4.18')
      expect(Fastlane::DateVersioning::TargetMarketingVersionProjectEditor).not_to receive(:write_version)

      result = described_class.run(
        xcodeproj: project_path,
        target_name: %w[App Widget],
        timezone: 'UTC',
        skip_if_same: true,
        fail_if_version_decreases: true,
        dry_run: false,
        override_version: nil
      )

      expect(result).to eq('2026.4.18')
    end

    it 'fails when the candidate would decrease any target' do
      project_path = SpecSupport::ProjectFactory.create!(
        targets: {
          'App' => '2026.4.18',
          'Widget' => '2026.4.20'
        }
      )

      allow(Fastlane::DateVersioning::DateVersionFormatter).to receive(:call).and_return('2026.4.19')

      expect do
        described_class.run(
          xcodeproj: project_path,
          target_name: %w[App Widget],
          timezone: 'UTC',
          skip_if_same: true,
          fail_if_version_decreases: true,
          dry_run: false,
          override_version: nil
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /Refusing to decrease MARKETING_VERSION/)
    end

    it 'accepts an array target_name through the Fastlane DSL helper' do
      project_path = SpecSupport::ProjectFactory.create!(
        targets: {
          'App' => '2026.4.18',
          'Widget' => '2026.4.18'
        }
      )

      fastfile = Fastlane::FastFile.new.parse(<<~FASTFILE)
        platform :ios do
          lane :test_multi_target_dsl do
            set_marketing_version_from_date(
              xcodeproj: #{project_path.inspect},
              target_name: ['App', 'Widget'],
              timezone: 'UTC',
              skip_if_same: true,
              fail_if_version_decreases: true,
              dry_run: false,
              override_version: '2026.4.19'
            )
          end
        end
      FASTFILE

      expect(fastfile.runner.execute(:test_multi_target_dsl, :ios, nil)).to eq('2026.4.19')
      expect(
        Fastlane::DateVersioning::TargetMarketingVersionReader.call(xcodeproj_path: project_path, target_name: 'App')
      ).to eq('2026.4.19')
      expect(
        Fastlane::DateVersioning::TargetMarketingVersionReader.call(xcodeproj_path: project_path, target_name: 'Widget')
      ).to eq('2026.4.19')
    end
  end
end
