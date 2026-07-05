<div align="center">
  <img src="assets/icon.png" alt="Baskit app icon" width="120" height="120">

  # Baskit 🛒

  **Shopping lists that work instantly as a guest, then sync and collaborate when you need them.**

  <img src="assets/baskit-cover.png" alt="Baskit shopping list app cover" width="700">
</div>

## What is Baskit?

Baskit is a collaborative shopping list app for everyday grocery runs, shared households, and quick errands. Open the app and start adding items right away—no account required.

When you want to share a list or keep it in sync across devices, sign in with Google and Baskit moves your local lists into the cloud.

## Highlights

- **Start as a guest:** create and manage lists immediately without signing up.
- **Works offline:** guest lists stay local on your device and remain available without a connection.
- **Share when ready:** sign in to invite others, manage members, and collaborate on the same list.
- **Sync across devices:** authenticated users can keep lists updated through Firebase/Firestore.
- **Simple list management:** add items, check them off, organize shared lists, and keep shopping coordinated.
- **Modern Flutter UI:** Material 3 interface with light/dark themes across mobile, web, and desktop targets.

## Guest-first flow

1. **Open Baskit** and use it locally as a guest.
2. **Build your lists** with no account, no setup, and no cloud dependency.
3. **Sign in only when needed** for sharing or cross-device sync.
4. **Keep your data:** local lists migrate to the signed-in account automatically.

## For contributors

Baskit is a Flutter app with Riverpod state management, Hive local storage, and Firebase services for authentication, sharing, and sync. Detailed product and architecture notes live in [prds/](prds/); contributor workflow guidance lives in [AGENTS.md](AGENTS.md).

### Prerequisites

- Flutter SDK `3.41.6` (matches CI and [.tool-versions](.tool-versions))
- Dart SDK bundled with that Flutter version
- Android Studio and/or Xcode for mobile builds
- Optional Firebase project for auth, Firestore, sharing, and sync flows

### Local setup

```bash
git clone https://github.com/kmjayadeep/baskit.git
cd baskit/app
flutter pub get
flutter run
```

The app can run in local-first guest mode without Firebase. For Firebase-backed features, add platform config files for your Firebase project before running those flows:

- Android: `app/android/app/google-services.json`
- iOS/macOS: `GoogleService-Info.plist` in the appropriate platform runner

Keep local Firebase config files out of source control unless they are intentionally public for your environment.

### Common commands

Run Flutter commands from `app/`:

```bash
flutter --version      # confirm Flutter 3.41.6
flutter pub get        # install dependencies
flutter analyze        # static analysis
flutter test           # unit and widget tests
flutter run            # launch the app

flutter build apk --release
flutter build ios --release
flutter build web --release
```

## Repository map

```text
.
├── app/                    # Flutter app source, tests, and platform projects
│   ├── lib/models/         # Shopping list models and checked-in Hive adapters
│   ├── lib/services/       # Storage, Firebase, auth, and platform services
│   ├── lib/repositories/   # Data access abstractions
│   ├── lib/providers/      # Riverpod provider definitions
│   ├── lib/view_models/    # Riverpod Notifier-based app state
│   ├── lib/screens/        # Feature screens and screen view models
│   ├── lib/widgets/        # Reusable UI components
│   ├── lib/utils/          # Routing and helpers
│   └── test/               # Unit and widget tests
├── assets/                 # README imagery and shared app assets
├── docs/                   # Operational docs such as release automation
├── prds/                   # Product, architecture, and development details
└── AGENTS.md               # Contributor and agent workflow guide
```

Generated Hive adapters live under `app/lib/**.g.dart`; do not edit them manually.

## Contributor workflow

1. Read [AGENTS.md](AGENTS.md) for repository conventions and validation expectations.
2. Pick a focused issue or change and keep the scope narrow.
3. Update docs in this README or `prds/` when behavior, architecture, or setup changes.
4. Run the relevant validation commands from `app/` before opening a PR.
5. Include screenshots or screen recordings for user-visible UI changes.

## Helpful docs

- [PRD index](prds/00-index.md) - recommended reading order for product and architecture docs.
- [Overview](prds/01-overview.md) - product scope and core user flows.
- [Authentication](prds/02-authentication.md) - guest mode, Google sign-in, and account conversion.
- [Storage and sync](prds/03-storage-and-sync.md) - local Hive, Firestore, migration, and sharing behavior.
- [State management](prds/05-state-management.md) - Riverpod provider relationships.
- [Development and operations](prds/07-development.md) - setup, validation, code generation, and Firebase notes.
- [Play release automation](docs/play-release-automation.md) - Android release upload flow.

## Security and privacy

Guest data is stored locally on the device. Cloud sync and list sharing require sign-in and use Firebase Authentication plus Firestore security rules to isolate user and shared-list data.

## License

Baskit is licensed under the [MIT License](LICENSE).

---

Made with ❤️ for calmer shopping trips.
