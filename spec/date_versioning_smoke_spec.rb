require 'spec_helper'

RSpec.describe Fastlane::DateVersioning do
  it 'exposes a string version constant' do
    expect(described_class::VERSION).to be_a(String)
  end

  it 'registers plugin actions through Fastlane plugin manager' do
    manager = Fastlane::PluginManager.new

    expect do
      manager.store_plugin_reference('fastlane-plugin-date_versioning')
    end.not_to raise_error

    expect(
      manager.plugin_references.fetch('fastlane-plugin-date_versioning').fetch(:actions)
    ).to include(:set_marketing_version_from_date)
  end
end
