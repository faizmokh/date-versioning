# Date-Based Marketing Version Plugin Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Fastlane plugin that updates an iOS target's `MARKETING_VERSION` from the current date, with UTC-by-default timezone handling, same-version skip logic, backwards-bump protection, and manual override support.

**Architecture:** Build a standard Fastlane plugin gem at the repository root, keep one public action named `set_marketing_version_from_date`, and isolate date formatting, version validation/comparison, and `xcodeproj` read/write behavior into small Ruby classes. Read the current version from all build configurations on the chosen target, fail on config drift, and write one consistent value back to every build configuration.

**Tech Stack:** Ruby, Bundler, Fastlane plugin API, `xcodeproj`, `tzinfo`, RSpec, `tmpdir`

---

### Task 1: Scaffold the plugin gem at the repository root

**Files:**
- Create: `Gemfile`
- Create: `Rakefile`
- Create: `.gitignore`
- Create: `README.md`
- Create: `fastlane-plugin-date_versioning.gemspec`
- Create: `lib/fastlane/plugin/date_versioning.rb`
- Create: `lib/fastlane/plugin/date_versioning/version.rb`
- Create: `lib/fastlane/plugin/date_versioning/helper/date_versioning_helper.rb`
- Create: `spec/spec_helper.rb`

**Step 1: Write the gem scaffold**

```ruby
# Gemfile
source "https://rubygems.org"

gemspec

gem "fastlane"
gem "rspec"
```

```ruby
# fastlane-plugin-date_versioning.gemspec
Gem::Specification.new do |spec|
  spec.name          = "fastlane-plugin-date_versioning"
  spec.version       = Fastlane::DateVersioning::VERSION
  spec.author        = "TODO"
  spec.email         = "TODO"
  spec.summary       = "Set MARKETING_VERSION from the current date"
  spec.homepage      = "TODO"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "spec/**/*", "README.md", "LICENSE", "*.gemspec"]
  spec.require_paths = ["lib"]

  spec.add_dependency "fastlane", ">= 2.0.0"
  spec.add_dependency "xcodeproj", ">= 1.27"
  spec.add_dependency "tzinfo", ">= 2.0"
  spec.add_development_dependency "rspec", ">= 3.0"
end
```

**Step 2: Write the entrypoint files**

```ruby
# lib/fastlane/plugin/date_versioning.rb
require "fastlane/action"
require_relative "date_versioning/version"
require_relative "date_versioning/helper/date_versioning_helper"
```

```ruby
# lib/fastlane/plugin/date_versioning/version.rb
module Fastlane
  module DateVersioning
    VERSION = "0.1.0"
  end
end
```

```ruby
# spec/spec_helper.rb
require "bundler/setup"
require "fastlane"
require "fastlane/plugin/date_versioning"
```

**Step 3: Install dependencies**

Run: `bundle install`

Expected: Bundler installs `fastlane`, `xcodeproj`, `tzinfo`, and `rspec` with no version conflicts.

**Step 4: Verify the plugin loads**

Run: `bundle exec ruby -e "require './lib/fastlane/plugin/date_versioning'; puts Fastlane::DateVersioning::VERSION"`

Expected: prints `0.1.0`

**Step 5: Commit**

```bash
git add Gemfile Rakefile .gitignore README.md fastlane-plugin-date_versioning.gemspec lib spec/spec_helper.rb
git commit -m "chore: scaffold fastlane plugin gem"
```

### Task 2: Implement timezone-aware date formatting

**Files:**
- Create: `lib/fastlane/plugin/date_versioning/date_version_formatter.rb`
- Create: `spec/date_version_formatter_spec.rb`
- Modify: `lib/fastlane/plugin/date_versioning.rb`
- Modify: `spec/spec_helper.rb`

**Step 1: Write the failing formatter spec**

```ruby
describe Fastlane::DateVersioning::DateVersionFormatter do
  it "formats the current UTC date as YYYY.M.D" do
    now = Time.utc(2026, 4, 18, 9, 30, 0)

    expect(described_class.call(timezone: "UTC", now: now)).to eq("2026.4.18")
  end

  it "converts the date into the requested timezone" do
    now = Time.utc(2026, 4, 18, 23, 30, 0)

    expect(described_class.call(timezone: "Asia/Kuala_Lumpur", now: now)).to eq("2026.4.19")
  end

  it "raises for an invalid timezone" do
    expect {
      described_class.call(timezone: "Mars/Olympus", now: Time.utc(2026, 4, 18))
    }.to raise_error(ArgumentError, /Invalid timezone/)
  end
end
```

**Step 2: Run the formatter spec to verify it fails**

Run: `bundle exec rspec spec/date_version_formatter_spec.rb`

Expected: FAIL with `NameError` for `Fastlane::DateVersioning::DateVersionFormatter`

**Step 3: Write the minimal formatter implementation**

```ruby
require "tzinfo"

module Fastlane
  module DateVersioning
    class DateVersionFormatter
      def self.call(timezone:, now: Time.now.utc)
        current_time = if timezone == "UTC"
          now.getutc
        else
          TZInfo::Timezone.get(timezone).to_local(now.getutc)
        end

        "#{current_time.year}.#{current_time.month}.#{current_time.day}"
      rescue TZInfo::InvalidTimezoneIdentifier
        raise ArgumentError, "Invalid timezone: #{timezone}"
      end
    end
  end
end
```

Add a `require_relative "date_versioning/date_version_formatter"` line to `lib/fastlane/plugin/date_versioning.rb`.

**Step 4: Run the formatter spec to verify it passes**

Run: `bundle exec rspec spec/date_version_formatter_spec.rb`

Expected: PASS with 3 examples, 0 failures

**Step 5: Commit**

```bash
git add lib/fastlane/plugin/date_versioning.rb lib/fastlane/plugin/date_versioning/date_version_formatter.rb spec/date_version_formatter_spec.rb spec/spec_helper.rb
git commit -m "feat: add date-based version formatter"
```

### Task 3: Implement version validation and numeric comparison

**Files:**
- Create: `lib/fastlane/plugin/date_versioning/marketing_version_validator.rb`
- Create: `lib/fastlane/plugin/date_versioning/marketing_version_comparer.rb`
- Create: `spec/marketing_version_validator_spec.rb`
- Create: `spec/marketing_version_comparer_spec.rb`
- Modify: `lib/fastlane/plugin/date_versioning.rb`

**Step 1: Write the failing validator and comparer specs**

```ruby
describe Fastlane::DateVersioning::MarketingVersionValidator do
  it "accepts numeric dotted versions" do
    expect(described_class.valid?("2026.4.18")).to eq(true)
    expect(described_class.valid?("1.2")).to eq(true)
  end

  it "rejects non-numeric suffixes" do
    expect(described_class.valid?("2026.4.18-beta")).to eq(false)
  end
end
```

```ruby
describe Fastlane::DateVersioning::MarketingVersionComparer do
  it "compares numerically instead of lexically" do
    expect(described_class.compare("2026.4.10", "2026.4.9")).to eq(1)
  end

  it "treats missing trailing components as zeroes" do
    expect(described_class.compare("1.2", "1.2.0")).to eq(0)
  end

  it "raises for invalid versions" do
    expect {
      described_class.compare("1.2-beta", "1.2")
    }.to raise_error(ArgumentError, /Invalid marketing version/)
  end
end
```

**Step 2: Run the new specs to verify they fail**

Run: `bundle exec rspec spec/marketing_version_validator_spec.rb spec/marketing_version_comparer_spec.rb`

Expected: FAIL with `NameError` for the missing classes

**Step 3: Write the minimal validator and comparer**

```ruby
module Fastlane
  module DateVersioning
    class MarketingVersionValidator
      PATTERN = /\A\d+(?:\.\d+)+\z/

      def self.valid?(value)
        value.is_a?(String) && value.match?(PATTERN)
      end

      def self.validate!(value)
        raise ArgumentError, "Invalid marketing version: #{value}" unless valid?(value)
      end
    end
  end
end
```

```ruby
module Fastlane
  module DateVersioning
    class MarketingVersionComparer
      def self.compare(left, right)
        left_parts = normalize(left)
        right_parts = normalize(right)

        (0...[left_parts.length, right_parts.length].max).each do |index|
          comparison = (left_parts[index] || 0) <=> (right_parts[index] || 0)
          return comparison unless comparison.zero?
        end

        0
      end

      def self.normalize(value)
        MarketingVersionValidator.validate!(value)
        value.split(".").map(&:to_i)
      end
      private_class_method :normalize
    end
  end
end
```

Add `require_relative` entries for both files in `lib/fastlane/plugin/date_versioning.rb`.

**Step 4: Run the specs to verify they pass**

Run: `bundle exec rspec spec/marketing_version_validator_spec.rb spec/marketing_version_comparer_spec.rb`

Expected: PASS with 5 examples, 0 failures

**Step 5: Commit**

```bash
git add lib/fastlane/plugin/date_versioning.rb lib/fastlane/plugin/date_versioning/marketing_version_validator.rb lib/fastlane/plugin/date_versioning/marketing_version_comparer.rb spec/marketing_version_validator_spec.rb spec/marketing_version_comparer_spec.rb
git commit -m "feat: add marketing version validation"
```

### Task 4: Implement `xcodeproj` helpers to read and write `MARKETING_VERSION`

**Files:**
- Create: `lib/fastlane/plugin/date_versioning/target_marketing_version_reader.rb`
- Create: `lib/fastlane/plugin/date_versioning/target_marketing_version_writer.rb`
- Create: `spec/support/project_factory.rb`
- Create: `spec/target_marketing_version_reader_spec.rb`
- Create: `spec/target_marketing_version_writer_spec.rb`
- Modify: `lib/fastlane/plugin/date_versioning.rb`
- Modify: `spec/spec_helper.rb`

**Step 1: Write the failing reader and writer specs**

```ruby
describe Fastlane::DateVersioning::TargetMarketingVersionReader do
  it "returns the shared MARKETING_VERSION when all build configurations agree" do
    project_path = SpecSupport::ProjectFactory.create!(target_name: "Demo", version: "2026.4.18")

    expect(described_class.call(xcodeproj_path: project_path, target_name: "Demo")).to eq("2026.4.18")
  end

  it "raises when build configurations disagree" do
    project_path = SpecSupport::ProjectFactory.create!(
      target_name: "Demo",
      build_settings: { "Debug" => "2026.4.18", "Release" => "2026.4.19" }
    )

    expect {
      described_class.call(xcodeproj_path: project_path, target_name: "Demo")
    }.to raise_error(ArgumentError, /Build configurations do not agree/)
  end
end
```

```ruby
describe Fastlane::DateVersioning::TargetMarketingVersionWriter do
  it "writes the same MARKETING_VERSION to every build configuration" do
    project_path = SpecSupport::ProjectFactory.create!(target_name: "Demo", version: "2026.4.18")

    described_class.call(xcodeproj_path: project_path, target_name: "Demo", version: "2026.4.19")

    expect(
      Fastlane::DateVersioning::TargetMarketingVersionReader.call(xcodeproj_path: project_path, target_name: "Demo")
    ).to eq("2026.4.19")
  end
end
```

**Step 2: Run the specs to verify they fail**

Run: `bundle exec rspec spec/target_marketing_version_reader_spec.rb spec/target_marketing_version_writer_spec.rb`

Expected: FAIL with `NameError` for the missing reader, writer, or support helper

**Step 3: Write a temporary project factory and the minimal reader/writer**

```ruby
# spec/support/project_factory.rb
require "tmpdir"
require "xcodeproj"

module SpecSupport
  module ProjectFactory
    def self.create!(target_name:, version: nil, build_settings: nil)
      dir = Dir.mktmpdir
      path = File.join(dir, "Demo.xcodeproj")
      project = Xcodeproj::Project.new(path)
      target = project.new_target(:application, target_name, :ios, "17.0")

      settings = build_settings || { "Debug" => version, "Release" => version }
      target.build_configurations.each do |config|
        config.build_settings["MARKETING_VERSION"] = settings.fetch(config.name)
      end

      project.save
      path
    end
  end
end
```

```ruby
# lib/fastlane/plugin/date_versioning/target_marketing_version_reader.rb
require "xcodeproj"

module Fastlane
  module DateVersioning
    class TargetMarketingVersionReader
      def self.call(xcodeproj_path:, target_name:)
        project = Xcodeproj::Project.open(xcodeproj_path)
        target = project.targets.find { |item| item.name == target_name }
        raise ArgumentError, "Target not found: #{target_name}" unless target

        versions = target.build_configurations.to_h do |config|
          [config.name, config.build_settings["MARKETING_VERSION"]]
        end

        raise ArgumentError, "MARKETING_VERSION is missing" if versions.values.any?(&:nil?)
        raise ArgumentError, "Build configurations do not agree: #{versions}" if versions.values.uniq.length != 1

        versions.values.first
      end
    end
  end
end
```

```ruby
# lib/fastlane/plugin/date_versioning/target_marketing_version_writer.rb
require "xcodeproj"

module Fastlane
  module DateVersioning
    class TargetMarketingVersionWriter
      def self.call(xcodeproj_path:, target_name:, version:)
        project = Xcodeproj::Project.open(xcodeproj_path)
        target = project.targets.find { |item| item.name == target_name }
        raise ArgumentError, "Target not found: #{target_name}" unless target

        target.build_configurations.each do |config|
          config.build_settings["MARKETING_VERSION"] = version
        end

        project.save
      end
    end
  end
end
```

Require the support file from `spec/spec_helper.rb` and the new library files from `lib/fastlane/plugin/date_versioning.rb`.

**Step 4: Run the specs to verify they pass**

Run: `bundle exec rspec spec/target_marketing_version_reader_spec.rb spec/target_marketing_version_writer_spec.rb`

Expected: PASS with the reader and writer examples green

**Step 5: Commit**

```bash
git add lib/fastlane/plugin/date_versioning.rb lib/fastlane/plugin/date_versioning/target_marketing_version_reader.rb lib/fastlane/plugin/date_versioning/target_marketing_version_writer.rb spec/spec_helper.rb spec/support/project_factory.rb spec/target_marketing_version_reader_spec.rb spec/target_marketing_version_writer_spec.rb
git commit -m "feat: add MARKETING_VERSION project helpers"
```

### Task 5: Implement the Fastlane action and its guardrails

**Files:**
- Create: `lib/fastlane/plugin/date_versioning/actions/set_marketing_version_from_date_action.rb`
- Create: `spec/set_marketing_version_from_date_action_spec.rb`
- Modify: `lib/fastlane/plugin/date_versioning.rb`
- Modify: `README.md`

**Step 1: Write the failing action spec**

```ruby
describe Fastlane::Actions::SetMarketingVersionFromDateAction do
  let(:project_path) { SpecSupport::ProjectFactory.create!(target_name: "Demo", version: "2026.4.18") }

  it "writes the computed date version" do
    allow(Fastlane::DateVersioning::DateVersionFormatter).to receive(:call).and_return("2026.4.19")

    described_class.run(
      xcodeproj: project_path,
      target_name: "Demo",
      timezone: "UTC",
      skip_if_same: true,
      fail_if_version_decreases: true,
      dry_run: false,
      override_version: nil
    )

    expect(
      Fastlane::DateVersioning::TargetMarketingVersionReader.call(xcodeproj_path: project_path, target_name: "Demo")
    ).to eq("2026.4.19")
  end

  it "does not write when dry_run is true" do
    allow(Fastlane::DateVersioning::DateVersionFormatter).to receive(:call).and_return("2026.4.19")

    described_class.run(
      xcodeproj: project_path,
      target_name: "Demo",
      timezone: "UTC",
      skip_if_same: true,
      fail_if_version_decreases: true,
      dry_run: true,
      override_version: nil
    )

    expect(
      Fastlane::DateVersioning::TargetMarketingVersionReader.call(xcodeproj_path: project_path, target_name: "Demo")
    ).to eq("2026.4.18")
  end
end
```

**Step 2: Run the action spec to verify it fails**

Run: `bundle exec rspec spec/set_marketing_version_from_date_action_spec.rb`

Expected: FAIL with `NameError` for `SetMarketingVersionFromDateAction`

**Step 3: Write the minimal action implementation**

```ruby
module Fastlane
  module Actions
    class SetMarketingVersionFromDateAction < Action
      def self.run(params)
        candidate = params[:override_version] || Fastlane::DateVersioning::DateVersionFormatter.call(timezone: params[:timezone])
        Fastlane::DateVersioning::MarketingVersionValidator.validate!(candidate)

        current = Fastlane::DateVersioning::TargetMarketingVersionReader.call(
          xcodeproj_path: params[:xcodeproj],
          target_name: params[:target_name]
        )

        if params[:skip_if_same] && Fastlane::DateVersioning::MarketingVersionComparer.compare(candidate, current).zero?
          UI.message("MARKETING_VERSION already #{candidate}; skipping")
          return candidate
        end

        if params[:fail_if_version_decreases] && Fastlane::DateVersioning::MarketingVersionComparer.compare(candidate, current) < 0
          UI.user_error!("Refusing to decrease MARKETING_VERSION from #{current} to #{candidate}")
        end

        UI.message("Current MARKETING_VERSION: #{current}")
        UI.message("Candidate MARKETING_VERSION: #{candidate}")

        return candidate if params[:dry_run]

        Fastlane::DateVersioning::TargetMarketingVersionWriter.call(
          xcodeproj_path: params[:xcodeproj],
          target_name: params[:target_name],
          version: candidate
        )

        candidate
      end
    end
  end
end
```

Also add `available_options`, `description`, `authors`, and `is_supported?` with these options:

```ruby
FastlaneCore::ConfigItem.new(key: :xcodeproj, optional: false, type: String)
FastlaneCore::ConfigItem.new(key: :target_name, optional: false, type: String)
FastlaneCore::ConfigItem.new(key: :timezone, optional: true, type: String, default_value: "UTC")
FastlaneCore::ConfigItem.new(key: :skip_if_same, optional: true, type: Boolean, default_value: true)
FastlaneCore::ConfigItem.new(key: :fail_if_version_decreases, optional: true, type: Boolean, default_value: true)
FastlaneCore::ConfigItem.new(key: :dry_run, optional: true, type: Boolean, default_value: false)
FastlaneCore::ConfigItem.new(key: :override_version, optional: true, type: String)
```

Require the action file from `lib/fastlane/plugin/date_versioning.rb`.

**Step 4: Run the action spec to verify it passes**

Run: `bundle exec rspec spec/set_marketing_version_from_date_action_spec.rb`

Expected: PASS for the happy path and dry-run examples

**Step 5: Expand action coverage before committing**

Add these additional examples to `spec/set_marketing_version_from_date_action_spec.rb`:

```ruby
it "skips when the candidate matches the current version"
it "fails when the candidate version decreases"
it "uses override_version when present"
it "fails when override_version is invalid"
it "fails when the target is missing"
```

Run: `bundle exec rspec spec/set_marketing_version_from_date_action_spec.rb`

Expected: PASS with all action guardrail examples green

**Step 6: Commit**

```bash
git add lib/fastlane/plugin/date_versioning.rb lib/fastlane/plugin/date_versioning/actions/set_marketing_version_from_date_action.rb spec/set_marketing_version_from_date_action_spec.rb README.md
git commit -m "feat: add marketing version action"
```

### Task 6: Document usage and verify the full suite

**Files:**
- Modify: `README.md`
- Modify: `Rakefile`

**Step 1: Add the README usage section**

```markdown
## Usage

```ruby
set_marketing_version_from_date(
  xcodeproj: "MyApp.xcodeproj",
  target_name: "MyApp",
  timezone: "UTC",
  skip_if_same: true,
  fail_if_version_decreases: true,
  dry_run: false,
  override_version: nil
)
```

This plugin only manages the marketing version. You still need a separate monotonically increasing build number strategy. Same-day resubmits are fine, but a second distinct release on the same day may require `override_version`.
```

**Step 2: Make the default `rake` task run specs**

```ruby
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)
task default: :spec
```

**Step 3: Run the full test suite**

Run: `bundle exec rspec`

Expected: PASS with all formatter, validator, comparer, reader, writer, and action specs green

**Step 4: Run the default rake task**

Run: `bundle exec rake`

Expected: PASS and execute the same green RSpec suite

**Step 5: Commit**

```bash
git add README.md Rakefile
git commit -m "docs: document plugin usage"
```

### Task 7: Final manual smoke test against a temporary project

**Files:**
- Modify: `spec/support/project_factory.rb`
- Optional create: `tmp/manual_smoke_test.rb`

**Step 1: Write a one-off smoke script**

```ruby
require_relative "../spec/support/project_factory"
require_relative "../lib/fastlane/plugin/date_versioning"

project_path = SpecSupport::ProjectFactory.create!(target_name: "Demo", version: "2026.4.18")

Fastlane::Actions::SetMarketingVersionFromDateAction.run(
  xcodeproj: project_path,
  target_name: "Demo",
  timezone: "UTC",
  skip_if_same: true,
  fail_if_version_decreases: true,
  dry_run: false,
  override_version: "2026.4.19"
)

puts Fastlane::DateVersioning::TargetMarketingVersionReader.call(xcodeproj_path: project_path, target_name: "Demo")
```

**Step 2: Run the smoke test**

Run: `bundle exec ruby tmp/manual_smoke_test.rb`

Expected: prints `2026.4.19`

**Step 3: Remove the script if you do not want it committed**

Run: `rm "tmp/manual_smoke_test.rb"`

Expected: the repository keeps only production and test files

**Step 4: Commit only if the smoke script is meant to stay**

```bash
git add spec/support/project_factory.rb tmp/manual_smoke_test.rb
git commit -m "test: add manual smoke coverage"
```

Execution notes:

- Follow `@superpowers:test-driven-development` while implementing each task.
- Use `@superpowers:verification-before-completion` before claiming the work is finished.
- Do not add Info.plist support, multiple format presets, or build-number logic during this plan.
