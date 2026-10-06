# Play Release Smoke Test Checklist

Use this checklist for each Play-distributed internal, closed, or production release candidate. Automated tests must not target production Firebase; complete these steps with disposable tester accounts and test lists.

## Release Candidate

- App version/build: 
- Git tag or commit: 
- Play track: internal / closed / production
- Tester devices and Android versions: 
- Tester accounts used: 
- Date completed: 

## Guest, Sign-In, And Migration

- [ ] Install the Play-distributed build on a clean device or clear app data first.
- [ ] Create at least one guest list with multiple items while signed out/anonymous.
- [ ] Relaunch the app and confirm the guest list remains available locally.
- [ ] Sign in with Google and confirm guest lists migrate to the signed-in account.
- [ ] Confirm migrated lists and items remain visible after app restart.
- [ ] Retry scenario: interrupt connectivity during sign-in or immediately after migration starts, then restore connectivity and confirm the next authenticated access completes migration without losing local lists.

## Sharing By Email

- [ ] Share a list by email with a second Baskit tester account.
- [ ] Confirm a non-existent email shows a clear “user not found / signed up first” message.
- [ ] Confirm sharing with an existing member shows a clear “already a member” message.
- [ ] Confirm the second account sees the shared list and real-time item updates.
- [ ] Confirm both accounts can add, complete, and delete items according to expected member permissions.

## Leave-List And Remove-Member

- [ ] From the second tester account, leave the shared list.
- [ ] Confirm the list disappears for the second account and remains available to the owner.
- [ ] Re-share the list with the second tester account.
- [ ] From the owner account, remove the second tester account from the member list.
- [ ] Confirm the removed account loses access after refresh/restart.
- [ ] Confirm the owner cannot leave or remove their own owner membership.

## Account Deletion Request And Cleanup Expectations

- [ ] Open Profile > About Baskit.
- [ ] Confirm “Privacy Policy” opens `https://kmjayadeep.github.io/baskit/privacy-policy.html`.
- [ ] Confirm “Request account deletion” opens `https://kmjayadeep.github.io/baskit/delete-account.html`.
- [ ] Submit a test deletion request through the public page or record why the request was simulated.
- [ ] Verify the manual cleanup expectation for the requested account:
  - [ ] Firebase Auth account is deleted when it still exists.
  - [ ] `/users/{userId}` is deleted.
  - [ ] Lists owned by the user are deleted unless export/transfer was requested.
  - [ ] The user is removed from shared lists they do not own.
  - [ ] Completion is confirmed by email within 30 days.

## Sign-Out, Privacy, And Diagnostics

- [ ] Sign out and confirm the app returns to guest mode without showing signed-in cloud data.
- [ ] Confirm the Play Data Safety answers still match the shipped SDKs and privacy policy.
- [ ] Confirm Crashlytics receives release-build diagnostics from the smoke-test build.
- [ ] Confirm native debug symbols for this exact build are uploaded/available.

## Notes And Evidence

- Screenshots, issue links, or tester feedback:
- Failures found and owner:
- Release decision: proceed / block / retest
