# Baskit PRD - Overview

## Product Goal
Build a collaborative shopping list app with a guest-first experience: users can fully use the app offline without accounts, then upgrade to cloud sync and sharing via Google Sign-In.

## Platforms
- Mobile: Android, iOS
- Web: Flutter web
- Desktop: Windows, macOS, Linux

## Core Screens
1. **Lists**: shows all lists, empty state, create list CTA
2. **List Detail**: items, add item, edit item, share list, member list
3. **List Form**: create/edit list (name, description, color)
4. **Profile**: account status, Google sign-in/out, account benefits

## Core User Flows
1. **Guest usage**: install → create lists/items → offline usage
2. **Upgrade to cloud**: guest → Google Sign-In → migrate local lists → sync
3. **Sharing**: owner shares list with another user by email → member access
4. **Item lifecycle**: add → edit → complete → clear completed
5. **Delete list**: owner-only deletion with confirmation

## Functional Requirements
- Users can create, edit, and delete shopping lists
- Users can add, edit, complete, and delete items in a list
- Lists support a color palette and description
- Lists can be shared with other users by email (cloud users only)
- Permissions restrict read/write/delete/share actions for list members
- Contact suggestions appear in the share dialog when available
- App supports offline-first behavior in all modes
- App shows a "What's New" dialog after upgrades

## Non-Functional Requirements
- Fast local CRUD (Hive)
- Minimal network use for guests
- Resilient migration (no data loss)
- UI handles loading/empty/error states
