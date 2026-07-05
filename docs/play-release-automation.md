# Play Release Automation

Baskit keeps production rollout manual while automating the repeatable Play release work: building signed Android artifacts, exporting release notes, archiving validation logs, and optionally uploading an `.aab` to a Play track.

## Workflow

Use `.github/workflows/play-release.yml` (`Play Release`) after a release tag has been created.

1. Add curated user-facing highlights for the target version in `app/assets/whats_new/releases.json`.
2. Create the release commit and tag with `./scripts/release.sh patch|minor|major`.
3. Wait for the normal tag release workflow to finish.
4. Run **Actions → Play Release** with:
   - `release_ref`: the release tag, for example `v4.13.54`. The workflow rejects branches, SHAs, prerelease refs, tags that are not reachable from `main`, and tags whose `vX.Y.Z` value does not match `app/pubspec.yaml` before signing artifacts.
   - `play_track`: `internal`, `closed`, `open`, or `production`.
   - `non_production_status`: `completed` or `draft` for non-production tracks.
5. Download and retain the `play-release-<ref>-<track>` workflow artifact bundle.

The archive contains:

- `app-release.aab`
- `apk/*-release.apk`
- `flutter-debug-symbols.zip`, `native-debug-symbols.zip` when produced, plus the unpacked `symbols/` directory
- Play-formatted release notes under `release-notes/play/en-US/default.txt`
- Markdown release notes under `release-notes/whats-new.md`
- validation/build logs under `logs/`
- `build-metadata.txt` and `manifest.txt`

## Production approval gate

Production uploads run in the GitHub environment named `google-play-production`. Configure that environment in repository settings with required reviewers before using the workflow for production.

Even after approval, the workflow uploads production releases with Play status `draft`. A human must still review the Play Console draft, confirm the release notes, upload or confirm the native debug symbols from the artifact bundle, choose the staged rollout settings, and start rollout manually.

## Required secrets

Do not commit secret material. Configure these GitHub Actions secrets instead:

- `RELEASE_KEYSTORE_BASE64`: base64-encoded Android upload keystore.
- `KEYSTORE_PASSWORD`: keystore password.
- `KEY_PASSWORD`: key password.
- `KEY_ALIAS`: upload key alias.
- `PLAY_SERVICE_ACCOUNT_JSON`: Google Play service account JSON with permission to edit releases for `com.cboxlab.baskit`.

## Local release-note validation

The Play workflow exports release notes with:

```bash
scripts/export_play_release_notes.py
```

By default it reads `app/assets/whats_new/releases.json`, selects the entry matching the semantic version in `app/pubspec.yaml`, keeps `userFacing=true` items, writes Play notes to `release-artifacts/release-notes/play/en-US/default.txt`, writes Markdown notes to `release-artifacts/release-notes/whats-new.md`, and fails if the Play notes exceed Google Play's 500-character locale limit.
