# PRD: Alexa Account Linking App

## Summary

Implement the Baskit app flow that completes Alexa account linking after Alexa redirects the user into Baskit.

The app must authenticate the user with Firebase, ask for explicit confirmation, send a Firebase ID token to the backend, then return the user to Alexa with the authorization code supplied by the backend.

## Goals

1. Handle Alexa account-linking deep links.
2. Preserve OAuth parameters across sign-in and app lifecycle changes.
3. Require a signed-in non-anonymous Baskit user.
4. Confirm the user wants to link Alexa to the current Baskit account.
5. Submit Firebase ID token and OAuth parameters to backend.
6. Return to Alexa with authorization code and state.
7. Provide clear failure and cancellation states.

## Non-Goals

1. Choosing a default voice list.
2. Displaying voice command history.
3. Fulfilling Alexa voice commands.
4. Implementing backend OAuth token exchange.
5. Building Alexa skill package.

## Entry Point

The app should handle this deep link:

```text
baskit://integrations/alexa/link
```

Required params:

```text
response_type=code
client_id=...
redirect_uri=...
```

Optional params:

```text
scope=...
state=...
```

The app must keep these params unchanged when calling the backend completion endpoint.

## Detailed Flow

### Step 1: Receive Deep Link

1. App receives `baskit://integrations/alexa/link`.
2. App parses query params.
3. App validates that required params are present and non-empty.
4. App stores params in a transient linking state.
5. App routes to Alexa linking screen.

If params are missing:

```text
We could not start Alexa linking because the request was incomplete. Please try again from the Alexa app.
```

### Step 2: Require Sign-In

1. If user is signed in and not anonymous, continue.
2. If user is signed out, show sign-in requirement.
3. If user is anonymous/local-only, explain that Alexa requires a cloud account.
4. After successful sign-in, return to the Alexa linking screen with original params intact.

Required behavior:

1. Do not drop OAuth params during sign-in.
2. Do not complete linking silently after sign-in.
3. Always show confirmation before backend completion.

### Step 3: Confirm Linking

Show:

1. Title: `Link Alexa to Baskit`
2. Current account email/display name when available.
3. Explanation that Alexa can add items to Baskit lists by voice.
4. Primary action: `Link Alexa`
5. Secondary action: `Cancel`

Cancel behavior:

1. Prefer returning to Alexa redirect URI with OAuth error if safe.
2. If not implemented, show cancellation copy and let user return manually.

Recommended OAuth cancel redirect:

```text
{redirect_uri}?error=access_denied&state={state}
```

### Step 4: Complete Authorization

On `Link Alexa`:

1. Request fresh Firebase ID token from current user.
2. POST to backend `/oauth/authorize/complete`.
3. Include original OAuth params and `id_token`.
4. Wait for backend response.

Request body:

```json
{
  "response_type": "code",
  "client_id": "alexa-client-id",
  "redirect_uri": "https://alexa.amazon.com/api/skill/link/callback",
  "scope": "baskit.voice",
  "state": "state-from-alexa",
  "id_token": "firebase-id-token"
}
```

Successful response:

```json
{
  "authorizationCode": "code",
  "expiresIn": 300,
  "state": "state-from-alexa"
}
```

### Step 5: Return to Alexa

Build redirect URL from original `redirect_uri`:

```text
{redirect_uri}?code={authorizationCode}&state={state}
```

Rules:

1. Preserve `state` exactly if present.
2. URL-encode params.
3. Do not append Firebase ID token.
4. Do not append user profile data.
5. Open the redirect URI using the platform URL launcher.

## Error Handling

| Error | User Message | Action |
| --- | --- | --- |
| Missing params | Request incomplete | Restart from Alexa app |
| Signed out | Sign in required | Open sign-in flow |
| Anonymous user | Cloud account required | Prompt upgrade/sign-in |
| Backend `invalid_client` | Could not verify Alexa request | Restart from Alexa app |
| Backend `invalid_token` | Sign-in expired | Re-auth or retry |
| Network failure | Could not link right now | Retry |
| User cancel | Linking cancelled | Return or close |

## State Management Requirements

The linking state must contain:

```text
responseType
clientId
redirectUri
scope
state
startedAt
status
error
```

The state should survive:

1. Navigation to sign-in screen.
2. Firebase auth result callback.
3. App background/foreground during linking.

The state does not need long-term persistence after success or cancellation.

## Security Requirements

1. Never log Firebase ID tokens.
2. Never store Firebase ID tokens in persistent app storage.
3. Never trust or modify `redirect_uri`; backend validates it.
4. Show account identity before user confirms linking.
5. Do not complete linking for anonymous/local-only users.
6. Clear transient linking state after success, cancellation, or terminal error.

## Acceptance Criteria

1. Alexa deep link opens the linking screen.
2. Missing params show a recoverable error.
3. Signed-out user can sign in and resume linking.
4. Anonymous user cannot complete linking.
5. User sees confirmation before linking.
6. App sends Firebase ID token and OAuth params to backend.
7. App opens Alexa redirect URI with code and state after success.
8. Firebase ID token is not logged or persisted.
9. User can cancel linking.

## Implementation Tasks

### App Task 1: Deep Link Route

1. Register route for `baskit://integrations/alexa/link`.
2. Parse OAuth query params.
3. Add validation for required params.
4. Route to linking screen.

### App Task 2: Linking State

1. Add transient state model.
2. Preserve state through sign-in navigation.
3. Clear state on success/cancel/failure.

### App Task 3: Auth Gate

1. Detect signed-out user.
2. Detect anonymous/local-only user.
3. Return to linking screen after sign-in.

### App Task 4: Confirmation UI

1. Show current account context.
2. Show linking explanation.
3. Add link and cancel actions.

### App Task 5: Backend Completion Client

1. Get fresh Firebase ID token.
2. POST completion request.
3. Parse success and error responses.
4. Ensure no token logging.

### App Task 6: Alexa Redirect

1. Build redirect URI with code and state.
2. Launch redirect URI.
3. Show fallback message if redirect fails.

### App Task 7: Tests

1. Unit test param parser.
2. Unit test redirect URL builder.
3. Widget test linking states.
4. Integration test sign-in resume path if feasible.
