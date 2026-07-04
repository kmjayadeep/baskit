import '../../../models/shopping_item_model.dart';
import '../widgets/items_header_widget.dart';

class ItemSorter {
  const ItemSorter._();

  static List<ShoppingItem> sort(
    Iterable<ShoppingItem> items,
    ItemsSortOption option,
  ) {
    final sortedItems = [...items];

    int byName(ShoppingItem a, ShoppingItem b) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }

    sortedItems.sort((a, b) {
      return switch (option) {
        ItemsSortOption.name => _then(
          byName(a, b),
          () => a.createdAt.compareTo(b.createdAt),
        ),
        ItemsSortOption.newest => _then(
          b.createdAt.compareTo(a.createdAt),
          () => byName(a, b),
        ),
        ItemsSortOption.oldest => _then(
          a.createdAt.compareTo(b.createdAt),
          () => byName(a, b),
        ),
      };
    });

    return sortedItems;
  }

  static int _then(int firstComparison, int Function() nextComparison) {
    return firstComparison != 0 ? firstComparison : nextComparison();
  }
}
