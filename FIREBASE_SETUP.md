# Firebase Setup Guide for Baskit

## Current Status ✅
- Firebase dependencies added to `pubspec.yaml`
- Firebase Authentication service created (`lib/services/firebase_auth_service.dart`)
- Firestore service created (`lib/services/firestore_service.dart`)
- Main app updated to initialize Firebase services
- Firestore security rules created (`firestore.rules`)

## Next Steps to Complete Firebase Setup

### 1. 📱 Configure Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your test database project
3. **Enable Authentication:**
   - Go to Authentication > Sign-in method
   - Enable **Anonymous** authentication
   - Enable **Google** sign-in (optional but recommended)
   - Enable **Email/Password** sign-in (optional)

4. **Configure Firestore Database:**
   - Go to Firestore Database
   - Make sure it's in "production mode" 
   - Deploy the security rules from `firestore.rules`

### 2. 📱 Add Configuration Files

#### For Android:
1. In Firebase Console, go to Project Settings
2. Add an Android app if you haven't already:
   - Package name: `com.baskit.app` (or your preferred package name)
   - App nickname: `Baskit`
3. Download `google-services.json`
4. Place it in `app/android/app/google-services.json`

#### For iOS (if needed):
1. Add an iOS app in Firebase Console
2. Download `GoogleService-Info.plist`
3. Place it in `app/ios/Runner/GoogleService-Info.plist`

### 3. 🔧 Configure Android Build

After adding `google-services.json`, update your Android build configuration:

1. **Update `app/android/build.gradle`:**
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
    // ... other dependencies
}
```

2. **Update `app/android/app/build.gradle`:**
```gradle
// At the top, after other plugins
apply plugin: 'com.google.gms.google-services'

android {
    compileSdkVersion 34 // Make sure this is at least 33
    // ... rest of configuration
}
```

### 4. 🧪 Test the Setup

Once configuration files are in place, you can test:

```bash
cd app
flutter clean
flutter pub get
flutter run
```

The app should:
- ✅ Start with anonymous authentication
- ✅ Initialize Firestore with offline persistence
- ✅ Create user profile automatically
- ✅ Be ready to sync data to Firebase

### 5. 🔄 Data Migration Strategy

The app is set up to:
1. **Continue using local storage** as fallback
2. **Automatically sync** new data to Firebase
3. **Migrate existing local data** when user signs in

To trigger migration of existing local data:
- The `FirestoreService.migrateLocalData()` method is available
- You can call this when user first signs in with a permanent account

### 6. 🚀 Features Now Available

With Firebase configured, you'll have:
- **Anonymous Authentication**: Users start using immediately
- **Real-time Updates**: Lists sync across devices instantly
- **Offline Support**: Works without internet, syncs when online
- **Account Conversion**: Seamlessly convert anonymous to full account
- **Collaboration Ready**: Foundation for sharing lists between users

### 7. 🔐 Security Rules

The `firestore.rules` file provides:
- User isolation (users can only access their own data)
- Support for shared lists (when implemented)
- Anonymous user support
- Invitation system foundation

Deploy these rules to your Firestore database in the Firebase Console.

### 8. 🐛 Common Issues

If you encounter issues:

1. **Build errors**: Make sure `google-services.json` is in the correct location
2. **Authentication errors**: Check that Anonymous auth is enabled in Firebase Console
3. **Permission errors**: Verify Firestore rules are deployed correctly
4. **Network errors**: Ensure your app has internet permissions

### 9. 📱 Ready to Use!

Once setup is complete, your app will:
- Start with anonymous authentication ✅
- Save all data to Firebase ✅
- Work offline with automatic sync ✅
- Be ready for real-time collaboration features ✅

The foundation is now in place for a fully-featured collaborative shopping list app! 