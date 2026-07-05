import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utilities for comparing app-style semantic versions.
class WhatsNewVersion {
  const WhatsNewVersion._();

  /// Compare two semantic versions.
  ///
  /// Returns a positive number when [a] is newer than [b], a negative number
  /// when [a] is older than [b], and zero when they are equivalent.
  static int compare(String a, String b) {
    final aParts = _numericParts(a);
    final bParts = _numericParts(b);
    final length =
        aParts.length > bParts.length ? aParts.length : bParts.length;

    for (var i = 0; i < length; i++) {
      final aPart = i < aParts.length ? aParts[i] : 0;
      final bPart = i < bParts.length ? bParts[i] : 0;
      if (aPart != bPart) {
        return aPart.compareTo(bPart);
      }
    }

    return 0;
  }

  static List<int> _numericParts(String version) {
    final normalized = version.split('+').first.split('-').first;
    return normalized.split('.').map((part) {
      final match = RegExp(r'^\d+').firstMatch(part.trim());
      return int.tryParse(match?.group(0) ?? '0') ?? 0;
    }).toList();
  }
}

/// Represents computed content for a "What's New" dialog.
class WhatsNewContent {
  final String version;
  final String title;
  final List<WhatsNewItem> items;

  const WhatsNewContent({
    required this.version,
    required this.title,
    required this.items,
  });

  /// Load versioned What's New content from assets and select eligible items.
  static Future<WhatsNewContent?> loadForVersionRange({
    required String lastSeenVersion,
    required String currentVersion,
  }) async {
    final catalog = await WhatsNewReleaseCatalog.loadFromAssets();
    return catalog?.selectHighlights(
      lastSeenVersion: lastSeenVersion,
      currentVersion: currentVersion,
    );
  }

  /// Load What's New content from the versioned releases asset.
  ///
  /// This returns content for all releases up to the current release and exists
  /// only for older call sites/tests. Prefer [loadForVersionRange].
  @Deprecated('Use loadForVersionRange instead.')
  static Future<WhatsNewContent?> loadLatest() async {
    try {
      final catalog = await WhatsNewReleaseCatalog.loadFromAssets();
      final latestVersion = catalog?.latestVersion;
      if (catalog == null || latestVersion == null) {
        return null;
      }
      return catalog.selectHighlights(
        lastSeenVersion: '0.0.0',
        currentVersion: latestVersion,
      );
    } catch (e) {
      debugPrint('ℹ️  No What\'s New content found');
      return null;
    }
  }

  /// Load What's New content for a specific version from assets.
  @Deprecated('Use loadForVersionRange instead.')
  static Future<WhatsNewContent?> loadForVersion(String version) async {
    final catalog = await WhatsNewReleaseCatalog.loadFromAssets();
    return catalog?.selectHighlights(
      lastSeenVersion: '0.0.0',
      currentVersion: version,
    );
  }

  /// Create from JSON.
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

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
    'version': version,
    'title': title,
    'items': items.map((item) => item.toJson()).toList(),
  };

  /// Check if content has any items.
  bool get hasItems => items.isNotEmpty;

  /// Get items by type.
  List<WhatsNewItem> getItemsByType(WhatsNewItemType type) {
    return items.where((item) => item.type == type).toList();
  }

  /// Get all feature items.
  List<WhatsNewItem> get features => getItemsByType(WhatsNewItemType.feature);

  /// Get all improvement items.
  List<WhatsNewItem> get improvements =>
      getItemsByType(WhatsNewItemType.improvement);

  /// Get all bugfix items.
  List<WhatsNewItem> get bugfixes => getItemsByType(WhatsNewItemType.bugfix);
}

/// A catalog of curated What's New releases.
class WhatsNewReleaseCatalog {
  final List<WhatsNewRelease> releases;

  const WhatsNewReleaseCatalog({required this.releases});

  /// Load the versioned release catalog from bundled assets.
  static Future<WhatsNewReleaseCatalog?> loadFromAssets() async {
    try {
      const assetPath = 'assets/whats_new/releases.json';
      final jsonString = await rootBundle.loadString(assetPath);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return WhatsNewReleaseCatalog.fromJson(json);
    } catch (e) {
      debugPrint('ℹ️  No What\'s New release catalog found');
      return null;
    }
  }

  /// Create from JSON.
  factory WhatsNewReleaseCatalog.fromJson(Map<String, dynamic> json) {
    final releasesList = json['releases'] as List<dynamic>? ?? [];
    final releases =
        releasesList
            .map(
              (release) =>
                  WhatsNewRelease.fromJson(release as Map<String, dynamic>),
            )
            .toList();

    return WhatsNewReleaseCatalog(releases: releases);
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
    'releases': releases.map((release) => release.toJson()).toList(),
  };

  /// Newest release version in the catalog, if any.
  String? get latestVersion {
    if (releases.isEmpty) {
      return null;
    }

    final sorted = [...releases]
      ..sort((a, b) => WhatsNewVersion.compare(b.version, a.version));
    return sorted.first.version;
  }

  /// Select user-facing highlights between [lastSeenVersion] and [currentVersion].
  ///
  /// Releases must satisfy `lastSeenVersion < release.version <= currentVersion`.
  /// Items are filtered to user-facing content, prioritized, deduplicated by
  /// group, and capped for a compact dialog.
  WhatsNewContent? selectHighlights({
    required String lastSeenVersion,
    required String currentVersion,
    int singleReleaseLimit = 5,
    int multipleReleaseLimit = 5,
  }) {
    final selectedReleases =
        releases.where((release) {
            return WhatsNewVersion.compare(release.version, lastSeenVersion) >
                    0 &&
                WhatsNewVersion.compare(release.version, currentVersion) <= 0;
          }).toList()
          ..sort((a, b) => WhatsNewVersion.compare(b.version, a.version));

    if (selectedReleases.isEmpty) {
      return null;
    }

    final candidates = <_ReleaseItem>[];
    for (final release in selectedReleases) {
      for (final item in release.items.where((item) => item.userFacing)) {
        candidates.add(
          _ReleaseItem(releaseVersion: release.version, item: item),
        );
      }
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((a, b) {
      final importanceCompare = b.item.importance.rank.compareTo(
        a.item.importance.rank,
      );
      if (importanceCompare != 0) {
        return importanceCompare;
      }
      return WhatsNewVersion.compare(b.releaseVersion, a.releaseVersion);
    });

    final seenGroups = <String>{};
    final deduped = <WhatsNewItem>[];
    for (final candidate in candidates) {
      final group = candidate.item.group;
      if (group != null && group.isNotEmpty) {
        if (seenGroups.contains(group)) {
          continue;
        }
        seenGroups.add(group);
      }
      deduped.add(candidate.item);
    }

    final limit =
        selectedReleases.length == 1
            ? singleReleaseLimit
            : multipleReleaseLimit;
    final title =
        selectedReleases.length == 1
            ? 'What\'s New in Baskit'
            : 'Highlights since your last update';

    return WhatsNewContent(
      version: currentVersion,
      title: title,
      items: deduped.take(limit).toList(),
    );
  }
}

class _ReleaseItem {
  final String releaseVersion;
  final WhatsNewItem item;

  const _ReleaseItem({required this.releaseVersion, required this.item});
}

/// Curated What's New content for one app release.
class WhatsNewRelease {
  final String version;
  final String title;
  final List<WhatsNewItem> items;

  const WhatsNewRelease({
    required this.version,
    required this.title,
    required this.items,
  });

  /// Create from JSON.
  factory WhatsNewRelease.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final items =
        itemsList
            .map((item) => WhatsNewItem.fromJson(item as Map<String, dynamic>))
            .toList();

    return WhatsNewRelease(
      version: json['version'] as String? ?? '1.0.0',
      title: json['title'] as String? ?? 'What\'s New',
      items: items,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
    'version': version,
    'title': title,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

/// Represents a single item in the What's New dialog.
class WhatsNewItem {
  final String title;
  final String description;
  final String iconName;
  final WhatsNewItemType type;
  final WhatsNewItemImportance importance;
  final bool userFacing;
  final String? group;

  const WhatsNewItem({
    required this.title,
    required this.description,
    required this.iconName,
    required this.type,
    this.importance = WhatsNewItemImportance.medium,
    this.userFacing = true,
    this.group,
  });

  /// Create from JSON.
  factory WhatsNewItem.fromJson(Map<String, dynamic> json) {
    return WhatsNewItem(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconName: json['icon'] as String? ?? 'info',
      type: WhatsNewItemType.fromString(json['type'] as String? ?? 'feature'),
      importance: WhatsNewItemImportance.fromString(
        json['importance'] as String? ?? 'medium',
      ),
      userFacing: json['userFacing'] as bool? ?? false,
      group: json['group'] as String?,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'importance': importance.name,
    'userFacing': userFacing,
    if (group != null) 'group': group,
    'title': title,
    'description': description,
    'icon': iconName,
  };

  /// Get the Flutter icon for this item.
  IconData get icon {
    switch (iconName.toLowerCase()) {
      // Feature icons
      case 'person_search':
      case 'contact_search':
        return Icons.person_search;
      case 'person_remove':
      case 'account_delete':
        return Icons.person_remove;
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
      case 'sync':
        return Icons.sync;
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

  /// Get the color for this item type.
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

  /// Get the emoji for this item type.
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

/// Types of What's New items.
enum WhatsNewItemType {
  feature,
  improvement,
  bugfix;

  /// Create from string.
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

  /// Get display name.
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

/// Importance levels for selecting release highlights.
enum WhatsNewItemImportance {
  low(1),
  medium(2),
  high(3);

  const WhatsNewItemImportance(this.rank);

  /// Sort rank, where higher values are more important.
  final int rank;

  /// Create from string.
  static WhatsNewItemImportance fromString(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return WhatsNewItemImportance.high;
      case 'low':
        return WhatsNewItemImportance.low;
      case 'medium':
      default:
        return WhatsNewItemImportance.medium;
    }
  }
}
