import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

enum ItemsSortOption {
  status('Status', Icons.check_circle_outline),
  name('Name', Icons.sort_by_alpha),
  newest('Newest', Icons.schedule),
  oldest('Oldest', Icons.history);

  final String label;
  final IconData icon;

  const ItemsSortOption(this.label, this.icon);
}

/// Header for the items section with count and sort controls.
class ItemsHeaderWidget extends StatelessWidget {
  final int itemsCount;
  final ItemsSortOption selectedSort;
  final ValueChanged<ItemsSortOption> onSortChanged;

  const ItemsHeaderWidget({
    super.key,
    required this.itemsCount,
    required this.selectedSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Items ($itemsCount)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<ItemsSortOption>(
            tooltip: 'Sort items',
            initialValue: selectedSort,
            onSelected: onSortChanged,
            itemBuilder:
                (context) =>
                    ItemsSortOption.values.map((option) {
                      return PopupMenuItem<ItemsSortOption>(
                        value: option,
                        child: Row(
                          children: [
                            Icon(option.icon, size: 18),
                            const SizedBox(width: 10),
                            Text(option.label),
                          ],
                        ),
                      );
                    }).toList(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort, size: 18),
                const SizedBox(width: 6),
                Text(selectedSort.label),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
