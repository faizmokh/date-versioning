# Multi-Target Support Design

## Goal

Allow `set_marketing_version_from_date` to update multiple app targets in one action call while preserving current single-target usage.

## Scope

- Keep using `target_name` as the public parameter.
- Accept `target_name` as either `String` or `Array<String>`.
- Compute one candidate version and apply it to every requested target.
- Validate every requested target before saving project changes.
- Preserve existing single-target behavior for current callers.

## Non-Goals

- New public action names
- Separate `target_names` parameter
- Info.plist writes
- Build number changes

## Public API

```ruby
set_marketing_version_from_date(
  xcodeproj: "MyApp.xcodeproj",
  target_name: ["MyApp", "MyWidgetExtension"],
  timezone: "UTC",
  skip_if_same: true,
  fail_if_version_decreases: true,
  dry_run: false,
  override_version: nil
)
```

## Behavior

1. Normalize `target_name` into a unique ordered array.
2. Compute or accept the candidate version.
3. Read the current `MARKETING_VERSION` for every requested target.
4. Fail if any target is missing, has missing `MARKETING_VERSION`, or has build configuration drift.
5. Skip only when every requested target already matches the candidate version.
6. Fail decrease protection when any requested target would move backwards.
7. In dry run mode, log the candidate without saving.
8. Otherwise write the candidate version to every requested target and save once.

## Architecture

- Keep `TargetMarketingVersionReader` and `TargetMarketingVersionWriter` for existing single-target behavior.
- Add `TargetMarketingVersionProjectEditor` to open one project, validate multiple targets, read their versions, and perform multi-target writes.
- Keep the public action responsible for normalization, logging, and guardrails.

## Testing

- Extend temporary project generation to create multiple targets.
- Add project editor specs for multi-target reads and writes.
- Add action specs for array input, multi-target skip behavior, and decrease protection.
