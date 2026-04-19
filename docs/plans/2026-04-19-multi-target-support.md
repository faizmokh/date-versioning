# Multi-Target Support Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Allow `set_marketing_version_from_date` to accept `target_name` as either a single string or an array of target names, and update all requested app targets in one run.

**Architecture:** Keep the existing single-target reader and writer for current callers, add one project-level helper for batch validation and writes, and update the action to normalize string-or-array input before applying guardrails.

**Tech Stack:** Ruby, fastlane, xcodeproj, RSpec

---

### Task 1: Add Multi-Target Project Editing

**Files:**
- Create: `lib/fastlane/plugin/date_versioning/target_marketing_version_project_editor.rb`
- Modify: `lib/fastlane/plugin/date_versioning.rb`
- Modify: `spec/support/project_factory.rb`
- Create: `spec/target_marketing_version_project_editor_spec.rb`

**Steps:**
1. Add a failing spec for reading versions from multiple targets.
2. Add a failing spec for writing one version to multiple targets.
3. Extend the temporary project factory to create multiple app targets.
4. Implement the new project editor helper.
5. Run the targeted specs until they pass.

### Task 2: Accept String or Array Target Input

**Files:**
- Modify: `lib/fastlane/plugin/date_versioning/actions/set_marketing_version_from_date_action.rb`
- Modify: `spec/set_marketing_version_from_date_action_spec.rb`

**Steps:**
1. Add failing action specs for array input.
2. Normalize `target_name` into an array.
3. Read all requested target versions before deciding skip or failure paths.
4. Write all requested targets when persistence is allowed.
5. Run the action specs and then the full suite.

### Task 3: Update Documentation

**Files:**
- Modify: `README.md`

**Steps:**
1. Document `target_name` as string-or-array input.
2. Add a multi-target usage example.
3. Re-run the test suite to confirm no regressions.
