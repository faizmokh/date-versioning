# fastlane-plugin-date_versioning

Fastlane plugin for setting an iOS target's `MARKETING_VERSION` from the current date.

## Scope

- This plugin only manages the marketing version.
- Build number strategy is separate and should be handled by your existing build-number flow.
- Current support is limited to `.xcodeproj` projects that store the target marketing version in `MARKETING_VERSION`.
- If you ship more than once on the same day, the second release may need `override_version` because the default date-based value will be unchanged.

## Action

Use the public Fastlane action `set_marketing_version_from_date`.

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

### Parameters

- `xcodeproj`: Required. Path to the `.xcodeproj` file to update.
- `target_name`: Required. Target whose `MARKETING_VERSION` will be read and written.
- `timezone`: Optional. IANA timezone identifier used when formatting the date version. Default: `"UTC"`. Invalid timezone identifiers cause the action to fail.
- `skip_if_same`: Optional. Skip writing when the candidate version matches the current version. Default: `true`.
- `fail_if_version_decreases`: Optional. Fail when the candidate version is lower than the current version. Default: `true`.
- `dry_run`: Optional. Compute and log the candidate version without writing it. Default: `false`.
- `override_version`: Optional. Use this explicit marketing version instead of generating one from the current date.

## Behavior

- The generated version format is `YYYY.M.D`.
- The action reads `MARKETING_VERSION` from all build configurations on the selected target.
- The action fails if the target is missing, `MARKETING_VERSION` is missing, or build configurations disagree on the current marketing version.
- The action writes one consistent `MARKETING_VERSION` back to every build configuration on the target.
- `override_version` must still be a numeric dotted marketing version such as `2026.4.19`.

## Examples

Set today's UTC-based marketing version:

```ruby
lane :release do
  set_marketing_version_from_date(
    xcodeproj: "MyApp.xcodeproj",
    target_name: "MyApp"
  )
end
```

Use a local timezone for the date boundary:

```ruby
set_marketing_version_from_date(
  xcodeproj: "MyApp.xcodeproj",
  target_name: "MyApp",
  timezone: "Asia/Kuala_Lumpur"
)
```

Preview the next version without writing it:

```ruby
set_marketing_version_from_date(
  xcodeproj: "MyApp.xcodeproj",
  target_name: "MyApp",
  dry_run: true
)
```

Force a same-day follow-up release version:

```ruby
set_marketing_version_from_date(
  xcodeproj: "MyApp.xcodeproj",
  target_name: "MyApp",
  override_version: "2026.4.18.1"
)
```

## Development

Install dependencies:

```bash
bundle install
```

Run specs directly:

```bash
bundle exec rspec
```

Run the default rake task:

```bash
bundle exec rake
```
