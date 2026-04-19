require 'spec_helper'

RSpec.describe Fastlane::DateVersioning::TargetMarketingVersionProjectEditor do
  describe '.read_versions' do
    it 'returns one shared version per requested target' do
      project_path = SpecSupport::ProjectFactory.create!(
        targets: {
          'App' => '2026.4.18',
          'Widget' => '2026.4.18'
        }
      )

      expect(
        described_class.read_versions(
          xcodeproj_path: project_path,
          target_names: %w[App Widget]
        )
      ).to eq(
        'App' => '2026.4.18',
        'Widget' => '2026.4.18'
      )
    end
  end

  describe '.write_version' do
    it 'writes one version to every requested target' do
      project_path = SpecSupport::ProjectFactory.create!(
        targets: {
          'App' => '2026.4.18',
          'Widget' => '2026.4.18'
        }
      )

      described_class.write_version(
        xcodeproj_path: project_path,
        target_names: %w[App Widget],
        version: '2026.4.19'
      )

      expect(
        Fastlane::DateVersioning::TargetMarketingVersionReader.call(
          xcodeproj_path: project_path,
          target_name: 'App'
        )
      ).to eq('2026.4.19')

      expect(
        Fastlane::DateVersioning::TargetMarketingVersionReader.call(
          xcodeproj_path: project_path,
          target_name: 'Widget'
        )
      ).to eq('2026.4.19')
    end

    it 'fails before writing when any target is missing' do
      project_path = SpecSupport::ProjectFactory.create!(
        targets: { 'App' => '2026.4.18' }
      )

      expect do
        described_class.write_version(
          xcodeproj_path: project_path,
          target_names: %w[App Missing],
          version: '2026.4.19'
        )
      end.to raise_error(ArgumentError, /Target not found: Missing/)

      expect(
        Fastlane::DateVersioning::TargetMarketingVersionReader.call(
          xcodeproj_path: project_path,
          target_name: 'App'
        )
      ).to eq('2026.4.18')
    end
  end
end
