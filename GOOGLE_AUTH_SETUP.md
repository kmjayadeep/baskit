# Google Authentication Setup for Baskit

## 🔑 Current Status
- Google Sign-In dependency added ✅
- Firebase Auth service with Google support ✅  
- Anonymous auth fallback ✅
- Android build configuration updated ✅

## 📱 Firebase Console Configuration

### 1. Enable Google Authentication
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Authentication** → **Sign-in method**
4. Click on **Google** provider
5. **Enable** the Google sign-in method
6. Set **Project support email** (your email)
7. Click **Save**

### 2. Configure OAuth Consent Screen
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your Firebase project
3. Go to **APIs & Services** → **OAuth consent screen**
4. Choose **External** user type
5. Fill in required fields:
   - **App name**: Baskit
   - **User support email**: Your email
   - **Developer contact**: Your email
6. Add **Authorized domains** (if you have a website)
7. **Save and Continue**

## 🔧 Android Configuration ✅ FIXED

### Build Configuration Updated
The following have been automatically configured:

**✅ Project-level `android/build.gradle.kts`:**
```gradle
buildscript {
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

**✅ App-level `android/app/build.gradle.kts`:**
```gradle
android {
    compileSdk = 34
    ndkVersion = "27.0.12077973"  // Required for Firebase
    
    defaultConfig {
        applicationId = "com.cboxlab.baskit"
        minSdk = 23          // Required for Firebase Auth
        targetSdk = 34
    }
}

dependencies {
    implementation("com.google.android.gms:play-services-auth:20.7.0")
}
```

### 1. Get SHA Certificate Fingerprints
For **Debug** builds (development):
```bash
cd app/android
./gradlew signingReport
```

Or use keytool directly:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### 2. Add SHA Fingerprints to Firebase
1. In Firebase Console → **Project Settings**
2. Select your Android app or add a new one:
   - Package name: `com.cboxlab.baskit`
   - App nickname: `Baskit`
3. Click **Add fingerprint**
4. Add the **SHA1** and **SHA256** from the debug keystore
5. Download the updated `google-services.json`
6. Place it in `app/android/app/google-services.json`

## 🧪 Test Google Authentication

### 1. Build and Test
```bash
cd app
flutter clean
flutter pub get
flutter build apk --debug    # For Android testing
flutter run                  # For device testing
```

### 2. Expected Results
- ✅ **No NDK version conflicts**
- ✅ **No minSdkVersion errors** 
- ✅ **Firebase plugins compile successfully**
- ✅ **Google Sign-In works on Android devices**

### 3. Authentication Flow
The app includes:
- **Anonymous sign-in by default** ✅
- **Google sign-in button** (when implemented in UI)
- **Account linking** (anonymous → Google account)
- **Seamless data migration** ✅

### 4. Expected User Experience
1. **Start Anonymous**: User starts with anonymous auth
2. **Create Lists**: User can create lists immediately  
3. **Sign In with Google**: Optional upgrade to Google account
4. **Data Migration**: All anonymous data transfers to Google account
5. **Cross-device Sync**: Lists sync across all devices

## 🎨 UI Integration Example

Here's how to add a Google Sign-In button to your UI:

```dart
import '../services/firebase_auth_service.dart';
import '../widgets/auth/google_sign_in_widget.dart';

// In your profile screen or settings page:
GoogleSignInWidget(
  onSignInSuccess: () {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Signed in with Google!')),
    );
  },
  onSignOut: () {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Signed out')),
    );
  },
)
```

## 🔄 Data Migration Strategy

The app automatically handles:
1. **Anonymous Data**: Stored locally initially
2. **Google Sign-In**: Links anonymous account to Google
3. **Cloud Sync**: Migrates all data to Firestore
4. **Real-time Updates**: Enables cross-device collaboration

## 🔐 Security Benefits

With Google Auth enabled:
- **Verified Identity**: Users authenticated via Google
- **Account Recovery**: Users can recover access via Google account  
- **Cross-device Access**: Same account on multiple devices
- **Secure Sharing**: Share lists with verified Google accounts

## 🚀 Ready to Use!

Once configured:
- **Anonymous users** can upgrade to Google accounts seamlessly
- **All data transfers** automatically during sign-in
- **Real-time sync** works across all signed-in devices
- **Guest experience** remains unchanged (no forced sign-in)
- **Android builds** work without NDK or SDK version conflicts

The Google authentication maintains the guest-first philosophy while providing premium features for signed-in users! 