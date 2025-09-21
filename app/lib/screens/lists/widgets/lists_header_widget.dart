import 'package:flutter/material.dart';

/// A header widget that displays the lists count and a "New List" button
///
/// Provides a consistent header layout showing the number of lists and
/// offering quick access to create a new list.
class ListsHeaderWidget extends StatelessWidget {
  /// The number of lists to display in the title
  final int listsCount;

  /// Callback function executed when the "New List" button is pressed
  final VoidCallback onCreateList;

  const ListsHeaderWidget({
    super.key,
    required this.listsCount,
    required this.onCreateList,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Your Lists ($listsCount)',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: onCreateList,
          icon: const Icon(Icons.add),
          label: const Text('New List'),
        ),
      ],
    );
  }
}
