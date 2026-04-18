require 'spec_helper'

RSpec.describe Fastlane::DateVersioning::TargetMarketingVersionReader do
  describe '.call' do
    it 'returns the shared MARKETING_VERSION when all build configurations agree' do
      project_path = SpecSupport::ProjectFactory.create!(target_name: 'Demo', version: '2026.4.18')

      expect(described_class.call(xcodeproj_path: project_path, target_name: 'Demo')).to eq('2026.4.18')
    end

    it 'raises when the target is missing' do
      project_path = SpecSupport::ProjectFactory.create!(target_name: 'Demo', version: '2026.4.18')

      expect do
        described_class.call(xcodeproj_path: project_path, target_name: 'Other')
      end.to raise_error(ArgumentError, /Target not found/)
    end

    it 'raises when MARKETING_VERSION is missing from any build configuration' do
      project_path = SpecSupport::ProjectFactory.create!(
        target_name: 'Demo',
        build_settings: { 'Debug' => '2026.4.18', 'Release' => nil }
      )

      expect do
        described_class.call(xcodeproj_path: project_path, target_name: 'Demo')
      end.to raise_error(ArgumentError, /MARKETING_VERSION is missing/)
    end

    it 'raises when build configurations disagree on MARKETING_VERSION' do
      project_path = SpecSupport::ProjectFactory.create!(
        target_name: 'Demo',
        build_settings: { 'Debug' => '2026.4.18', 'Release' => '2026.4.19' }
      )

      expect do
        described_class.call(xcodeproj_path: project_path, target_name: 'Demo')
      end.to raise_error(ArgumentError, /Build configurations do not agree/)
    end
  end
end
