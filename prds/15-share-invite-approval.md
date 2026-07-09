# Baskit PRD - Share Invite Approval

## Purpose
Require recipients to explicitly approve list share invitations before a list is added to their account. Users should be able to decide whether they want to accept shares from a specific person, preventing unexpected lists from appearing just because someone knows their email address.

## Problem
The current sharing flow adds the target user directly to a list after email lookup. This is convenient for trusted collaborators, but it gives recipients no opportunity to accept, decline, or control future shares from the same sender.

## Goals
- Convert direct list sharing into an invitation-based flow.
- Keep the existing share-by-email experience for senders, with clear pending status.
- Let recipients accept or decline pending list invitations before membership is activated.
- Let recipients choose whether future shares from the same sender can be accepted automatically.
- Prevent pending invites from granting list/item access until accepted.
- Preserve local-first guest behavior and authenticated-only sharing.

## Non-Goals
- Do not support sharing with users who do not have an account in this phase.
- Do not implement public invite links.
- Do not add granular per-item permissions beyond the existing list member permissions.
- Do not build a full contacts or social graph feature.

## User Stories
- As a list owner, I can invite another Baskit user by email and see that the invite is pending until they accept.
- As an invited user, I can review who invited me, which list they want to share, and when the invite was sent.
- As an invited user, I can accept the invite to join the list.
- As an invited user, I can decline the invite so the list is not added to my account.
- As an invited user, I can choose to automatically accept future list shares from a trusted sender.
- As an invited user, I can revoke automatic acceptance for a sender later.

## UX Requirements

### Sender Flow
- Sharing remains available only to authenticated users.
- The share dialog continues to accept an email address and validates that the target user exists.
- If the target user has not allowed automatic acceptance from the sender, creating a share should create a pending invite instead of adding the target to `memberIds`/`members`.
- The sender sees a success message such as `Invite sent to jane@example.com`.
- Member management UI should distinguish active members from pending invitees.
- The sender can cancel a pending invite before it is accepted.
- Duplicate pending invites for the same list and recipient are prevented.

### Recipient Flow
- Recipients should have an obvious place to see pending invitations, such as an inbox entry, lists-page banner, or notifications section.
- Each pending invite displays:
  - list name
  - sender display name/email
  - sender avatar when available
  - sent date/time
- Recipient actions:
  - `Accept`: activates membership and the list appears in their lists.
  - `Decline`: rejects the invitation and does not add the list.
  - `Always accept from this person`: accepts the current invite and stores a sender-level preference for future shares.
- If future shares from a trusted sender are auto-accepted, the recipient should still be able to find and manage the resulting shared list normally.
- Users can manage trusted senders from settings or an equivalent account/preferences screen.

### Trust and Safety
- Pending invites must not expose list items to the recipient until accepted.
- Declined or canceled invites must not leave the recipient in `memberIds`.
- A recipient can remove a sender from their trusted-senders list at any time.
- The app should handle sender profile changes gracefully; historical invite records may keep sender snapshots for display.

## Data Requirements

### Firestore Collections
Add an invitation model, for example:

- `/shareInvites/{inviteId}`

Required invite fields:
- `listId`: string
- `listName`: string snapshot for invite display
- `senderId`: Firebase UID
- `senderEmail`: nullable string snapshot
- `senderDisplayName`: nullable string snapshot
- `senderAvatarUrl`: optional string snapshot
- `recipientId`: Firebase UID
- `recipientEmail`: string snapshot
- `status`: `pending | accepted | declined | canceled | expired`
- `createdAt`: timestamp
- `updatedAt`: timestamp
- `respondedAt`: nullable timestamp

Add a sender preference model, for example:

- `/users/{userId}/sharePreferences/trustedSenders`

or a map/array under `/users/{userId}` if simpler and within Firestore limits.

Trusted sender fields:
- `senderId`: Firebase UID
- `senderEmail`: nullable string snapshot
- `senderDisplayName`: nullable string snapshot
- `trustedAt`: timestamp

### List Membership
- Pending invites do not add the recipient to `lists.{listId}.memberIds` or `lists.{listId}.members`.
- Accepting an invite adds the recipient using the existing `ListMember` shape and default member permissions.
- Auto-accepted shares from trusted senders may add the recipient directly and optionally record an accepted invite for audit/history.

## Query and Index Requirements
- Recipient pending invites: `recipientId == currentUserId` and `status == pending`, ordered by `createdAt desc`.
- Sender pending invites for a list: `listId == listId`, `senderId == currentUserId`, and `status == pending`.
- Duplicate prevention should check for an existing pending or accepted membership for the same `listId` + `recipientId`.
- Add Firestore indexes for invite recipient/status/date and list/sender/status queries as needed.

## State Management Requirements
- Add repository/service methods for creating, canceling, accepting, declining, and observing share invites.
- Expose pending recipient invites through Riverpod providers/view models.
- Existing list streams should continue to show only lists where the user is an active member.
- Share-related UI should surface typed/user-friendly errors rather than generic failures where possible.

## Security Rules Requirements
- Only authenticated users can create share invites.
- A sender can create invites only for lists where they have share permission.
- A recipient can read invites addressed to their UID.
- A sender can read/cancel pending invites they created.
- Only the recipient can accept or decline their invite.
- Membership activation must be protected so only an accepted invite, trusted-sender auto-accept path, owner, or authorized sharer can add the recipient.
- Pending invite documents must not grant list/item read access by themselves.

## Migration and Compatibility
- Existing active shared members remain active; do not require retroactive acceptance.
- Existing direct-share flows should be updated to the invite path for new shares.
- Guest/local-only users cannot send or receive cloud share invites until authenticated.
- If an invite references a deleted list, accepting it should fail with a clear message and mark or treat the invite as expired/canceled.

## Acceptance Criteria
- Given an authenticated owner invites an existing user who has not trusted them, the recipient is not added to the list until they accept.
- Given a recipient accepts an invite, the list appears in their lists and they receive default member permissions.
- Given a recipient declines an invite, the list does not appear and the sender no longer sees it as actionable pending access.
- Given a recipient chooses `Always accept from this person`, future shares from that sender are accepted without a manual prompt.
- Given a recipient removes a trusted sender, subsequent shares from that sender require approval again.
- Given a pending invite exists, creating another invite for the same list and recipient is prevented.
- Given a pending invite exists, the recipient cannot read list items until acceptance.
- Tests cover invite creation, duplicate prevention, accept, decline, cancel, trusted-sender auto-accept, and security-rule expectations where test infrastructure supports them.
