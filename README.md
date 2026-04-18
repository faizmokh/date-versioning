# fastlane-plugin-date_versioning

Fastlane plugin scaffold for setting an iOS target's `MARKETING_VERSION` from the current date.

## What It Is For

This plugin is intended to provide a Fastlane action that derives an iOS marketing version from the current date.

## Status

This repository is currently scaffold only. The gem loads and exposes its version, but the date-versioning action has not been implemented yet.

## Development

Install dependencies:

```bash
bundle install
```

Run the test suite:

```bash
bundle exec rake spec
```

Verify the plugin loads:

```bash
bundle exec ruby -e "require './lib/fastlane/plugin/date_versioning'; puts Fastlane::DateVersioning::VERSION"
```
