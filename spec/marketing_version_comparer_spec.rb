require 'spec_helper'

RSpec.describe Fastlane::DateVersioning::MarketingVersionComparer do
  describe '.compare' do
    it 'compares numerically instead of lexically' do
      expect(described_class.compare('2026.4.10', '2026.4.9')).to eq(1)
    end

    it 'treats missing trailing components as zeroes' do
      expect(described_class.compare('1.2', '1.2.0')).to eq(0)
    end

    it 'treats a single component version as equal to a zero-padded version' do
      expect(described_class.compare('1', '1.0')).to eq(0)
    end

    it 'raises for invalid versions' do
      expect do
        described_class.compare('1.2-beta', '1.2')
      end.to raise_error(ArgumentError, /Invalid marketing version/)
    end
  end
end
