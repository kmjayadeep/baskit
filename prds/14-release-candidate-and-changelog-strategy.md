# Release Candidate and Changelog Strategy

> **Status:** Proposed | **Date:** 2026-07-08

## Problem

Baskit currently uses the tag release workflow for frequent builds from `main`/`master` that are useful for maintainer testing and Play internal testing. The same flow also creates GitHub Releases, exports Google Play release notes, and requires a curated entry in `app/assets/whats_new/releases.json` for each semantic version.

This creates two related problems:

1. **Internal test builds are treated like user-facing releases.** Every tested build can become the latest GitHub Release and the latest Play internal release, even when it is only a checkpoint for the maintainer.
2. **Closed-testing users only see the latest promoted release notes.** If multiple internal builds happened since the previous closed-test promotion, the Play Console promotion can expose only the notes attached to the single build being promoted. Earlier user-facing changes can be lost unless they are manually repeated.

The release process should support frequent downloadable/testable builds without diluting the changelog that closed-testing or production users see.

## Current State

### Existing release automation

- `.github/workflows/build-apk.yml` runs validation on pushes and pull requests.
- Pushes to `main`/`master` build a fast debug APK artifact named `app-fast-debug-apk` for short-lived device testing.
- Tags matching `v*` trigger signed release APK/AAB builds, artifact upload, GitHub Release creation, release-note export, and Play internal upload.
- `scripts/release.sh` increments the semantic version and Google Play version code, validates that the next semantic version has a curated What's New entry, commits the bump, creates a `vX.Y.Z` tag, and pushes the tag.
- `scripts/export_play_release_notes.py` exports only the release-note entry matching the semantic version in `app/pubspec.yaml`.
- `docs/play-release-automation.md` documents that tagged releases upload the same AAB to the Play internal track and that promotion to closed/open/production remains manual.

### Existing What's New model

- `prds/11-whats-new-release-highlights.md` defines a versioned, curated in-app What's New model.
- `app/assets/whats_new/releases.json` stores release entries per semantic version.
- The app can summarize multiple skipped versions for in-app users, but Play release notes are exported for only one version at a time.

## Goals

- Allow frequent builds from `main`/`master` for maintainer download and smoke testing without creating user-facing GitHub Releases.
- Keep Play internal testing available for actual release candidates.
- Make closed-testing promotion notes cumulative since the last closed/open/production promotion.
- Preserve the app's versioned What's New behavior and curated, user-facing writing style.
- Make it obvious which build is a disposable snapshot, an internal release candidate, or a promoted user-visible release.
- Reduce manual copy/paste of release notes at promotion time.

## Non-Goals

- Do not remove the ability to download artifacts from CI.
- Do not automatically promote builds from internal to closed/open/production.
- Do not expose engineering-only changes to end users.
- Do not introduce a remote CMS for release notes.
- Do not rely on generated commit logs as the only source of user-facing notes.

## Release Taxonomy

| Type | Trigger | Artifact | GitHub Release | Play track | Notes policy |
| --- | --- | --- | --- | --- | --- |
| Snapshot build | push to `main`/`master` or manual workflow | Debug APK, optionally signed APK when secrets are available | No | No by default | No user-facing notes required |
| Internal release candidate | manual release command/tag | Signed APK/AAB | Yes, preferably pre-release until promoted | Internal | Curated notes for the candidate plus cumulative promotion notes |
| Closed-test promotion | manual Play Console promotion of selected candidate | Same AAB/version code | Existing GitHub Release can be marked non-prerelease | Closed | Cumulative notes since last closed/open/production promotion |
| Production promotion | manual Play Console promotion | Same AAB/version code | Existing GitHub Release remains the release record | Production | Same notes used for closed promotion unless explicitly revised |

## Proposed Behavior

### Snapshot builds

Pushes to `main`/`master` should continue to create a downloadable artifact for fast maintainer testing, but they should not:

- bump semantic version,
- create Git tags,
- create GitHub Releases,
- upload to Play,
- require `releases.json` entries, or
- affect the user-visible changelog baseline.

If a signed installable artifact is needed for local smoke testing, add a separate snapshot job that builds a signed APK only when signing secrets are available. This job should still publish a workflow artifact, not a GitHub Release.

### Internal release candidates

A release candidate should be created only when the maintainer wants a build that may be promoted beyond internal testing.

Candidate creation should:

1. require a curated release entry in `app/assets/whats_new/releases.json`,
2. bump `app/pubspec.yaml` and `app/lib/constants/app_version.dart`,
3. tag the candidate,
4. build signed APK/AAB artifacts,
5. create or update a GitHub Release,
6. upload the AAB and release notes to the Play internal track, and
7. clearly identify the candidate as internal until it is promoted.

### Cumulative Play release notes

For Play uploads that may later be promoted to closed/open/production, notes should include all user-facing highlights since the last promoted baseline, not only the current semantic version.

Recommended source of truth:

- Keep `app/assets/whats_new/releases.json` as the canonical curated item catalog.
- Add a tracked promotion state file, for example `docs/release-promotion-state.json`, containing the latest version promoted to a user-visible track:

```json
{
  "lastUserVisibleVersion": "4.13.75",
  "track": "closed",
  "updatedAt": "2026-07-08"
}
```

The Play notes exporter can then select releases where:

```text
lastUserVisibleVersion < release.version <= candidateVersion
```

It should filter to `userFacing=true`, deduplicate by `group`, prioritize high-impact changes, and render a compact note that fits the Google Play 500-character locale limit.

### Promotion baseline updates

After a candidate is promoted to closed/open/production, the repository should record that baseline so the next candidate can aggregate from the correct point.

This can be manual at first:

1. promote the selected build in Play Console,
2. update `docs/release-promotion-state.json`,
3. open a small PR, and
4. merge after confirming the Play promotion.

A future improvement can add `scripts/mark_promoted.sh VERSION --track closed|open|production` to validate the version exists in `releases.json` and update the state file consistently.

## UX and Content Requirements

- Snapshot builds should not require user-facing notes.
- Candidate notes should be written for users, not developers.
- Promotion notes should summarize the cumulative user benefit since the last user-visible promotion.
- If cumulative notes exceed 500 characters, the exporter should fail with an actionable message and suggest reducing low-importance items.
- Internal-only details, dependency upgrades, CI work, logging, and implementation changes must stay out of Play notes unless there is a clear user benefit.

## Implementation Plan

### Phase 1: Documentation and policy

1. Document the release taxonomy in the PRDs and link it from release automation docs.
2. Update contributor/release guidance to say: use workflow artifacts for frequent maintainer testing; use `scripts/release.sh` only for candidate builds that may be promoted.
3. Rename language in docs from "release every tested build" to "snapshot vs release candidate" where appropriate.

### Phase 2: Promotion state and cumulative notes exporter

1. Add `docs/release-promotion-state.json` with the current last closed/open/production baseline.
2. Extend `scripts/export_play_release_notes.py` with optional arguments:
   - `--since-version VERSION`,
   - `--promotion-state docs/release-promotion-state.json`,
   - `--max-items N`, and
   - `--mode single|cumulative`.
3. Implement cumulative selection over `releases.json` using the same high-level rules as `prds/11-whats-new-release-highlights.md`.
4. Preserve the current single-version export mode for GitHub Release artifacts if desired.
5. Add unit tests for single-release export, cumulative export, deduplication, empty ranges, missing baseline, and 500-character failures.

### Phase 3: Workflow separation

1. Keep push-to-`main` snapshot artifacts as CI artifacts only.
2. Make tag-triggered Play internal upload use cumulative notes when `docs/release-promotion-state.json` exists.
3. Optionally mark GitHub Releases created from internal candidates as pre-releases until promotion.
4. Add a manual workflow input for building a snapshot artifact from any branch without a release tag.

### Phase 4: Promotion helper

1. Add `scripts/mark_promoted.sh VERSION --track closed|open|production`.
2. Validate that `VERSION` exists in `app/assets/whats_new/releases.json` or explicitly allow note-less technical promotions.
3. Update `docs/release-promotion-state.json` and print the Play Console promotion checklist.
4. Document the post-promotion PR step.

## Acceptance Criteria

- Pushes to `main`/`master` still provide a downloadable maintainer testing artifact without creating a GitHub Release.
- Release candidate creation still produces signed APK/AAB artifacts and uploads to Play internal when secrets are configured.
- Play notes for a candidate can be generated cumulatively from the last user-visible promotion through the candidate version.
- Cumulative notes include only `userFacing=true` items and deduplicate related changes.
- Exported Play notes stay within the 500-character limit or fail before upload.
- The release docs clearly tell maintainers when to use snapshot artifacts versus release candidates.
- The promotion baseline can be updated after a manual closed/open/production promotion.

## Risks and Mitigations

- **Risk:** A maintainer forgets to update the promotion baseline after Play promotion.  
  **Mitigation:** Add a checklist item to release docs and later automate with `scripts/mark_promoted.sh`.

- **Risk:** Cumulative notes exceed Play's 500-character limit.  
  **Mitigation:** Prioritize by importance, cap item count, and fail the exporter with a clear message.

- **Risk:** High version codes from experimental Play uploads complicate future promotion.  
  **Mitigation:** Prefer CI artifacts for disposable testing and reserve Play internal uploads for candidates that may be promoted.

- **Risk:** GitHub Releases still look user-visible even before Play promotion.  
  **Mitigation:** Mark internal candidates as pre-releases or label them clearly until promoted.
