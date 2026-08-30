import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'whats_new_item_model.dart';

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

  Map<String, dynamic> toJson() => {
    'version': version,
    'title': title,
    'items': items.map((item) => item.toJson()).toList(),
  };

  bool get hasItems => items.isNotEmpty;

  List<WhatsNewItem> getItemsByType(WhatsNewItemType type) {
    return items.where((item) => item.type == type).toList();
  }

  List<WhatsNewItem> get features => getItemsByType(WhatsNewItemType.feature);

  List<WhatsNewItem> get improvements =>
      getItemsByType(WhatsNewItemType.improvement);

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

