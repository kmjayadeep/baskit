# Quick-Add Commonly Used Items

> **Status:** Spec | **Date:** 2026-06-11

## Problem

Inside a list, adding items requires typing the full name every time. Regular lists (e.g., "Weekly Groceries") get the same items over and over — Milk, Eggs, Bread. Users shouldn't have to retype them every trip.

## Solution

Two complementary features, both derived from existing list data (no new infrastructure):

### Feature A: Quick-Add Chips
A row of tappable chips below the add-item form, showing the 4–5 most frequently added items for **this specific list**. Tap a chip → item added instantly (quantity left empty).

```
┌──────────────────────────────────────┐
│  Add item: [______________] [Qty]  [Add] │
│  Quick add: [Milk] [Eggs] [Bread] [Butter] │
└──────────────────────────────────────┘
```

**Selection logic**: Count item name occurrences across all items ever added to this list (both active and completed), ordered by frequency desc, capped at 5.

### Feature B: Re-add from Completed Items
Each completed item card gets a small `+` icon on the trailing edge. Tap it → re-added as a new active item (reset to incomplete). No confirmation, no undo — just a quick repurchase.

```
Completed (3)
┌─────────────────────────────────┐
│ ✓ Milk       1 gal         [+] │
│ ✓ Eggs       1 dozen       [+] │
│ ✓ Bread      1 loaf        [+] │
└─────────────────────────────────┘
```

## Architecture

Both features are **read-only derivations** of existing `ShoppingList.items` — no new storage, no new models, no migrations.

- **Chips**: `ShoppingList` gets a new UI extension getter `frequentItemNames` that counts item name frequency.
- **Re-add**: The `ItemCardWidget` gets an optional `onReAdd` callback. `CompletedItemsSection` passes it through. The `list_detail_screen` wires it to call the same `_addItem` flow (without quantity).

## Scope & Non-Goals

**In scope:**
- Quick-add chips for the currently viewed list only (not cross-list)
- Re-add button on completed item cards
- Both respect the existing `_hasPermission('write', list)` guard

**Out of scope:**
- Cross-list item history (would need new storage)
- Quantity memory ("Milk" always adds "1 gal")
- Template-based quick-add (already exists at list-creation level)

## Tasks

### Task 1: Add `frequentItemNames` extension getter

**File:** `app/lib/extensions/shopping_list_extensions.dart`

Add a getter to `ShoppingListUI` that returns the top 5 most frequent item names:

```dart
/// Get the 5 most frequently added item names (across active + completed)
List<String> get frequentItemNames {
  final counts = <String, int>{};
  for (final item in items) {
    counts[item.name] = (counts[item.name] ?? 0) + 1;
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(5).map((e) => e.key).toList();
}
```

### Task 2: Add `frequentItemNames` unit test

**File:** `app/test/extensions/shopping_list_extensions_test.dart` (new)

Test: list with "Milk" (3 times), "Eggs" (2), "Bread" (1) → returns `["Milk", "Eggs", "Bread"]`. Empty list → empty. Single item → that item.

### Task 3: Build `QuickAddChips` widget

**File:** `app/lib/screens/list_detail/widgets/quick_add_chips_widget.dart` (new)

```dart
class QuickAddChips extends StatelessWidget {
  final List<String> itemNames;
  final bool enabled;
  final ValueChanged<String> onItemTap;

  // Renders a horizontal Wrap of ActionChip widgets.
  // Each chip shows the item name. On tap → onItemTap(name).
  // When enabled=false, chips are greyed out and non-interactive.
}
```

Design:
- `Wrap` with 8px spacing
- `ActionChip` with `avatar: Icon(Icons.add, size: 14)`
- Respects `enabled` (tied to `isAddingItem` + permissions)
- Only renders when `itemNames.isNotEmpty`

### Task 4: Add `QuickAddChips` widget test

**File:** `app/test/screens/list_detail/widgets/quick_add_chips_widget_test.dart` (new)

Tests:
- Renders chips for each item name
- Tapping a chip calls `onItemTap` with the correct name
- When `enabled=false`, chips are not tappable
- When `itemNames` is empty, renders nothing

### Task 5: Add `onReAdd` callback to `ItemCardWidget`

**File:** `app/lib/screens/list_detail/widgets/item_card_widget.dart`

- Add optional `VoidCallback? onReAdd` parameter
- When provided and item is completed, show a small `IconButton(Icons.add_circle_outline)` on the trailing edge
- Button respects the item's `isProcessing` state

### Task 6: Update `ItemCardWidget` tests for re-add

**File:** `app/test/screens/list_detail/widgets/item_card_widget_test.dart`

- Test that re-add button appears when `onReAdd` is provided and item is completed
- Test that re-add button does NOT appear for active items
- Test that tapping re-add calls the callback

### Task 7: Wire quick-add chips into `list_detail_screen`

**File:** `app/lib/screens/list_detail/list_detail_screen.dart`

In the `build` method, after the `AddItemWidget`, insert:

```dart
if (_hasPermission('write', list)) ...[
  QuickAddChips(
    itemNames: list.frequentItemNames,
    enabled: !state.isAddingItem,
    onItemTap: (name) {
      _addItemController.text = name;
      _addItem(list);
    },
  ),
],
```

### Task 8: Wire re-add into completed items section

**File:** `app/lib/screens/list_detail/list_detail_screen.dart`

Pass `onReAdd` to `CompletedItemsSection` which passes it to each `ItemCardWidget`:

```dart
CompletedItemsSection(
  completedItems: completedItems,
  processingItems: state.processingItems,
  onReAdd: _hasPermission('write', list)
      ? (item) {
          _addItemController.text = item.name;
          _addQuantityController.text = item.quantity ?? '';
          _addItem(list);
        }
      : null,
  // ... existing callbacks
)
```

**Files also touched:**
- `app/lib/screens/list_detail/widgets/completed_items_section_widget.dart` — add `onReAdd` param, pass to `ItemCardWidget`

### Task 9: Respect permissions in `CompletedItemsSection`

Ensure `onReAdd` is null-checked before rendering the button — read-only viewers see no re-add button.

### Task 10: Run full test suite and verify

```bash
cd app && flutter test
flutter analyze
flutter build web
```

All existing tests must pass. New widget + extension tests must pass.

## Verification

- **Chips appear**: Open a list with 3+ items of the same name → chips render below add form
- **Chips add**: Tap a chip → item added, input cleared
- **Chips disabled**: While an item is being added (`isAddingItem=true`), chips are greyed out
- **Re-add visible**: Open a list with completed items → each shows a `+` icon
- **Re-add works**: Tap `+` on a completed item → new active item appears with same name+quantity
- **Read-only**: View a shared list without write permission → no chips, no re-add icons
