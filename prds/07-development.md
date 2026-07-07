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

## Native Google Sign-In Setup
- Android native Google Sign-In uses `app/android/app/google-services.json`; it must include:
  - An Android OAuth client for `com.cboxlab.baskit` with every debug/release/play signing SHA-1 fingerprint used to build the app
  - A web OAuth client (`oauth_client` with `client_type: 3`) so the Android plugin can derive the server client ID
- If Android sign-in fails after choosing an account, verify package name, SHA fingerprints, and the web OAuth client in Firebase/Google Cloud Console, then re-download `google-services.json`
- iOS native Google Sign-In requires the Firebase iOS client ID (`GIDClientID`) and reversed client ID URL scheme in `ios/Runner/Info.plist` before iOS release validation
