# Baskit PRD - List Member Avatars on Lists Page

## Purpose
Improve the Lists page by replacing the shared-member count chip with a compact visual stack of member profile pictures. The goal is to make shared lists feel more personal and quickly communicate who has access without requiring the user to open list details.

## Problem
List cards currently show a generic sharing icon and a numeric member count for shared lists. This communicates quantity but not identity, and it underuses the rich `ListMember` data already available on `ShoppingList.members`, including `displayName` and `avatarUrl`.

## Goals
- Show shared members as overlapping circular avatars on each shared list card.
- Preserve the existing private-list state for lists that are not shared.
- Provide graceful fallbacks when a member has no profile picture.
- Keep list cards compact, readable, and accessible.

## Non-Goals
- Do not add member management actions to the Lists page.
- Do not change sharing permissions, Firestore schema, or invite flows.
- Do not fetch extra profile data from the list card; use member data already present on `ShoppingList`.

## UX Requirements

### Private Lists
- Private lists continue to show a clear `Private` status.
- Private status may keep the current lock/person icon chip treatment or an equivalent Material 3 chip.

### Shared Lists
- Replace the shared numeric count text with an avatar stack.
- The avatar stack should represent list members other than the current user. This means owners see shared members, and non-owner members see the owner/other collaborators rather than themselves.
- Display up to 3 visible member avatars on the list card.
- If there are more than 3 shared members, show a final overflow avatar such as `+2`.
- If a member has `avatarUrl`, display the image in a circular avatar.
- If `avatarUrl` is missing, invalid, or fails to load, display initials derived from `displayName`; if no usable name exists, use a generic person icon.
- Avatars should overlap slightly and include a border or background contrast so each avatar remains visible.
- Tapping the list card should keep opening the list detail page; avatars should not introduce a separate tap target in this phase.

## Accessibility Requirements
- The avatar stack must have a semantic label such as `Shared with Jane, Alex, and 2 others`.
- Avatar image fallbacks must not rely on color alone.
- Text and avatar borders/backgrounds must meet app contrast expectations.

## Data Requirements
- Use existing `ShoppingList.members`, `ShoppingList.sharedMembers`, `ListMember.displayName`, and `ListMember.avatarUrl`.
- Do not persist new fields for this feature.
- New shares should store member `avatarUrl` when the target user's profile has one.
- Existing memberships may be self-healed by copying the signed-in user's current profile `photoURL` into that user's existing `members.{uid}.avatarUrl` entries.
- Handle empty or partially migrated member data safely.

## Acceptance Criteria
- Given a private list, the list card shows `Private` rather than member avatars.
- Given a shared list with 1-3 shared members, the list card shows one circular avatar per shared member.
- Given a shared list with more than 3 shared members, the list card shows 3 avatars plus an overflow `+N` indicator.
- Given a member without a valid profile picture, the list card shows initials or a generic fallback avatar.
- The existing item count, progress bar, completion summary, and card navigation behavior remain unchanged.
- Widget tests cover private, shared, overflow, and missing-avatar fallback states.
