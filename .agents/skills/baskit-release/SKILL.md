---
name: baskit-release
description: Use when releasing the Baskit Flutter app, including preparing release notes, committing pending changes, running validation, bumping app version with scripts/release.sh, pushing main and tags, and checking GitHub Actions release builds.
---

# Baskit Release

Use this skill when the user asks to release, publish, tag, bump the version, create a Play-ready build, or run the Baskit release flow.

## Release Flow

1. Inspect state from the repo root.

```bash
git status --short --branch
git diff
grep -n "^version:" app/pubspec.yaml
sed -n '1,80p' app/lib/constants/app_version.dart
sed -n '1,180p' app/assets/whats_new/releases.json
sed -n '1,120p' app/assets/whats_new/latest.json  # legacy/reference only
```

2. Validate code before release.

```bash
cd app
flutter analyze
flutter test
```

For a narrow fix, a focused `flutter test <path>` is acceptable before committing, but run `flutter analyze` at minimum. Surface any skipped full-suite coverage in the final answer.

3. Prepare `app/assets/whats_new/releases.json`.

- `scripts/release.sh` validates the versioned release catalog before bumping for `patch`, `minor`, and `major` releases.
- For `minor` or `major`, compute the next semantic version accordingly.
- Add one curated release entry for the next version when the release has useful user-facing highlights.
- Each item should include `type`, `importance`, `userFacing`, optional `group`, `title`, `description`, and `icon`.
- Write for users, not developers; exclude dependency updates, logging/analytics/build-system work, refactors, and implementation details.
- If there are no useful user-facing highlights, it is acceptable to omit the release entry or include no `userFacing: true` items; the app will mark the version seen without showing a dialog. The script will warn and ask for confirmation.
- `latest.json` is legacy/reference content only and is not the source of truth for the in-app What's New dialog.

4. Commit app changes before running the release script.

The release script refuses a dirty working tree. Stage only intentional files and use a conventional signed commit:

```bash
git add <intentional files>
git commit -sm "fix(scope): short description"
```

Do not commit generated build outputs or hand-edit `app/lib/**.g.dart`.

5. Run the release script from the repo root.

```bash
./scripts/release.sh patch
```

Use `patch` unless the user explicitly asks for `minor` or `major`. The script:

- updates `app/pubspec.yaml` from `X.Y.Z+BUILD` to the new version and build number
- updates `app/lib/constants/app_version.dart`
- commits `chore: bump version to X.Y.Z+BUILD`
- creates annotated tag `vX.Y.Z`
- pushes `main` and the tag to origin

If the script reports a missing `releases.json` entry or no `userFacing: true` items, stop and update curated highlights unless the release genuinely has no useful user-facing content or the user explicitly says to continue.

6. Verify remote release automation.

```bash
git status --short --branch
git log -2 --oneline
git tag --points-at HEAD
gh run list --limit 5 --json databaseId,headBranch,headSha,status,conclusion,name,event,createdAt,url
```

Find the tag-triggered run where `headBranch` is `vX.Y.Z`, then watch it:

```bash
gh run watch <run-id> --exit-status
```

If it fails, fetch jobs/logs and report the failing step:

```bash
gh run view <run-id> --json jobs,url,status,conclusion
gh run view <run-id> --log-failed
```

## Safety

- Never force push for a release.
- Never skip hooks or checks.
- Do not run `scripts/release.sh` with uncommitted changes.
- Do not manually create release tags unless the script cannot be used and the user approves the alternate path.
- If GitHub Actions is still running, give the run URL and current state rather than claiming the release artifacts are ready.
