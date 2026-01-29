# Baskit PRD - Development & Operations

## Build & Run
- All Flutter commands run from `app/`
- `flutter pub get` is required after dependency changes

## Lint & Format
- Use `flutter analyze`
- Use `dart format .`

## Tests
- `flutter test` runs the full test suite
- Tests are organized under `app/test/`

## Code Generation
- Hive adapters are generated via build_runner
- Generated files live under `app/lib/**.g.dart` and are not manually edited

## Firebase Setup
- Firebase is optional; without it the app must run in local-only mode
- When enabled, ensure platform config files and `firebase_options.dart` exist
