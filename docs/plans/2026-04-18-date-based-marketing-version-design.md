# Date-Based Marketing Version Plugin Design

## Goal

Build a Fastlane plugin that updates an iOS target's `MARKETING_VERSION` from the current date, with guardrails for no-op runs, backwards version bumps, and same-day manual overrides.

## Confirmed v1 Scope

- Support `.xcodeproj` input only.
- Require an explicit `target_name`.
- Use `MARKETING_VERSION` as the only read/write source of truth.
- Update all build configurations for the chosen target.
- Default timezone to `UTC` when omitted.
- Support one computed format only: `YYYY.M.D`.
- Support `override_version`, `dry_run`, `skip_if_same`, and `fail_if_version_decreases`.

## Non-Goals

- Build number management
- App Store Connect checks
- Info.plist writes
- Arbitrary format strings or token DSLs
- Multiple versioning strategies
- Release automation

## Public Action

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

## Architecture

Keep one public action and push logic into small plain Ruby classes so each behavior can be tested without invoking Fastlane end-to-end.

- `DateVersionFormatter`
- `MarketingVersionValidator`
- `MarketingVersionComparer`
- `TargetMarketingVersionReader`
- `TargetMarketingVersionWriter`
- `SetMarketingVersionFromDateAction`

## Data Flow

1. Action resolves the candidate version.
2. If `override_version` is present, validate and use it.
3. Otherwise compute `YYYY.M.D` from the chosen timezone.
4. Read the current `MARKETING_VERSION` from the named target.
5. Fail if the target is missing, if any build configuration is missing `MARKETING_VERSION`, or if configurations disagree.
6. Apply guardrails:
   - same version + `skip_if_same` => log and exit
   - lower version + `fail_if_version_decreases` => fail
7. If `dry_run` is true, log the change without saving.
8. Otherwise write the candidate version to every build configuration for the target and save the project.

## Validation Rules

- Computed versions always use numeric dotted components: `YYYY.M.D`.
- `override_version` and existing project versions must be numeric dotted strings.
- Comparison is numeric, not lexical.
- Mixed component counts are normalized with trailing zeroes for comparison only.
- Invalid timezone values fail fast.

## Error Handling

Fail fast on these conditions:

- invalid or unreadable `.xcodeproj` path
- missing target
- missing `MARKETING_VERSION`
- inconsistent `MARKETING_VERSION` values across build configurations
- invalid `override_version`
- unparseable existing marketing version
- attempted version decrease when the guardrail is enabled

The action should log the current version, candidate version, timezone, and final outcome so lane output is easy to audit.

## Testing Strategy

- Unit tests for formatter, validator, and comparer.
- Reader/writer tests using temporary `.xcodeproj` fixtures generated with the `xcodeproj` gem inside the test run.
- Action tests covering happy path, dry run, skip, override, and failure cases.

The tests should avoid committed `.pbxproj` fixtures unless temporary project generation proves too brittle.

## Why This Shape

This design keeps v1 small and predictable while still covering the operational risks that matter in CI: timezone drift, accidental no-op runs, and accidental backwards bumps. It avoids speculative abstractions until real plugin users force them.
