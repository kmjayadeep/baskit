# Baskit UI Revamp Plan

## Goals

- Make Baskit feel like a modern grocery and household-list app instead of a generic task manager.
- Align the app colors with shopping, freshness, and the existing basket identity.
- Improve visual hierarchy, spacing, and action clarity on the list overview and list detail screens.
- Keep the first release focused on the main shopping workflow before expanding to forms, profile, and dialogs.

## Visual Direction

Baskit should feel clean, warm, and practical. The core experience is repeated household use, so the UI should favor readable surfaces, restrained motion, and obvious actions over decorative layouts.

Recommended system:

- Primary: fresh green for app identity and success states.
- Secondary/accent: basket orange for creation and highlights.
- Background: warm off-white instead of cold gray or blue.
- Surfaces: white cards with subtle borders and minimal elevation.
- Progress: list-specific color where useful, with rounded tracks.
- Text: near-black for titles, muted neutral gray for secondary metadata.

## Phase 1: Lists Home And Detail Screen

This is the first release scope.

1. Replace the welcome banner with a compact dashboard summary.
   - Show total lists, total items, and completed items.
   - Use grocery-aligned icons and warm surfaces.
   - Keep the screen useful even when the user already understands the app.

2. Modernize list cards.
   - Use subtle borders instead of heavy shadow.
   - Add a stronger color marker per list.
   - Use rounded progress bars.
   - Convert sharing/private metadata into clear chips.
   - Improve item-count and progress hierarchy.

3. Refresh the list detail header.
   - Use a richer tinted header based on the list color.
   - Improve title, description, progress, and member/status hierarchy.
   - Make the member row look tappable without relying on underlined text.

4. Improve add-item and item-row polish.
   - Use filled, modern input fields.
   - Keep item and quantity entry compact.
   - Use a stronger green action button.
   - Make item rows denser, with clearer checked and completed states.
   - Show quantity as secondary metadata without oversized row height.

## Phase 2: Supporting Screens

- Update create/edit list form styling to match the refreshed card, chip, and input language.
- Refresh empty states across lists and detail screens.
- Improve share/member dialogs with clearer permission language and modern spacing.
- Review profile and account screens for palette and component consistency.

## Phase 3: Interaction Polish

- Add subtle progress and item-state animations where they support comprehension.
- Add swipe actions for common item operations if they test well on mobile.
- Review haptics for item completion and destructive actions.
- Ensure loading, error, offline, and sync states are visible without dominating the UI.

## Design Constraints

- Keep Material 3 conventions and existing Riverpod architecture.
- Prefer small composable widgets over screen-level monoliths.
- Preserve guest-first local storage and sync behavior.
- Do not edit generated `.g.dart` files.
- Verify the release with `flutter analyze` and targeted tests before shipping.
