# Plan: "Have at Home" Page

## Problem

Users currently add items they intend to buy. Many shopping-list users also track things they **already have at home** — they want to see them at a glance, mark them as "finished" as they're used, and have used-up items surface in a "Run-Out" list (useful for restocking decisions).

Baskit currently has no separate concept for "items I already own" vs "items I need to get".

## Solution Overview

Add a new **"Have at Home"** tab on the `ListDetailScreen`. Each list gains two parallel item collections:

- **Have at Home** — items the user already possesses in their pantry/fridge/cupboard
- **Run-Out** — items previously marked as "Finished" (used up)

A `ShoppingItem` gets a `listItemType` field to distinguish between `needs_purchase` (default), `have_at_home`, and `run_out`.

---

## Data Model Changes

### `ShoppingItem` (`lib/models/shopping_item_model.dart`)

Add one field:

```dart
@HiveField(5) // shift existing fields down
final ItemType listItemType; // default: ItemType.needsPurchase
```

New enum:

```dart
enum ItemType {
  needsPurchase, // default — goes to main pending/completed buckets
  haveAtHome,    // user already has it at home
  runOut,        // was haveAtHome, user marked "Finished"
}
```

**Migration:** Existing items default to `ItemType.needsPurchase` (Hive auto-fills enum default = first value). Add a migration in `migration_service.dart` that iterates existing items and sets `listItemType = needsPurchase` explicitly.

Update `fromJson` / `fromJsonSafe` / `toJson` / `copyWith` accordingly. Bump `HiveType` field indices or add a new typeId version.

### Firestore schema (`lib/services/firestore_mappers.dart`)

Add `listItemType` mapping (stored as string: `'needs_purchase'`, `'have_at_home'`, `'run_out'`). Update upsert logic in `firestore_item_crud_service.dart` to persist this field.

### Repository interface (`lib/repositories/shopping_repository.dart`)

No interface changes needed — `updateItem` already supports `name`, `quantity`, `completed` flags. Add an optional `ItemType? listItemType` parameter.

---

## ViewModel Changes

### `ListDetailViewModel` (`lib/screens/list_detail/view_models/list_detail_view_model.dart`)

Add methods:

```dart
Future<ActionResult> addItemToHaveAtHome(String itemName, String? quantity)
Future<ActionResult> finishHaveAtHomeItem(ShoppingItem item)
Future<ActionResult> markBackToHaveAtHome(ShoppingItem item)
```

- `addItemToHaveAtHome` — creates a `ShoppingItem` with `listItemType: ItemType.haveAtHome`, `isCompleted: false`
- `finishHaveAtHomeItem` — changes `listItemType: ItemType.runOut`, sets `completedAt: DateTime.now()`
- `markBackToHaveAtHome` — reverts a run-out item back to `haveAtHome`

Update `toggleItemCompletion` to **not affect** `haveAtHome` or `runOut` items (or add guard).

Update `clearCompletedItems` to **exclude** `runOut` items (or handle separately).

### State (`ListDetailState`)

No new state fields needed — the UI reads directly from the `ShoppingList` items stream and filters by `listItemType`.

---

## Screen / Widget Changes

### `ListDetailScreen` (`lib/screens/list_detail/list_detail_screen.dart`)

Add a `TabBar` above the existing scroll view with 2 tabs:

1. **"Have at Home"** — shows only `haveAtHome` items that are not completed
2. **"Shopping List"** (existing) — shows `needsPurchase` pending + completed items

The existing `AddItemWidget` appears only on the "Shopping List" tab (current behavior). Add a separate "Add to Have at Home" row on the "Have at Home" tab that reuses `AddItemWidget` with a modified `onAddItem` handler that calls `addItemToHaveAtHome`.

### Filtering logic

In `build()`, compute:

```dart
final pendingItems = sortedItems.where((item) => !item.isCompleted && item.listItemType == ItemType.needsPurchase).toList();
final completedItems = sortedItems.where((item) => item.isCompleted && item.listItemType == ItemType.needsPurchase).toList();
final haveAtHomeItems = sortedItems.where((item) => item.listItemType == ItemType.haveAtHome).toList();
final runOutItems = sortedItems.where((item) => item.listItemType == ItemType.runOut).toList();
```

### Item card rendering

The existing `ListItemsScrollView` / `ShoppingItemCard` needs updates:

- **Have at Home items:** show a **"Finished"** button (outlined, amber or green) next to the standard checkbox
- **Run-Out items:** show in a separate collapsed section below "Have at Home" with an option to **"Move back"** (to Have at Home) or **"Delete"**

---

## Widget Breakdown

| Widget | New? | Purpose |
|--------|------|---------|
| `TabBar` with "Have at Home" / "Shopping" tabs | New | Navigation between the two views |
| `HaveAtHomeAddItemRow` | New | Reuses `AddItemWidget` logic for adding to "Have at Home" |
| `HaveAtHomeItemCard` | New (extract) | Item card variant with "Finished" button |
| `RunOutSection` | New | Collapsible section showing run-out items |
| `RunOutItemCard` | New (extract) | Item card variant with "Move back" / "Delete" |
| `ShoppingItemCard` | Modified | Add `listItemType` awareness |

---

## Permission / Security

- Same permission model as existing items — `ListPermission.write` controls add/finish/mark-back
- `Run-Out` items are editable by anyone with write permission
- Share flow unaffected

---

## Sorting

`ItemSorter` needs a `listItemType` sort key so that within each tab, items sort consistently (newest first by default, but preserve existing sort options).

---

## Firestore Query Updates

The existing `watchList` fetches all items for a list. Since items are stored per-list, no additional Firestore indexes are needed. The `runOut` items are already in the list document, just filtered by `listItemType`.

If lists grow very large (>1000 items), consider:
- Storing `runOut` items in a subcollection instead
- Adding Firestore array-bundle queries for `listItemType` filters

For now, keep everything in the `items` array.

---

## Migration Plan

1. **Phase 1 — Data model**
   - Add `ItemType` enum
   - Update `ShoppingItem` model + `fromJson`/`toJson`/`copyWith`
   - Run Hive migration in `migration_service.dart`
   - Update Firestore mappers
   - Regenerate `build_runner` for `.g.dart`

2. **Phase 2 — ViewModel**
   - Add `addItemToHaveAtHome`, `finishHaveAtHomeItem`, `markBackToHaveAtHome`
   - Update `toggleItemCompletion` guard
   - Update `clearCompletedItems` guard
   - Add tests

3. **Phase 3 — UI**
   - Add tab bar to `ListDetailScreen`
   - Extract `HaveAtHomeItemCard` and `RunOutSection`
   - Wire up `AddItemWidget` for "Have at Home" tab
   - Add tests

4. **Phase 4 — Polish**
   - Haptic feedback on finish
   - Snackbar messages
   - E2E / integration test
   - Design review (colors, spacing, icons)

---

## Risks & Trade-offs

| Risk | Mitigation |
|------|-----------|
| Hive migration for existing users | Use Hive's `onOpen` callback; add version field; first open runs migration |
| Firestore sync — `listItemType` not understood by older app versions | Field is additive; older clients ignore unknown fields. Gradual rollout |
| Tab UI complexity | Start with 2 tabs only; "Run-Out" is a collapsible section within "Have at Home" tab |
| Shopping list items could accidentally be marked "have at home" | Separate add flows prevent confusion |

---

## Acceptance Criteria

- [ ] User can add an item to "Have at Home" from a dedicated input row on the "Have at Home" tab
- [ ] Optional quantity field works (same as existing add-item widget)
- [ ] Each "Have at Home" item has a visible "Finished" button
- [ ] Tapping "Finished" moves the item to "Run-Out" with a timestamp
- [ ] Run-Out items appear in a collapsible section below active Have at Home items
- [ ] Run-Out items can be "moved back" to Have at Home or deleted
- [ ] Existing Shopping List flow is unchanged (no regression)
- [ ] Works with both Hive-only and Hive+Firestore modes
- [ ] All existing tests pass + new tests for new functionality
