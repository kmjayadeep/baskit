import 'package:flutter/material.dart';
import '../models/shopping_list_model.dart';
import '../models/shopping_item_model.dart';

/// UI-specific extensions for ShoppingList
///
/// This extension contains all UI-related helper methods that were previously
/// in the ShoppingList model. By separating UI logic from domain models,
/// we maintain clean architecture while preserving functionality.
extension ShoppingListUI on ShoppingList {
  /// Get the display color for this list by parsing the hex color string
  ///
  /// Supports both 6-character (#RRGGBB) and 7-character (#RRGGBB) hex strings.
  /// Automatically adds alpha channel (FF) for 6-character strings.
  /// Returns default blue color if parsing fails.
  Color get displayColor {
    try {
      final buffer = StringBuffer();
      if (color.length == 6 || color.length == 7) buffer.write('ff');
      buffer.write(color.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.blue; // Default color if parsing fails
    }
  }

  /// Get completion progress as a value between 0.0 and 1.0 for UI progress indicators
  double get completionProgress =>
      totalItemsCount == 0 ? 0.0 : completedItemsCount / totalItemsCount;

  /// Get items sorted by completion status (incomplete first, completed last)
  /// Within each group, items are sorted by creation time (oldest first)
  ///
  /// This is UI-specific sorting for display purposes.
  List<ShoppingItem> get sortedItems {
    return [...items]..sort((a, b) {
      // Incomplete items first, completed items last
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      // Within each group, maintain original order (by creation time)
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  /// Get appropriate sharing status text based on member count
  String get sharingText {
    // Note: list.members contains display names, not IDs
    // Current user's name is not included in members
    if (members.isEmpty) {
      return 'Private';
    } else if (members.length == 1) {
      return 'Shared with ${members[0]}';
    } else if (members.length == 2) {
      return 'Shared with ${members[0]} and ${members[1]}';
    } else {
      return 'Shared with ${members.length} people';
    }
  }

  /// Get appropriate sharing icon based on member count
  IconData get sharingIcon {
    if (members.isEmpty) {
      return Icons.lock;
    } else if (members.length == 1) {
      return Icons.person;
    } else {
      return Icons.group;
    }
  }
}
