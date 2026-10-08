import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/shopping_list_model.dart';

/// UI-specific extensions for ShoppingList
///
/// This extension contains all UI-related helper methods
extension ShoppingListUI on ShoppingList {
  /// Get the display color for this list by parsing the hex color string
  ///
  /// Supports both 6-character (RRGGBB) and 7-character (#RRGGBB) hex strings.
  /// Automatically adds an alpha channel (FF) for 6- and 7-character strings.
  /// Returns [AppColors.primaryGreen] if parsing fails.
  Color get displayColor {
    try {
      final buffer = StringBuffer();
      if (color.length == 6 || color.length == 7) buffer.write('ff');
      buffer.write(color.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return AppColors.primaryGreen; // Default color if parsing fails
    }
  }

  /// Get completion progress as a value between 0.0 and 1.0 for UI progress indicators
  double get completionProgress =>
      totalItemsCount == 0 ? 0.0 : completedItemsCount / totalItemsCount;

  /// Get appropriate sharing icon based on shared member count
  IconData get sharingIcon {
    if (sharedMemberCount == 0) {
      return Icons.lock;
    } else if (sharedMemberCount == 1) {
      return Icons.person;
    } else {
      return Icons.group;
    }
  }

  /// Get the 5 most frequently added item names across all items
  /// (active + completed), excluding names already in the active list.
  /// Used for quick-add chips.
  List<String> get frequentItemNames {
    final activeNames = items
        .where((item) => !item.isCompleted)
        .map((item) => item.name)
        .toSet();

    final counts = <String, int>{};
    for (final item in items) {
      counts[item.name] = (counts[item.name] ?? 0) + 1;
    }

    final sorted = counts.entries
        .where((e) => !activeNames.contains(e.key))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) => e.key).toList();
  }
}
