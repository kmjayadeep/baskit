---
name: baskit-release
description: Use when creating a Baskit internal release candidate or snapshot build, including preparing curated release notes, committing pending changes, running validation, bumping app version with scripts/release.sh, pushing main and tags, checking GitHub Actions release builds, and updating the Play promotion baseline after manual promotion.
---

# Baskit Release

Use this skill when the user asks to release, publish, tag, bump the version, create a Play-ready build, create an internal release candidate, build a disposable snapshot artifact, or update the post-promotion baseline.

## Release Flow

1. Inspect state from the repo root.

```bash
git status --short --branch
git diff
grep -n "^version:" app/pubspec.yaml
sed -n '1,80p' app/lib/constants/app_version.dart
sed -n '1,180p' app/assets/whats_new/releases.json
sed -n '1,120p' docs/release-promotion-state.json
```

2. Validate code before release.

```bash
cd app
flutter analyze
flutter test
```

For a narrow fix, a focused `flutter test <path>` is acceptable before committing, but run `flutter analyze` at minimum. Surface any skipped full-suite coverage in the final answer.

3. Decide whether this is a snapshot or an internal release candidate.

- Use CI snapshot artifacts for disposable maintainer smoke testing. Do not run `scripts/release.sh` for snapshots.
- Use `scripts/release.sh` only for internal release candidates that may be promoted beyond Play internal testing.
- Release candidates require curated user-facing highlights for the next semantic version in `app/assets/whats_new/releases.json`; do not proceed with note-less candidate releases.
- For `minor` or `major`, compute the next semantic version accordingly.
- Each release item should include `type`, `importance`, `userFacing`, optional `group`, `title`, `description`, and `icon`.
- Write for users, not developers; exclude dependency updates, logging/analytics/build-system work, refactors, and implementation details.
- `latest.json` is legacy/reference content only and is not the source of truth for the in-app What's New dialog or Play notes.
- Play notes are exported cumulatively from `docs/release-promotion-state.json` through the candidate version, filtering `userFacing=true` and deduplicating by `group`.

4. Commit app changes before running the release script.

For release candidates, the release script refuses a dirty working tree. Stage only intentional files and use a conventional signed commit:

```bash
git add <intentional files>
git commit -sm "fix(scope): short description"
```

Do not commit generated build outputs or hand-edit `app/lib/**.g.dart`.

5. Run the release candidate script from the repo root.

```bash
./scripts/release.sh patch
```

Use `patch` unless the user explicitly asks for `minor` or `major`. The script:

- requires `app/assets/whats_new/releases.json` to contain a candidate release entry with at least one `userFacing=true` item
- updates `app/pubspec.yaml` from `X.Y.Z+BUILD` to the new version and build number
- updates `app/lib/constants/app_version.dart`
- commits `chore: bump version to X.Y.Z+BUILD`
- creates annotated tag `vX.Y.Z` for the internal release candidate
- pushes `main` and the tag to origin

If the script reports a missing `releases.json` entry or no `userFacing: true` items, stop and update curated highlights. Use snapshot artifacts instead when there are no user-facing release notes.

6. Verify remote release automation.

```bash
git status --short --branch
git log -2 --oneline
git tag --points-at HEAD
gh run list --limit 5 --json databaseId,headBranch,headSha,status,conclusion,name,event,createdAt,url
```

Find the tag-triggered run where `headBranch` is `vX.Y.Z`, then watch it. The workflow should create signed artifacts, mark the GitHub Release as a prerelease, export cumulative Play notes, and upload the AAB to Play internal when credentials are configured:

```bash
gh run watch <run-id> --exit-status
```

If it fails, fetch jobs/logs and report the failing step:

```bash
gh run view <run-id> --json jobs,url,status,conclusion
gh run view <run-id> --log-failed
```

7. After manual Play promotion, update the baseline.

Only after confirming the selected candidate is promoted to closed/open/production in Play Console:

```bash
./scripts/mark_promoted.sh X.Y.Z --track closed|open|production
git add docs/release-promotion-state.json
git commit -sm "chore: update release promotion baseline"
git push
```

Open a small PR for the baseline update and merge it after the promotion is live.

## Safety

- Never force push for a release.
- Never skip hooks or checks.
- Do not run `scripts/release.sh` with uncommitted changes.
- Do not use `scripts/release.sh` for disposable snapshot builds.
- Do not manually create release tags unless the script cannot be used and the user approves the alternate path.
- Do not mark `docs/release-promotion-state.json` ahead of the version actually promoted in Play Console.
- If GitHub Actions is still running, give the run URL and current state rather than claiming the release artifacts are ready.
