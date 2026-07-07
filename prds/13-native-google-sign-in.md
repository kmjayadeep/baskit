# Baskit PRD - Native Google Sign-In

## Purpose
Baskit should use the device-native Google account picker on mobile platforms instead of opening a browser-hosted OAuth page for Google login. The goal is to match common Android/iOS app login behavior while preserving Baskit's guest-first account upgrade flow.

## Problem
The current mobile implementation uses Firebase Auth provider APIs (`signInWithProvider` / `linkWithProvider`). On Android and iOS this can open a browser, custom tab, or web OAuth page. Users expect to choose from Google accounts already present on the phone, and the web-style flow feels less integrated and less trustworthy.

## Goals
- Use native Google Sign-In on Android and iOS for account selection.
- Preserve anonymous-to-Google account linking so guest data is not lost.
- Keep the existing web behavior for Flutter Web.
- Keep sign-out and account deletion behavior consistent with the current app.
- Provide user-friendly errors when native sign-in is cancelled, unavailable, or misconfigured.

## Non-Goals
- Silent login without user consent.
- Replacing Firebase Authentication.
- Changing Firestore security rules or the user profile schema.
- Introducing non-Google identity providers.

## User Experience Requirements
1. When a guest taps **Sign in with Google** on Android/iOS, the app should show the native Google account chooser or Credential Manager style prompt where available.
2. Existing Google accounts on the device should be offered without requiring the user to type credentials again unless Google requires reauthentication.
3. If the user cancels, Baskit should stay in guest mode and show a non-alarming cancellation message when appropriate.
4. If sign-in succeeds, Baskit should show the existing signed-in profile state and migrate/link data as it does today.
5. Flutter Web should continue using Firebase Auth popup/redirect behavior.

## Functional Requirements
- On mobile platforms, use `google_sign_in` to request Google authentication tokens through the native platform implementation.
- Convert the returned Google ID/access tokens to a Firebase `GoogleAuthProvider.credential`.
- If the current Firebase user is anonymous, link the credential to that user.
- If no anonymous user exists, sign in with the credential.
- Handle `credential-already-in-use` and `provider-already-linked` without data loss; return a clear error or recovery path.
- Continue signing out from both Firebase Auth and Google Sign-In.
- Keep local-only mode behavior unchanged when Firebase is unavailable.

## Configuration Requirements
- Verify Android OAuth client configuration includes the production package name and signing certificate SHA fingerprints.
- Verify iOS URL scheme and reversed client ID setup if/when iOS support is enabled.
- Document any required Firebase Console or Google Cloud Console setup in development docs.

## Acceptance Criteria
- Android Google login opens the native Google account chooser/prompt instead of a browser page.
- Anonymous guest upgrade links to the Google account and preserves guest lists.
- Existing signed-out Google users can sign in through the native prompt.
- Sign-in cancellation leaves the app usable in guest mode.
- Web Google login still works using the existing web flow.
- `flutter analyze` and relevant auth/widget tests pass.

## Testing Plan
- Unit test credential/link branching where practical by isolating auth flow logic.
- Widget test that cancellation or failure keeps the sign-in CTA usable.
- Manual Android smoke test with:
  - Device with an existing Google account.
  - Fresh guest account with local lists.
  - Sign out followed by sign in again.
  - Cancelled sign-in flow.
- Manual web smoke test to confirm popup behavior is unchanged.

## Risks and Mitigations
- **OAuth SHA mismatch:** native sign-in can fail if debug/release signing certificates are missing. Mitigate by documenting and validating Firebase OAuth client setup.
- **Anonymous link conflicts:** linking can fail when the Google account is already attached to another Firebase user. Mitigate with explicit error handling and no local data deletion before successful migration.
- **Plugin API changes:** `google_sign_in` 7.x has a newer API surface. Mitigate by using the currently pinned package APIs and adding focused tests around app-owned branching logic.
