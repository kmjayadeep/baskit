<div align="center">
  <img src="assets/icon.png" alt="Baskit app icon" width="120" height="120">

  # Baskit 🛒

  **Shopping lists that work instantly, then sync when you need them.**

  <img src="assets/feature.jpeg" alt="Baskit shopping list features" width="600">
</div>

## What is Baskit?

Baskit is a collaborative shopping list app for everyday grocery runs, shared households, and quick errands. Open the app and start adding items right away—no account required.

When you want to share a list or keep it in sync across devices, sign in with Google and Baskit moves your local lists into the cloud.

## Why people use it

- **Start as a guest:** create and manage lists immediately without signing up.
- **Works offline:** guest lists stay local on your device and remain available without a connection.
- **Share when ready:** sign in to invite others, manage members, and collaborate on the same list.
- **Sync across devices:** authenticated users can keep lists updated through Firebase/Firestore.
- **Simple list management:** add items, check them off, organize shared lists, and keep shopping coordinated.

## Guest-first flow

1. **Open Baskit** and use it locally as a guest.
2. **Build your lists** with no account, no setup, and no cloud dependency.
3. **Sign in only when needed** for sharing or cross-device sync.
4. **Keep your data:** local lists migrate to the signed-in account automatically.

## For contributors

Baskit is a Flutter app with Riverpod state management, Hive local storage, and Firebase services for authentication, sharing, and sync. Detailed product and architecture notes live in [prds/](prds/); contributor workflow guidance lives in [AGENTS.md](AGENTS.md).

### Prerequisites

- Flutter SDK `3.41.6` (see [.tool-versions](.tool-versions))
- Dart version bundled with that Flutter SDK
- Android Studio and/or Xcode for mobile builds
- A Firebase project when working on authenticated, sharing, or sync flows

### Local setup

```bash
git clone <repository-url>
cd baskit/app
flutter pub get
flutter run
```

For Firebase-backed features, add the platform config files for your Firebase project before running those flows:

- Android: `app/android/app/google-services.json`
- iOS/macOS: `app/ios/Runner/GoogleService-Info.plist` and/or the matching macOS config if needed

### Common commands

Run these from `app/`:

```bash
flutter analyze
flutter test
flutter run

flutter build apk --release
flutter build ios --release
flutter build web --release
```

### Helpful docs

- [Product requirements and architecture notes](prds/)
- [Development and operations guide](prds/07-development.md)
- [Agent/contributor guide](AGENTS.md)
- [Play release automation](docs/play-release-automation.md)

## Security and privacy

Guest data is stored locally on the device. Cloud sync and list sharing require sign-in and use Firebase Authentication plus Firestore security rules to isolate user and shared-list data.

## License

Baskit is licensed under the [MIT License](LICENSE).

---

Made with ❤️ for calmer shopping trips.
