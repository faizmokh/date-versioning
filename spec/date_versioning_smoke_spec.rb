require 'spec_helper'

RSpec.describe Fastlane::DateVersioning do
  it 'exposes a string version constant' do
    expect(described_class::VERSION).to be_a(String)
  end
end
