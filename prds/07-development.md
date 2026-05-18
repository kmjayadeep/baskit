# Baskit PRD - Development & Operations

## Toolchain
- Local and CI Flutter version is pinned to `3.41.6`
- Repo pin file: `.tool-versions` (`flutter 3.41.6`)
- All Flutter commands run from `app/`
- Validate your SDK before running checks: `flutter --version`

## Build & Run
- `flutter pub get` is required after dependency changes

## Lint & Format
- Use `flutter analyze`
- Use `dart format .`

## Tests
- `flutter test` runs the full test suite
- Tests are organized under `app/test/`

## Code Generation
- Hive adapters are checked in under `app/lib/models/*.g.dart`; regenerate them only when the model layer changes and the generator toolchain is available
- Generated files live under `app/lib/**.g.dart` and are not manually edited

## Firebase Setup
- Firebase is optional; without it the app must run in local-only mode
- When enabled, ensure platform config files and `firebase_options.dart` exist
