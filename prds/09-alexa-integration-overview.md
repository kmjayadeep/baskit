# Alexa Integration Overview

## Purpose

The Baskit app should support Alexa account linking and voice settings so a signed-in user can add items to Baskit lists by voice.

The app does not process Alexa voice requests. The app owns the user-facing setup flow:

1. Open from Alexa account-linking deep link.
2. Require a signed-in Baskit cloud account.
3. Confirm linking Alexa to the current Baskit account.
4. Send Firebase ID token to Baskit backend.
5. Return user to Alexa when linking is complete.
6. Let user choose a default writable list for voice commands.

## User Flow

### 1. Start in Alexa App

1. User opens Alexa app.
2. User selects the Baskit skill.
3. User taps account linking.
4. Alexa opens Baskit's OAuth authorize URL.
5. Baskit backend redirects to the Baskit app deep link.

### 2. Continue in Baskit App

1. Baskit app opens the Alexa linking screen.
2. App validates that required OAuth params are present in the deep link.
3. If user is not signed in, app asks user to sign in.
4. If user is anonymous/local-only, app explains that Alexa requires a cloud account.
5. App shows the current signed-in account.
6. User confirms linking.
7. App requests a fresh Firebase ID token.
8. App sends the ID token plus OAuth params to Baskit backend.
9. Backend returns an authorization code.
10. App opens Alexa redirect URI with `code` and `state`.
11. Alexa completes token exchange with backend.

### 3. Manage Default List

1. User opens app settings.
2. User opens Voice Assistant or Alexa settings.
3. App lists cloud-synced lists where current user has write permission.
4. User selects a default list.
5. App writes selected list ID to:

```text
/users/{uid}.voiceSettings.defaultListId
```

## App Responsibilities

| Area | Requirement |
| --- | --- |
| Deep link routing | Route `baskit://integrations/alexa/link` to Alexa linking screen |
| Param preservation | Preserve OAuth params through sign-in and app lifecycle changes |
| Auth | Require Firebase signed-in non-anonymous user |
| Confirmation | Make user explicitly approve linking Alexa to current Baskit account |
| Backend handoff | Send Firebase ID token and OAuth params to backend completion endpoint |
| Return to Alexa | Open Alexa redirect URI with `code` and preserved `state` |
| Voice settings | Let user select a writable cloud list as default |
| Error UX | Explain unsupported local/anonymous state and retryable backend failures |

## Non-Responsibilities

1. The app does not generate OAuth access tokens.
2. The app does not validate Alexa client credentials.
3. The app does not fulfill Alexa voice commands.
4. The app does not write voice-created items directly during Alexa requests.

## Required Screens

### Alexa Linking Screen

States:

1. Loading link params.
2. Missing or invalid link params.
3. Signed out, sign-in required.
4. Anonymous/local-only account, upgrade required.
5. Ready to link current account.
6. Linking in progress.
7. Linking failed with retry.
8. Linking complete, returning to Alexa.

Required copy:

```text
Link Alexa to Baskit
Alexa will be able to add items to your Baskit lists using your voice.
```

The screen should show enough account context to avoid linking the wrong account, such as email or display name when available.

### Voice Assistant Settings

States:

1. Not linked or unknown linked status.
2. Linked account.
3. No writable cloud lists.
4. Default list selected.
5. Default list missing/deleted/read-only.

MVP can omit live linked-status detection if backend does not expose it yet. In that case, settings should focus on default list selection.

## Target Deep Link

```text
baskit://integrations/alexa/link
```

Expected query params:

| Param | Source | Required |
| --- | --- | --- |
| `response_type` | Alexa/backend | Yes |
| `client_id` | Alexa/backend | Yes |
| `redirect_uri` | Alexa/backend | Yes |
| `state` | Alexa | No, but preserve if present |
| `scope` | Alexa/backend | No |

The app should not make authorization decisions from these values. It should send them back to the backend for validation.

## Phased Delivery

### Phase 1: Account Linking App Flow

1. Add deep link route.
2. Add linking screen.
3. Preserve OAuth params through sign-in.
4. Require non-anonymous Firebase user.
5. Call backend completion endpoint.
6. Open Alexa redirect URI with returned code.
7. Handle errors and cancellation.

### Phase 2: Voice Settings

1. Add settings entry point.
2. Query writable cloud lists.
3. Save default list ID.
4. Handle read-only/deleted default list.

### Phase 3: Linked Status and Unlink

1. Show Alexa linked status if backend exposes it.
2. Provide unlink/manage instructions.
3. Optionally call backend revoke endpoint from app.

## Open Questions

1. Should linking require selecting a default list immediately? Recommendation: not for phase 1; keep account linking focused.
2. Should the app use custom scheme only or Android App Links as an HTTPS fallback? Recommendation: support HTTPS App Link before public release.
3. Should the app expose unlink in MVP? Recommendation: include copy, backend revoke can come later if Alexa unlink handles revocation.
