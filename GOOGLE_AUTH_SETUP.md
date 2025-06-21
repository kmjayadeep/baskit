# Google Authentication Setup for Baskit

## 🔑 Current Status
- Google Sign-In dependency added ✅
- Firebase Auth service with Google support ✅  
- Anonymous auth fallback ✅

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

## 🔧 Android Configuration

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
2. Select your Android app
3. Click **Add fingerprint**
4. Add the **SHA1** and **SHA256** from the debug keystore
5. Download the updated `google-services.json`
6. Replace the file in `app/android/app/google-services.json`

### 3. Configure Android Build Files

**Update `app/android/app/build.gradle`:**
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.baskit.app"  // Make sure this matches Firebase
        minSdkVersion 21
        targetSdkVersion 34
        // ... other settings
    }
}

dependencies {
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
    // ... other dependencies
}
```

**Update `app/android/build.gradle`:**
```gradle
dependencies {
    classpath 'com.android.tools.build:gradle:8.1.0'
    classpath 'com.google.gms:google-services:4.4.0'
    // ... other dependencies
}
```

## 🧪 Test Google Authentication

### 1. Authentication Flow
The app already includes:
- **Anonymous sign-in by default** ✅
- **Google sign-in button** (when implemented in UI)
- **Account linking** (anonymous → Google account)
- **Seamless data migration** ✅

### 2. Expected User Experience
1. **Start Anonymous**: User starts with anonymous auth
2. **Create Lists**: User can create lists immediately  
3. **Sign In with Google**: Optional upgrade to Google account
4. **Data Migration**: All anonymous data transfers to Google account
5. **Cross-device Sync**: Lists sync across all devices

### 3. Testing Commands
```bash
cd app
flutter clean
flutter pub get
flutter run -d linux    # For development
flutter run             # For Android device
```

## 🎨 UI Integration Example

Here's how to add a Google Sign-In button to your UI:

```dart
import '../services/firebase_auth_service.dart';

class SignInButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final result = await FirebaseAuthService.signInWithGoogle();
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signed in successfully!')),
          );
        }
      },
      icon: Icon(Icons.account_circle),
      label: Text('Sign in with Google'),
    );
  }
}
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

The Google authentication maintains the guest-first philosophy while providing premium features for signed-in users! 