# UI & Assets Management

## Overview
This document covers UI customization, asset management, and branding setup for the Baskit app, including proper Google branding compliance.

## Google Sign-In Branding

### Official Google Logo Setup

To comply with Google's branding guidelines for Sign in with Google:

#### 1. Download Official Google Logo
- Visit: [Google Identity Branding Guidelines](https://developers.google.com/identity/branding-guidelines)
- Download the "G" icon in PNG format (18x18px recommended)
- Choose the light themed version for best compatibility

#### 2. Add Logo to Assets
```bash
# Save the downloaded PNG as:
app/assets/google_logo.png
```

#### 3. Update Sign-In Widget
Location: `app/lib/widgets/auth/google_sign_in_widget.dart`

**Replace the current icon:**
```dart
// Current fallback icon
icon: const Icon(Icons.account_circle, size: 18),

// Replace with official Google logo
icon: Image.asset(
  'assets/google_logo.png',
  height: 18,
  width: 18,
  errorBuilder: (context, error, stackTrace) =>
      const Icon(Icons.account_circle, size: 18),
),
```

#### 4. Update pubspec.yaml
Ensure the asset is declared:
```yaml
flutter:
  assets:
    - assets/
    - assets/google_logo.png
```

#### 5. Rebuild App
```bash
flutter clean
flutter pub get
flutter run
```

### Current Status ✅
- Web configuration fixed (client ID added to index.html)
- Fallback icon implemented (Google sign-in works without the logo)
- Widget properly handles asset loading errors
- ⏳ Waiting for official Google logo asset

## App Icons & Branding

### Current App Icon
Location: `assets/icon.png` (project root)
- Used for repository branding and documentation
- Size: 120x120px for GitHub display

### Platform-Specific Icons

#### Android Icons
Location: `app/android/app/src/main/res/`
```
mipmap-hdpi/
├── ic_launcher.png (72x72)
└── launcher_icon.png (72x72)

mipmap-mdpi/
├── ic_launcher.png (48x48)  
└── launcher_icon.png (48x48)

mipmap-xhdpi/
├── ic_launcher.png (96x96)
└── launcher_icon.png (96x96)

mipmap-xxhdpi/
├── ic_launcher.png (144x144)
└── launcher_icon.png (144x144)

mipmap-xxxhdpi/
├── ic_launcher.png (192x192)
└── launcher_icon.png (192x192)
```

#### iOS Icons
Location: `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Complete icon set for all iOS device sizes
- Generated from single high-resolution source

#### Web Icons
Location: `app/web/icons/`
```
Icon-192.png          # PWA icon
Icon-512.png          # PWA icon
Icon-maskable-192.png # Maskable icon
Icon-maskable-512.png # Maskable icon
```

### Icon Generation Tools

#### Flutter Launcher Icons
Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icon.png"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/icon.png"
    background_color: "#hexcode"
    theme_color: "#hexcode"
```

Generate icons:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## Theme Configuration

### Material Design 3
The app uses Material Design 3 with support for:
- Light/Dark theme switching
- Dynamic color theming
- Custom color schemes
- Responsive design patterns

### Theme Implementation
Location: `app/lib/main.dart`

```dart
MaterialApp.router(
  title: 'Baskit',
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
  ),
  darkTheme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
  ),
  themeMode: ThemeMode.system, // Follows system preference
)
```

### Custom Color Schemes
For list colors and branding:
```dart
// List color options
const List<Color> listColors = [
  Color(0xFF1976D2), // Blue
  Color(0xFF388E3C), // Green  
  Color(0xFFE64A19), // Orange
  Color(0xFF7B1FA2), // Purple
  Color(0xFFD32F2F), // Red
  Color(0xFF00796B), // Teal
];
```

## UI Components

### Key Widgets
- `GoogleSignInWidget`: Branded Google authentication button
- `ProfilePictureWidget`: User avatar with fallback
- `AuthWrapper`: Handles authentication state UI
- Custom list item widgets
- Material Design 3 components

### Responsive Design
- Adaptive layouts for different screen sizes
- Mobile-first approach with tablet/desktop support
- Proper touch targets and accessibility

## Asset Management Best Practices

### Directory Structure
```
app/assets/
├── icons/
│   ├── google_logo.png
│   └── app_icon.png
├── images/
│   └── placeholder.png
└── fonts/ (if custom fonts needed)
```

### Asset Optimization
- Use PNG for icons with transparency
- Optimize file sizes for mobile apps
- Provide multiple resolutions for different densities
- Use vector assets (SVG) when possible for scalability

### Loading Strategies
```dart
// Proper asset loading with error handling
Image.asset(
  'assets/google_logo.png',
  height: 18,
  width: 18,
  errorBuilder: (context, error, stackTrace) {
    // Fallback to icon or alternative
    return const Icon(Icons.account_circle, size: 18);
  },
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    // Show loading indicator
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  },
)
```

## Accessibility

### Guidelines
- Proper semantic labels for screen readers
- Sufficient color contrast ratios
- Touch target sizes (minimum 44x44 points)
- Keyboard navigation support
- High contrast mode support

### Implementation
```dart
// Semantic labels for accessibility
Semantics(
  label: 'Sign in with Google',
  button: true,
  child: ElevatedButton.icon(
    // Button implementation
  ),
)
```

## Platform Considerations

### Android
- Adaptive icons support
- Material Design guidelines
- Proper theme integration with system
- Night mode support

### iOS
- Human Interface Guidelines compliance
- Dynamic Type support
- Dark mode integration
- SF Symbols when available

### Web
- PWA icon support
- Responsive web design
- Cross-browser compatibility
- Proper favicon setup

## Troubleshooting

### Common Asset Issues
1. **Asset not found**: Check pubspec.yaml asset declarations
2. **Wrong sizes**: Verify icon dimensions match platform requirements
3. **Build errors**: Run `flutter clean` after asset changes
4. **Loading failures**: Implement proper error handling with fallbacks

### Debug Commands
```bash
# Clean and rebuild after asset changes
flutter clean
flutter pub get
flutter run

# Check asset bundle
flutter build apk --debug
# Assets included in build/app/outputs/flutter-apk/
```

This UI and assets setup ensures a polished, branded experience that follows platform guidelines while maintaining visual consistency across all platforms. 