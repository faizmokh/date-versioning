require 'spec_helper'

RSpec.describe Fastlane::DateVersioning::TargetMarketingVersionWriter do
  describe '.call' do
    it 'writes the same MARKETING_VERSION to every build configuration' do
      project_path = SpecSupport::ProjectFactory.create!(target_name: 'Demo', version: '2026.4.18')

      described_class.call(xcodeproj_path: project_path, target_name: 'Demo', version: '2026.4.19')

      expect(
        Fastlane::DateVersioning::TargetMarketingVersionReader.call(xcodeproj_path: project_path, target_name: 'Demo')
      ).to eq('2026.4.19')
    end
  end
end
