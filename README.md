# fastlane-plugin-date_versioning

Set an iOS target's `MARKETING_VERSION` from the current date.

## Install in Your App

Add this to `fastlane/Pluginfile`:

```ruby
gem "fastlane-plugin-date_versioning", git: "https://github.com/<org>/date-versioning.git"
```

Replace the git URL with your plugin repository, then run:

```bash
bundle install
```

## Use in Fastfile

```ruby
platform :ios do
  lane :release do
    set_marketing_version_from_date(
      xcodeproj: "MyApp.xcodeproj",
      target_name: "MyApp",
      timezone: "Asia/Kuala_Lumpur",
      skip_if_same: true,
      fail_if_version_decreases: true
    )

    increment_build_number(
      xcodeproj: "MyApp.xcodeproj"
    )
  end
end
```

## What It Does

- Updates `MARKETING_VERSION` only
- Reads and writes all build configurations for one target
- Works with `.xcodeproj` projects that store the version in `MARKETING_VERSION`
- Leaves build number handling to your existing Fastlane flow

## Parameters

- `xcodeproj`: Required. Path to the `.xcodeproj` file.
- `target_name`: Required. Target to update.
- `timezone`: Optional. IANA timezone identifier. Default: `"UTC"`.
- `skip_if_same`: Optional. Skip writing when the version is unchanged. Default: `true`.
- `fail_if_version_decreases`: Optional. Fail when the candidate version is lower. Default: `true`.
- `dry_run`: Optional. Log the candidate version without writing it. Default: `false`.
- `override_version`: Optional. Use an explicit version instead of the date.

## Notes

- Generated format: `YYYY.M.D`
- Invalid timezone identifiers fail only when generating the date-based version
- If you ship more than once on the same day, use `override_version`
- This plugin does not manage build numbers

## Examples

Dry run:

```ruby
set_marketing_version_from_date(
  xcodeproj: "MyApp.xcodeproj",
  target_name: "MyApp",
  dry_run: true
)
```

Same-day follow-up release:

```ruby
set_marketing_version_from_date(
  xcodeproj: "MyApp.xcodeproj",
  target_name: "MyApp",
  override_version: "2026.4.18.1"
)
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rake
```
