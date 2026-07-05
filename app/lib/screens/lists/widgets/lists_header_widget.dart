import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

enum ListsSortOption {
  recent('Recent', Icons.schedule),
  name('Name', Icons.sort_by_alpha),
  progress('Progress', Icons.trending_up),
  items('Items', Icons.format_list_numbered);

  final String label;
  final IconData icon;

  const ListsSortOption(this.label, this.icon);
}

/// A header widget that displays the lists count and sort options.
///
/// Provides a consistent header layout showing the number of lists and the
/// current sort option for non-empty list collections.
class ListsHeaderWidget extends StatelessWidget {
  /// The number of lists to display in the title
  final int listsCount;

  /// Currently selected sort option.
  final ListsSortOption selectedSort;

  /// Callback function executed when a sort option is selected.
  final ValueChanged<ListsSortOption> onSortChanged;

  const ListsHeaderWidget({
    super.key,
    required this.listsCount,
    required this.selectedSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Your Lists ($listsCount)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (listsCount > 0)
          PopupMenuButton<ListsSortOption>(
            tooltip: 'Sort lists',
            initialValue: selectedSort,
            onSelected: onSortChanged,
            itemBuilder: (context) => ListsSortOption.values.map((option) {
              return CheckedPopupMenuItem<ListsSortOption>(
                value: option,
                checked: option == selectedSort,
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
    );
  }
}
