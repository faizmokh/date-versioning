require 'spec_helper'

RSpec.describe Fastlane::DateVersioning::DateVersionFormatter do
  it 'formats the current UTC date as YYYY.M.D' do
    now = Time.utc(2026, 4, 18, 9, 30, 0)

    expect(described_class.call(timezone: 'UTC', now: now)).to eq('2026.4.18')
  end

  it 'converts the date into the requested timezone' do
    now = Time.utc(2026, 4, 18, 23, 30, 0)

    expect(described_class.call(timezone: 'Asia/Kuala_Lumpur', now: now)).to eq('2026.4.19')
  end

  it 'raises for an invalid timezone' do
    expect do
      described_class.call(timezone: 'Mars/Olympus', now: Time.utc(2026, 4, 18))
    end.to raise_error(ArgumentError, /Invalid timezone/)
  end
end
