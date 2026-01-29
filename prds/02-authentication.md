# Baskit PRD - Authentication

## Modes
1. **Local-only** (Firebase not configured)
   - No Firebase initialization
   - No auth APIs are used
   - All data remains in Hive

2. **Firebase-enabled guest** (anonymous auth)
   - App signs in anonymously on launch
   - User profile created in Firestore
   - Lists stay local until upgrade

3. **Google authenticated**
   - Anonymous account is linked to Google
   - Local lists migrate to Firestore
   - All list operations route to Firestore

## Requirements
- On startup, attempt Firebase init; if it fails, run in local-only mode
- When Firebase is available, sign in anonymously and create a user profile
- Provide Google Sign-In upgrade and link the existing anonymous account
- Sign-out clears local data and returns to anonymous mode
- Account deletion clears local data and returns to anonymous mode
- UI must expose account status, display name, and email when available

## Authentication UX
- Guests see a clear “Sign in with Google” CTA
- Signed-in users see profile info and “Sign out” CTA
- Firebase-unavailable state communicates local-only mode

## Security
- Guest data stays on device until upgrade
- Firestore access is restricted by security rules and membership checks
