# UI & Assets

## Overview
This guide covers UI theming, branding, and asset management for Baskit.

## Theme Configuration
Theme setup lives in `app/lib/main.dart` using Material 3:
```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  ),
)
```

Notes:
- The app is currently pinned to `ThemeMode.light`
- Card and button styles are customized in `main.dart`

## List Colors
The list creation UI uses a fixed palette in:
`app/lib/screens/lists/view_models/list_form_view_model.dart`

```dart
static const List<Color> availableColors = [
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.red,
  Colors.teal,
  Colors.pink,
  Colors.indigo,
];
```

## App Icons
- Root icon for docs/branding: `assets/icon.png`
- Launcher icons are generated from `assets/icon/icon.png` via `flutter_launcher_icons`
- Web icons live under `app/web/icons/`

To regenerate launcher icons:
```bash
cd app
flutter pub run flutter_launcher_icons
```

## Google Sign-In Branding
The sign-in button is implemented in:
`app/lib/widgets/auth/google_sign_in_widget.dart`

Current behavior:
- Uses Material icons for the sign-in button
- No Google logo asset is bundled

If you need official branding, add an asset and update the widget:
1. Download the "G" icon from
   https://developers.google.com/identity/branding-guidelines
2. Place it at `app/assets/google_logo.png`
3. Update the widget to use `Image.asset`
4. Declare the asset in `app/pubspec.yaml`

## Asset Conventions
Asset folders (current):
```
assets/
  icon.png
  feature.jpeg
  whats_new/
```

Use the `assets/` root for bundled images. Add new asset groups alongside `whats_new/` as needed.

## Accessibility
- Provide semantic labels on interactive widgets
- Maintain touch target sizes of ~44x44 points
- Ensure contrast for text on colored cards
