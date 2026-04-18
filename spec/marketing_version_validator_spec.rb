require 'spec_helper'

RSpec.describe Fastlane::DateVersioning::MarketingVersionValidator do
  describe '.valid?' do
    it 'accepts numeric dotted versions' do
      expect(described_class.valid?('2026.4.18')).to eq(true)
      expect(described_class.valid?('1.2')).to eq(true)
    end

    it 'accepts a single numeric component' do
      expect(described_class.valid?('1')).to eq(true)
    end

    it 'rejects non-numeric suffixes' do
      expect(described_class.valid?('2026.4.18-beta')).to eq(false)
    end
  end

  describe '.validate!' do
    it 'raises for an invalid marketing version' do
      expect do
        described_class.validate!('2026.4.18-beta')
      end.to raise_error(ArgumentError, /Invalid marketing version/)
    end
  end
end
