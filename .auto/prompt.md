# Autoresearch: Flutter readability

## Objective
Improve the structure and code readability of the Flutter/Dart code in `app/lib` so it is easier for a human to understand without adding verbose comments. Prefer clearer names, smaller widgets/functions, extraction of cohesive helpers, removal of duplication, and simpler control flow. Preserve behavior.

## Metrics
- **Primary**: readability_cost (points, lower is better) — static proxy for hard-to-read code based on large files, long lines, comments density, TODOs, and formatting/analyzer issues.
- **Secondary**: dart_files, total_lines, avg_file_lines, large_files, long_lines, comment_lines, flutter_analyze_exit, flutter_test_exit.

The metric is a proxy; use judgment. Keep improvements only when the code is genuinely easier to understand and tests pass.

## How to Run
`./.auto/measure.sh` — outputs `METRIC name=number` lines.

## Files in Scope
- `app/lib/**/*.dart` except generated `*.g.dart`: production Flutter/Dart files may be refactored for readability.
- `app/test/**/*.dart`: tests may be updated or added only when necessary to preserve/refine behavior.
- `.auto/*`: autoresearch session files.

## Off Limits
- Generated files: `app/lib/**/*.g.dart`.
- Platform/build artifacts and dependency lockfiles unless explicitly needed.
- Do not add new dependencies for readability-only changes.

## Constraints
- Keep tests passing at all times: `flutter test` must pass before keeping a change.
- `flutter analyze` should pass before keeping a change.
- Avoid verbose comments; prefer self-documenting code and small focused helpers.
- Preserve UI behavior, data models, persistence, Firebase flows, and guest-first routing.

## What's Been Tried
- Session initialized. Baseline will establish static readability proxy and test/analyze status.
