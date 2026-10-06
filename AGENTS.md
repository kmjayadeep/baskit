# Agent guide

Baskit is a Flutter app in `app/`. Start with `README.md`; use `prds/00-index.md` to find feature requirements. Check the current code and tests when docs disagree.

## Workflow

- Check `git status --short` first; do not overwrite unrelated work. Trace the relevant code and tests before editing.
- Keep changes focused and test behavior changes. From `app/`, use Flutter `3.41.6` (pinned in `.tool-versions`):
  ```bash
  flutter pub get   # if dependencies changed or are missing
  flutter analyze
  flutter test
  ```
  Run both checks before committing app changes; for a quick iteration use `flutter test test/<path>_test.dart`. Format only changed Dart files. For docs-only changes, run `git diff --check`.
- Report checks run and any unverified device, Firebase, or Play flows. Do not claim a check passed if you could not run it.

## Boundaries

- Preserve guest-first local Hive behavior and signed-in Firestore sync/sharing. Put side effects in services or Riverpod Notifier view models, not widgets; use repositories/`StorageService` for data access.
- Do not edit generated `app/lib/**.g.dart` by hand. Do not commit secrets, signing keys, machine-specific SDK paths, or generated coverage/build output.
- `pages/` includes public privacy and account-deletion pages; do not treat them as disposable internal docs.
- `automation/autonomous-agent/` is a separate Node project; follow its README and run its checks when changing it.
- Do not release, tag, push, deploy, or change release automation incidentally. For requested releases, follow `.agents/skills/baskit-release/SKILL.md`.

## Keep this guide current

When a change alters setup commands, project layout, validation, or agent safety boundaries, update `AGENTS.md` in the same change. Keep it short and actionable; link to `README.md`, relevant `prds/`, or the automation README for detail rather than duplicating them. Update those docs when their subject changes, and remove instructions that no longer match the repository.
