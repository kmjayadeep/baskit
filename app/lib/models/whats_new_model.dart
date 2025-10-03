import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Represents the content for a "What's New" dialog
class WhatsNewContent {
  final String version;
  final String title;
  final List<WhatsNewItem> items;

  const WhatsNewContent({
    required this.version,
    required this.title,
    required this.items,
  });

  /// Load What's New content for a specific version from assets
  ///
  /// Looks for whats_new/{version}.json in the assets folder
  /// Returns null if no content exists for the version
  static Future<WhatsNewContent?> loadForVersion(String version) async {
    try {
      final assetPath = 'whats_new/$version.json';
      final jsonString = await rootBundle.loadString(assetPath);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      return WhatsNewContent.fromJson(json);
    } catch (e) {
      // No content for this version - that's okay
      debugPrint('ℹ️  No What\'s New content found for version $version');
      return null;
    }
  }

  /// Create from JSON
  factory WhatsNewContent.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final items =
        itemsList
            .map((item) => WhatsNewItem.fromJson(item as Map<String, dynamic>))
            .toList();

    return WhatsNewContent(
      version: json['version'] as String? ?? '1.0.0',
      title: json['title'] as String? ?? 'What\'s New',
      items: items,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'version': version,
    'title': title,
    'items': items.map((item) => item.toJson()).toList(),
  };

  /// Check if content has any items
  bool get hasItems => items.isNotEmpty;

  /// Get items by type
  List<WhatsNewItem> getItemsByType(WhatsNewItemType type) {
    return items.where((item) => item.type == type).toList();
  }

  /// Get all feature items
  List<WhatsNewItem> get features => getItemsByType(WhatsNewItemType.feature);

  /// Get all improvement items
  List<WhatsNewItem> get improvements =>
      getItemsByType(WhatsNewItemType.improvement);

  /// Get all bugfix items
  List<WhatsNewItem> get bugfixes => getItemsByType(WhatsNewItemType.bugfix);
}

/// Represents a single item in the What's New dialog
class WhatsNewItem {
  final String title;
  final String description;
  final String iconName;
  final WhatsNewItemType type;

  const WhatsNewItem({
    required this.title,
    required this.description,
    required this.iconName,
    required this.type,
  });

  /// Create from JSON
  factory WhatsNewItem.fromJson(Map<String, dynamic> json) {
    return WhatsNewItem(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconName: json['icon'] as String? ?? 'info',
      type: WhatsNewItemType.fromString(json['type'] as String? ?? 'feature'),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'icon': iconName,
    'type': type.name,
  };

  /// Get the Flutter icon for this item
  IconData get icon {
    switch (iconName.toLowerCase()) {
      // Feature icons
      case 'person_search':
      case 'contact_search':
        return Icons.person_search;
      case 'group':
      case 'people':
        return Icons.group;
      case 'share':
        return Icons.share;
      case 'security':
      case 'shield':
        return Icons.security;
      case 'auto_complete':
      case 'autocomplete':
        return Icons.auto_awesome;

      // Improvement icons
      case 'speed':
      case 'fast':
        return Icons.speed;
      case 'design':
      case 'palette':
        return Icons.palette;
      case 'accessibility':
        return Icons.accessibility;
      case 'mobile':
      case 'phone':
        return Icons.phone_android;

      // Bug fix icons
      case 'bug_fix':
      case 'bug':
        return Icons.bug_report;
      case 'fix':
      case 'build':
        return Icons.build;
      case 'stable':
      case 'verified':
        return Icons.verified;

      // General icons
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'thumb_up':
        return Icons.thumb_up;
      case 'celebration':
        return Icons.celebration;
      case 'new':
      case 'fiber_new':
        return Icons.fiber_new;
      case 'update':
        return Icons.update;
      case 'info':
      default:
        return Icons.info;
    }
  }

  /// Get the color for this item type
  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case WhatsNewItemType.feature:
        return theme.primaryColor;
      case WhatsNewItemType.improvement:
        return Colors.orange;
      case WhatsNewItemType.bugfix:
        return Colors.green;
    }
  }

  /// Get the emoji for this item type
  String get emoji {
    switch (type) {
      case WhatsNewItemType.feature:
        return '✨';
      case WhatsNewItemType.improvement:
        return '🚀';
      case WhatsNewItemType.bugfix:
        return '🛠️';
    }
  }
}

/// Types of What's New items
enum WhatsNewItemType {
  feature,
  improvement,
  bugfix;

  /// Create from string
  static WhatsNewItemType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'feature':
      case 'new':
        return WhatsNewItemType.feature;
      case 'improvement':
      case 'enhance':
      case 'enhancement':
        return WhatsNewItemType.improvement;
      case 'bugfix':
      case 'fix':
      case 'bug':
        return WhatsNewItemType.bugfix;
      default:
        return WhatsNewItemType.feature;
    }
  }

  /// Get display name
  String get displayName {
    switch (this) {
      case WhatsNewItemType.feature:
        return 'New Feature';
      case WhatsNewItemType.improvement:
        return 'Improvement';
      case WhatsNewItemType.bugfix:
        return 'Bug Fix';
    }
  }
}
