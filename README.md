<div align="center">
  <img src="assets/icon.png" alt="Baskit App Icon" width="120" height="120">

  # Baskit 🛒

  **Collaborative shopping lists that work instantly as a guest and grow into real-time shared lists when you sign in.**

  <img src="assets/feature.jpeg" alt="Baskit App Features" width="600">
</div>

## Why Baskit?

Baskit is a Flutter app for creating, sharing, and managing grocery lists with less friction.

- Start immediately in guest mode; no account required.
- Keep guest data local with Hive and full offline access.
- Sign in with Google when you want cloud sync or list sharing.
- Collaborate in real time with shared lists, members, and permissions.
- Use the same codebase across Android, iOS, web, and desktop targets.

## Quick setup

### Prerequisites

- Flutter SDK `3.41.6` (matches CI and `.tool-versions`)
- Dart SDK supplied by Flutter
- Android Studio and/or Xcode for mobile builds
- Optional: a Firebase project for auth, Firestore, and sharing flows

### Run locally

```bash
git clone https://github.com/kmjayadeep/baskit.git
cd baskit/app
flutter pub get
flutter run
```

Firebase config files are optional for local-only development. Add platform config files such as `google-services.json`, `GoogleService-Info.plist`, and generated Firebase options when working on authenticated cloud features.

## Development commands

Run Flutter commands from `app/`:

```bash
flutter --version      # confirm Flutter 3.41.6
flutter pub get        # install dependencies
flutter analyze        # static analysis
flutter test           # unit and widget tests
flutter run            # launch the app
```

Build examples:

```bash
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

## Where to learn more

- [PRD index](prds/00-index.md) - recommended reading order for product and architecture docs.
- [Overview](prds/01-overview.md) - product scope and core user flows.
- [Authentication](prds/02-authentication.md) - guest mode, Google sign-in, and account conversion.
- [Storage and sync](prds/03-storage-and-sync.md) - local Hive, Firestore, migration, and sharing behavior.
- [State management](prds/05-state-management.md) - Riverpod provider relationships.
- [Development and operations](prds/07-development.md) - setup, validation, code generation, and Firebase notes.
- [Play release automation](docs/play-release-automation.md) - Android release upload flow.

## Security and privacy

- Guest lists stay local unless the user signs in and migrates data.
- Authenticated sharing uses Firebase Auth, Firestore, and server-side security rules.
- Access to shared lists is controlled by membership and permissions.

## License

This project is licensed under the [MIT License](LICENSE).

---

Made with ❤️ for better shopping experiences.
