# Baskit Smoke Test Checklist

This checklist must be completed for every Play Store release before rollout.

## Preconditions
- [ ] Fresh device or fully cleared app data
- [ ] Google Play-distributed build installed (internal/closed testing track)
- [ ] Second test account available for sharing tests
- [ ] Internet connection available

## Guest Mode

- [ ] **Guest list creation**: Create a new shopping list with at least 3 items
- [ ] **Guest list editing**: Rename the list, add items, edit item quantities
- [ ] **Guest list deletion**: Delete a shopping list and verify it is removed
- [ ] **Offline usage**: Enable airplane mode, create a list, add items, disable airplane mode — verify data persists

## Google Sign-In

- [ ] **Sign-in flow**: Tap "Sign in with Google" and complete the authentication flow
- [ ] **Guest-to-Google migration**: Verify that guest lists created before sign-in appear after successful sign-in
- [ ] **User display**: Verify the signed-in user's name and avatar are displayed in the profile screen

## Sharing

- [ ] **Share by email**: Share a list with the second test account's email address
- [ ] **Shared list appears**: Verify the shared list appears on the second test account's device
- [ ] **Real-time updates**: Add an item on one account and verify it appears on the other
- [ ] **Complete an item**: Mark an item as completed on one account and verify on the other

## Member Management

- [ ] **Leave shared list**: As the invited member, leave the shared list and verify it disappears from their lists
- [ ] **Owner removes member**: As the list owner, remove a member and verify the list disappears from their account
- [ ] **Owner cannot be removed**: Verify that the owner cannot leave their own list without transferring ownership

## Sign-Out

- [ ] **Sign-out flow**: Sign out from the profile screen
- [ ] **Returns to guest mode**: Verify the app returns to guest mode (anonymous user)
- [ ] **Cloud data not exposed**: Verify the signed-out user's cloud data is NOT visible in guest mode
- [ ] **Re-sign-in**: Sign back in and verify all cloud data is restored

## Privacy & Compliance

- [ ] **Privacy policy**: Open the About dialog from the profile screen and tap "Privacy Policy" — verify it opens in a browser
- [ ] **Account deletion link**: Verify the account deletion URL (`https://kmjayadeep.github.io/baskit/delete-account.html`) is accessible in a browser
- [ ] **App version**: Verify the About dialog shows the correct version number matching the release

## Crash Reporting

- [ ] **Crashlytics availability**: Verify that Crashlytics diagnostics and debug symbols are available for the release in the Firebase console
- [ ] **No PII in logs**: Verify that no personally identifiable information (emails, list names, item names) appears in Crashlytics logs/keys

## Additional Notes

| Item | Notes |
|------|-------|
| Tester name | |
| Device model | |
| OS version | |
| App version | |
| Date | |
| Issues found | |

---

## Sign-off

- [ ] All checklist items passed
- [ ] Issues documented and severity assessed
- [ ] Release approved for rollout

**Signed**: ______________________ **Date**: __________________
