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
- Member list dialog shows roles and current-user indicators (`You` chip/label)
- Member list dialog includes `Invite More` CTA when sharing callbacks are wired
- Owner-only member removal actions are available in the member dialog (owners cannot remove themselves)
- Non-owner members can leave shared lists via the list-detail overflow menu (`Leave List`)

## Profile UI Requirements
- Display account status (local-only, guest, Google)
- Sign-in CTA for guests
- Sign-out CTA for authenticated users
- Show email and display name when available

## What's New
- Do not show the dialog on first install; store the current version as the baseline
- On app update, show a compact dialog only when curated user-facing highlights exist
- Content is read from versioned curated releases in `assets/whats_new/releases.json`
- For skipped-version updates, combine eligible highlights since the stored baseline, deduplicate related items, and keep the summary capped
- Do not show technical, internal, or non-user-facing release metadata

## Asset Requirements
- `assets/icon.png` used in README and branding
- Launcher icons generated from `assets/icon/icon.png`
- Web icons stored in `app/web/icons/`
- Feature image stored at `assets/feature.jpeg`
