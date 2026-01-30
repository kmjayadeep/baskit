# Baskit PRD - UI & Assets

## Theme Requirements
- Material 3 enabled
- Light theme is the default
- App bar centered, cards with rounded corners
- Input fields use filled backgrounds

## List UI Requirements
- Lists show name, description, item counts, and member sharing hints
- Empty state when no lists exist
- Create list CTA always visible

## List Detail Requirements
- Header shows list metadata and share controls
- Add item input with optional quantity
- Items show name, quantity, completion state
- Completed items are visually separated
- Clear completed action available when permitted

## Sharing UI Requirements
- Share dialog only for authenticated users
- Contact suggestions list appears in share flow
- Member list dialog shows roles and permissions

## Profile UI Requirements
- Display account status (local-only, guest, Google)
- Sign-in CTA for guests
- Sign-out CTA for authenticated users
- Show email and display name when available

## What's New
- On app update, show a dialog with changelog items
- Content is read from `assets/whats_new/latest.json` only
- Dialog only shows for the current app version
- Do not show on first install

## Asset Requirements
- `assets/icon.png` used in README and branding
- Launcher icons generated from `assets/icon/icon.png`
- Web icons stored in `app/web/icons/`
- Feature image stored at `assets/feature.jpeg`
