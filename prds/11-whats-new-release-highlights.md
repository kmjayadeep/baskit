# What's New Release Highlights

> **Status:** Spec | **Date:** 2026-07-05

## Problem

The current What's New experience is not useful enough because it is tied to a single `latest.json` file for the current version. That makes it hard to serve users who skipped versions, and it can surface release-note style details that are obvious, technical, or not meaningful to everyday users.

Users should only see a short, helpful summary of meaningful product changes after updating the app.

## Goals

- Do **not** show What's New on first install.
- On a normal one-version update, show what changed in that update.
- When a user updates after skipping versions, show a concise summary of the most important user-facing highlights since their last installed/seen version.
- Avoid a full changelog for skipped versions.
- Exclude obvious, internal, technical, or non-user-facing changes.
- Keep content curated and predictable; do not rely on automatic release-note dumping.

## Non-Goals

- Do not show What's New to new users on their first app launch.
- Do not expose engineering implementation details, dependency updates, analytics/logging changes, or infrastructure work unless there is a clear user benefit.
- Do not build a remote CMS for What's New in this iteration.
- Do not require users to read every release note they missed.

## User Experience Requirements

### First Install

When the app is installed for the first time:

1. Store the current app version as the user's What's New baseline.
2. Do not show any What's New dialog.

### Update From Previous Version

When the stored baseline version is older than the current app version:

1. Load curated What's New content for versions newer than the stored baseline and up to the current app version.
2. Show a dialog only if there are user-facing items worth showing.
3. Mark the current version as seen after the dialog is dismissed.

For a one-version update, the dialog should usually show the curated changes for the current release.

### Update After Skipping Versions

When the user skipped multiple versions:

1. Combine eligible highlights from all versions after the stored baseline.
2. Prioritize the most important changes.
3. Deduplicate related changes.
4. Show only a concise highlight summary, not the full list.

Recommended cap: 3 to 5 items total.

### No Useful Content

If there are no user-facing highlights between the stored baseline and the current version:

1. Do not show the dialog.
2. Mark the current version as seen so the user is not checked repeatedly for the same version.

## Content Guidelines

What's New items should be written for users, not developers.

### Include

- New user-visible features.
- Meaningful improvements to existing flows.
- Important reliability fixes that affect user trust or data safety.
- Clear collaboration, sharing, account, list, item, sync, or usability improvements.

### Exclude

- Dependency upgrades.
- Logging, crash reporting, analytics, or build-system changes.
- Refactors, architecture changes, migrations, or Firebase implementation details.
- Minor copy changes unless they materially improve clarity.
- Obvious statements like "bug fixes and improvements".
- Fixes for edge cases that most users would not understand or notice.

### Writing Style

- Use plain language.
- Focus on user benefit.
- Keep titles short.
- Keep descriptions to one sentence.
- Prefer "Sharing lists is more predictable" over "Refined permission map handling".

## Content Model Requirements

Replace the single latest-only model with versioned curated content.

Recommended asset:

`assets/whats_new/releases.json`

Example structure:

```json
{
  "releases": [
    {
      "version": "4.13.54",
      "title": "Baskit 4.13.54",
      "items": [
        {
          "type": "improvement",
          "importance": "high",
          "userFacing": true,
          "group": "sharing",
          "title": "Cleaner sharing and members",
          "description": "Sharing lists and managing members is more predictable.",
          "icon": "group"
        }
      ]
    }
  ]
}
```

### Item Fields

- `type`: `feature`, `improvement`, or `bugfix`.
- `importance`: `high`, `medium`, or `low`.
- `userFacing`: boolean. Only `true` items are eligible for display.
- `group`: optional stable grouping key used to deduplicate related changes across skipped versions.
- `title`: user-facing item title.
- `description`: user-facing benefit statement.
- `icon`: visual icon key.

## Highlight Selection Rules

Given `lastSeenVersion` and `currentVersion`:

1. Select releases where `lastSeenVersion < release.version <= currentVersion`.
2. Flatten release items.
3. Keep only items where `userFacing == true`.
4. Prefer `high` importance, then `medium`, then `low`.
5. Deduplicate by `group` when present, keeping the newest/highest-importance item.
6. If only one release is selected, show up to 5 curated items for that release.
7. If multiple releases are selected, show up to 3 to 5 total highlights across all selected releases.
8. If no items remain, do not show the dialog.

## Dialog Requirements

- Title for one-version update: `What's New in Baskit`.
- Title for skipped-version summary: `Highlights since your last update`.
- Include the current app version as secondary text.
- Keep the dialog compact and scannable.
- Do not show technical details or hidden release metadata.
- Button text: `Got it`.

## State Requirements

Use local persistent storage to track the user's What's New baseline.

Required behavior:

- On first launch, save current version and do not show.
- On update, compare saved version to current version.
- After showing, save current version.
- If content is missing or has no eligible user-facing highlights, save current version to prevent repeat checks.
- If loading fails unexpectedly, fail silently and do not block app startup.

## Migration Requirements

Existing installs may already have `last_seen_version` from the current implementation.

- Continue honoring the existing stored version when available.
- If no stored version exists, treat the current version as the baseline and do not show.
- Remove reliance on the `first_launch` flag if version baseline tracking makes it redundant, or keep it only for backward compatibility.

## Acceptance Criteria

- First install never shows What's New.
- Same-version launches never show What's New.
- Updating from the immediately previous version shows curated current-release changes when available.
- Updating after skipped versions shows a concise highlight summary, capped and deduplicated.
- Non-user-facing items are never shown.
- Technical details are not visible in the dialog.
- If there are no eligible highlights, no dialog is shown and the current version is marked seen.
- Unit tests cover first install, same version, one-version update, skipped-version update, no-content update, and version comparison.
- Model tests cover release parsing, filtering, prioritization, and deduplication.

## Implementation Tasks

1. Add a versioned What's New content model that can parse `assets/whats_new/releases.json`.
2. Add selection logic for `lastSeenVersion` → `currentVersion` ranges.
3. Update `VersionService` to use baseline version tracking for first install and updates.
4. Update `WhatsNewDialog` to accept computed highlight content instead of only `latest.json`.
5. Curate current release content to remove technical/non-user-facing descriptions.
6. Add/adjust tests for version tracking and highlight selection.
7. Update `prds/06-ui-and-assets.md` after implementation to reference this versioned highlight behavior.
