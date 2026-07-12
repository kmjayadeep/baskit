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
- Preserve local-first guest behavior and non-anonymous Google-authenticated sharing.

## Non-Goals
- Do not support sharing with users who do not have an account in this phase.
- Do not implement public invite links.
- Do not add granular per-item permissions beyond the existing list member permissions.
- Do not build a full contacts or social graph feature.

## Mandatory Architecture Decision

All share-invite state transitions and all membership additions are server-authoritative. Implement callable Firebase Functions in `../baskit-server/firebase-functions`; the Flutter client must not create or mutate invite documents, active-invite guards, or list membership directly.

The backend API must provide these authenticated operations:
- `createShareInvite(listId, recipientEmail)`
- `cancelShareInvite(inviteId)`
- `acceptShareInvite(inviteId, alwaysTrustSender)`
- `declineShareInvite(inviteId)`
- `removeTrustedShareSender(senderId)`

Each function must derive the caller UID and authentication-provider state from the verified Firebase Auth token. It must derive user profiles, list data, permissions, timestamps, invite snapshots, and membership fields from Firestore. Client-supplied identity, permission, status, timestamp, list-name, or member data must never be trusted.

Firebase App Check must be enforced on these callable functions in production as an abuse-reduction control. App Check does not replace Firebase Auth or backend authorization. Development and emulator environments may use documented debug tokens.

Firestore rules must deny client create, update, and delete access to `/shareInvites`, `/activeShareInvites`, trusted-sender documents, and membership additions. Clients retain only the narrowly scoped reads described below. There is no client-only implementation fallback.

Every callable operation must return a stable typed result. The minimum error codes are `unauthenticated`, `app-check-failed`, `google-sign-in-required`, `invalid-argument`, `recipient-not-found`, `recipient-update-required`, `self-invite`, `list-not-found`, `permission-denied`, `already-member`, `invite-not-found`, `invite-expired`, `invite-already-resolved`, `feature-disabled`, `resource-conflict`, and `temporarily-unavailable`. Flutter must map each expected code to tested user-facing copy; unknown errors use a retry-safe generic message and structured diagnostic logging.

## User Stories
- As a list owner, I can invite another Baskit user by email and see that the invite is pending until they accept.
- As an invited user, I can review who invited me, which list they want to share, and when the invite was sent.
- As an invited user, I can accept the invite to join the list.
- As an invited user, I can decline the invite so the list is not added to my account.
- As an invited user, I can choose to automatically accept future list shares from a trusted sender.
- As an invited user, I can revoke automatic acceptance for a sender later.

## UX Requirements

### Sender Flow
- Sharing remains available only to non-anonymous Google-authenticated users.
- The share dialog continues to accept an email address and validates that the target user exists.
- If the target user has not allowed automatic acceptance from the sender, creating a share should create a pending invite instead of adding the target to `memberIds`/`members`.
- The sender sees a success message such as `Invite sent to jane@example.com`.
- Member management UI should distinguish active members from pending invitees.
- The sender can cancel a pending invite before it is accepted.
- Duplicate pending invites for the same list and recipient are prevented.

### Recipient Flow
- The lists screen must show a persistent `Pending invitations` entry with an unread count whenever pending invitations exist. Opening it shows the invitation inbox. Do not rely solely on SnackBars, push notifications, email, or a transient banner.
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
- Account settings must include a `Trusted share senders` screen where users can review and remove trusted senders.

### Trust and Safety
- Pending invites must not expose list items to the recipient until accepted.
- Declined or canceled invites must not leave the recipient in `memberIds`.
- A recipient can remove a sender from their trusted-senders list at any time.
- The app should handle sender profile changes gracefully; historical invite records may keep sender snapshots for display.

## Data Requirements

### Firestore Collections
Add an invitation model:

- `/shareInvites/{inviteId}`

This PRD extends the canonical Firestore data model in `prds/04-firestore-data-model.md` with invite and trusted-sender collections.

Use a per-attempt invite id and an active-invite guard at `/activeShareInvites/{guardId}`. Compute `guardId` on the backend as a collision-safe encoding or cryptographic hash of the canonical `listId` and `recipientId`; do not use ambiguous raw string concatenation. The guard stores `inviteId`, `listId`, `recipientId`, and `expiresAt`.

`createShareInvite` must use a Firestore transaction that reads the list, recipient, trusted-sender document, and guard. Within that transaction it must:
- reject self-invites, nonexistent recipients, existing active membership, and callers without share permission;
- treat an expired guard as stale, mark its referenced pending invite `expired` when it still exists, and replace the guard;
- return the existing pending invite as an idempotent success when the same logical request is retried;
- either create the pending invite and guard atomically, or perform trusted-sender auto-accept atomically as described below.

Accepting, declining, canceling, or expiring an invite must update the invite and delete its matching guard in the same backend transaction. A missing or mismatched guard must not prevent a valid terminal transition; the transaction must repair that inconsistency safely. Re-inviting after a terminal state creates a new invite id and audit record.

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
- `expiresAt`: timestamp for pending invite expiration

Add a sender preference model using one document per trusted sender:

- `/users/{userId}/trustedShareSenders/{senderId}`

The document id is the trusted sender UID. The recipient may read their own trusted-sender documents. Only the callable backend creates or deletes them. `createShareInvite` reads the single `/users/{recipientId}/trustedShareSenders/{senderId}` document with the Admin SDK; senders cannot read or enumerate a recipient's trust data.

Trusted sender fields:
- `senderId`: Firebase UID
- `senderEmail`: nullable string snapshot
- `senderDisplayName`: nullable string snapshot
- `trustedAt`: timestamp

Add `/users/{userId}/capabilities.shareInvitesVersion` as an integer capability marker. An invite-capable authenticated app writes `1` to its current user's profile after the invitation inbox and action handlers are initialized successfully. Rules allow a user to update only their own capability marker with an integer value from the supported allowlist. This marker is a delivery-readiness signal, not an authorization control.

`createShareInvite` must reject a recipient whose marker is absent or below `1` with `recipient-update-required`. This prevents creating an invitation that the recipient's installed app cannot discover or act on. Future incompatible protocol changes must increment the capability version and document server compatibility before rollout.

### List Membership
- Pending invites do not add the recipient to `lists.{listId}.memberIds` or `lists.{listId}.members`.
- Accepting an invite adds the recipient using the existing `ListMember` shape and the currently documented default member permissions. The backend constructs this shape; the client does not submit it.
- Accept, decline, cancel, and auto-accept operations must be idempotent Firebase Function transactions. Invite status, guard state, trusted-sender preference changes, and list membership must not diverge after retries or partial failures.
- Auto-accepted shares from trusted senders may add the recipient directly and must record an `accepted` invite for audit/history in the same atomic operation.
- An accept retry after a successful accept returns success if the same recipient remains a member. A decline/cancel retry returns success when the invite is already in the requested terminal state. Conflicting terminal transitions return a typed `invite-already-resolved` error and never alter membership.
- Acceptance must re-read the list and verify it still exists. It must reject acceptance if the recipient is already a member through an unrelated operation, if the invite is expired, or if the list is deleted. Deleted-list and expired-invite handling must transition the invite to `expired` and release the guard transactionally.

## Query and Index Requirements
- Recipient pending invites: `recipientId == currentUserId` and `status == pending`, ordered by `createdAt desc`.
- Pending invites for list management: the backend queries `listId == targetListId` and `status == pending` only after verifying current share permission. Sender/list-management invite queries are not issued directly by Flutter.
- Duplicate prevention uses the required `/activeShareInvites/{guardId}` transaction described above. Query-then-create without the guard is forbidden.
- Trusted sender lookup: `createShareInvite` checks only `/users/{recipientId}/trustedShareSenders/{senderId}` on the backend before deciding whether to create a pending invite or auto-accept.
- Add Firestore indexes for invite recipient/status/date and list/sender/status queries as needed.

## State Management Requirements
- Add repository/service methods for creating, canceling, accepting, declining, and observing share invites.
- Expose pending recipient invites through Riverpod providers/view models.
- Existing list streams should continue to show only lists where the user is an active member.
- Share-related UI must map the defined backend error codes to user-friendly messages and recovery actions.

## Security Rules Requirements
- Existing `../baskit-server/firestore.rules` list membership permissions currently allow members with `share` permission to mutate `members`/`memberIds` directly. Before invite enforcement is enabled, rules must deny all client membership additions. Only the Firebase Admin SDK in the callable backend may add members. Rules may continue to allow separately validated self-removal and owner/member-removal flows, but those rules must prove that no UID was added and that the owner remains present in both membership fields.
- Only non-anonymous, Google-authenticated users can create share invites; Firebase anonymous guest sessions are not sufficient for cloud sharing.
- A sender can create invites only through the callable backend and only for lists where they currently have share permission.
- Firestore rules deny client writes to invite and guard collections. The backend sets and validates all invite fields.
- Allowed status transitions must be explicit: `pending -> accepted` or `pending -> declined` by the recipient before `expiresAt`, `pending -> canceled` by the sender or an authorized list sharer/owner, and `pending -> expired` by trusted backend cleanup after `expiresAt`. Pending invites at or after `expiresAt` cannot be accepted even if cleanup has not run yet.
- A recipient can read invites addressed to their UID.
- Senders can read/cancel pending invites they created; owners and authorized list sharers can read/cancel pending invites for lists they can share/manage.
- Only the recipient can accept or decline their invite.
- Trusted-sender documents can be listed only by the recipient user under their own `/users/{userId}/trustedShareSenders/{senderId}` path. Creation through `Always accept from this person` is performed by the backend in the acceptance transaction, and deletion is performed through `removeTrustedShareSender`. All direct client writes are denied.
- Membership activation for a new recipient is performed only by the backend after an accepted invite or a transactionally verified trusted-sender lookup. Owners and authorized sharers may initiate or cancel invites, but cannot directly add recipients to `memberIds`/`members` from a client.
- Pending invite documents must not grant list/item read access by themselves.
- `/activeShareInvites` is backend-only: deny every client read and write.
- Recipient invite queries are allowed only when constrained by `recipientId == request.auth.uid`. Sender and list-management invite views must use an authenticated backend endpoint that checks current list permission before returning data; do not grant broad client queries over other recipients' invites.
- Add Firestore Rules emulator tests proving that anonymous users, arbitrary authenticated users, senders, recipients, owners, and sharers cannot bypass these invariants.

## Expiration and Recovery

- Deploy a scheduled Firebase Function that processes pending invites with `expiresAt <= now` in bounded, paginated batches. Each invite is expired and its guard released in a transaction.
- Run cleanup at least hourly. Record processed, repaired, failed, and remaining counts; retry transient failures on the next run.
- Correctness must not depend on the schedule. `createShareInvite`, `acceptShareInvite`, `declineShareInvite`, and `cancelShareInvite` must detect expired state and perform lazy transactional expiration/repair before returning.
- Recipient queries may fetch `status == pending`, but the client must hide entries whose `expiresAt <= its current clock` and refresh from the backend. The backend clock remains authoritative for every action.
- A stale guard, missing invite, missing guard, or guard/invite mismatch must produce structured diagnostic logging and be repaired transactionally when ownership can be proven. Ambiguous corruption must fail closed and alert; it must never grant membership.
- Configure Firestore TTL for historical terminal invite deletion only if audit-retention requirements permit it. TTL is not the active expiration mechanism because TTL deletion timing is not guaranteed and must never control authorization or guard release.

## Migration and Compatibility
- Existing active shared members remain active; do not require retroactive acceptance.
- Existing direct-share flows should be updated to the invite path for new shares.
- Rollout must never preserve an insecure direct-membership path merely for old clients. App-version claims, custom headers, and client code are not authorization boundaries and must not be used to bypass invite approval.
- Add a backend-controlled Remote Config/feature flag for showing invite UI and routing supported clients to callable functions. This flag controls rollout UX only; it never relaxes authorization.
- Release invite-capable clients first with the feature disabled. Verify adoption and backend readiness. Then deploy functions, indexes, scheduled cleanup, monitoring, and tested rules. Enable invite UI only after all dependencies are healthy.
- When enforcement rules are activated, old clients attempting direct share will receive permission denied. Existing share error mapping must turn this into an explicit update-required message. Silent failure and generic failure are release blockers.
- Recipients on old app versions do not have an invite inbox, so the backend must not create an invite until their `shareInvitesVersion` capability is at least `1`. The sender receives a clear message that the recipient must update and open Baskit before they can be invited.
- Existing members retain list read/write access according to their permissions. Enforcement changes only membership additions; it must not remove members or block ordinary list/item operations.
- Guest/local-only users and Firebase anonymous users cannot send or receive cloud share invites until upgraded to a non-anonymous authenticated account.
- Pending invites use `expiresAt = createdAt + 30 days`, calculated from the backend clock.
- If an invite references a deleted list, acceptance returns `list-not-found`, transitions the invite to `expired`, and releases its guard in the same transaction.

## Deployment, Monitoring, and Rollback Gates

Deployment order is mandatory:
1. Deploy required composite indexes and wait until they are built.
2. Deploy callable functions and scheduled cleanup with invite UI disabled.
3. Deploy additive read rules and Rules emulator tests; keep invite UI disabled while legacy membership additions remain possible.
4. Release the invite-capable app and verify update-required error handling on an old-client fixture.
5. Tighten Firestore rules to deny every client membership addition.
6. Enable invite creation for a small internal cohort and monitor function errors, transaction contention, duplicate guards, and notification/inbox discoverability, then expand the cohort gradually.
7. Enable generally only after the acceptance tests and operational thresholds pass.

Required monitoring:
- callable success/error/latency counts by operation and typed error code;
- pending and overdue invite counts;
- stale/missing/mismatched guard repair counts;
- transaction retry and contention rates;
- direct membership-addition permission denials, to measure old-client use and bypass attempts;
- alerts for cleanup failures, overdue pending growth, invariant corruption, and sustained function error-rate increases.

Rollback must fail safe. Disable invite creation through the server-side feature flag and leave invite acceptance/decline/cancel plus cleanup available. Do not restore direct client membership additions. If functions are unhealthy, show a temporary-unavailable message and preserve pending state for retry.

Implementation is not ready for production until the app and server changes are reviewed together, deployed to a Firebase emulator/staging project, and the security and concurrency tests pass.

## Acceptance Criteria
- Given a non-anonymous Google-authenticated owner invites an existing user who has not trusted them, the recipient is not added to the list until they accept.
- Given a non-owner member with share permission invites an existing user, the invite path is allowed and the recipient is not added until acceptance.
- Given a member without share permission tries to invite an existing user, invite creation is denied.
- Given an owner or sharer tries to directly add an untrusted recipient to `memberIds`/`members`, the write is rejected unless it is part of an accepted invite or trusted-sender auto-accept operation.
- Given a recipient accepts an unexpired invite, the list appears in their lists and they receive default member permissions.
- Given a recipient tries to accept an invite at or after `expiresAt`, acceptance fails and the recipient does not gain list/item access.
- Given a recipient declines an invite, the list does not appear and the sender no longer sees it as actionable pending access.
- Given a sender or authorized list sharer/owner cancels an invite, the recipient cannot accept it and does not gain list/item access.
- Given a recipient chooses `Always accept from this person`, future shares from that sender are accepted without a manual prompt.
- Given a recipient removes a trusted sender, subsequent shares from that sender require approval again.
- Given a pending invite exists, creating another invite for the same list and recipient is prevented even under concurrent send attempts.
- Given a pending invite exists, the recipient cannot read list items until acceptance.
- Given a user is running a previously released app version during rollout, sharing behavior remains compatible or fails with a clear update-required message rather than silently dropping or hiding the share.
- Given accept or auto-accept succeeds, invite status and list membership are updated together; retries do not create duplicate members or inconsistent invite state.
- Given a modified or old client attempts to add a member directly, Firestore rules reject it regardless of reported app version.
- Given two concurrent create requests target the same list and recipient, exactly one active invite/audit outcome exists and both callers receive deterministic results.
- Given trust removal races with auto-accept, the backend transaction serializes the writes; the share is auto-accepted only if trust exists in the successful transaction snapshot.
- Given cleanup is delayed, expired invitations still cannot be accepted and a new invite can repair/replace the stale guard safely.
- Given the feature is rolled back, new invites stop while existing recipients can still accept/decline and scheduled cleanup continues.
- Tests cover invite creation, duplicate prevention, accept, decline, cancel, trusted-sender auto-accept, bypass prevention for direct member writes, and security-rule expectations where test infrastructure supports them.
- Server tests cover authentication-provider enforcement, App Check enforcement, field spoofing, every allowed and forbidden status transition, transaction retries, trust-removal races, expiration boundary conditions using the backend clock, deleted lists/users, stale guard repair, and idempotency.
