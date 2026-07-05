import 'package:baskit/models/whats_new_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatsNewContent', () {
    test('should create from JSON correctly', () {
      final json = {
        'version': '1.0.0',
        'title': 'Test Release',
        'items': [
          {
            'type': 'feature',
            'title': 'New Feature',
            'description': 'A cool new feature',
            'icon': 'star',
          },
          {
            'type': 'improvement',
            'title': 'Better Performance',
            'description': 'App runs faster now',
            'icon': 'speed',
          },
        ],
      };

      final content = WhatsNewContent.fromJson(json);

      expect(content.version, '1.0.0');
      expect(content.title, 'Test Release');
      expect(content.items.length, 2);
      expect(content.hasItems, true);
    });

    test('should handle empty items list', () {
      final json = {'version': '1.0.0', 'title': 'Test Release', 'items': []};

      final content = WhatsNewContent.fromJson(json);

      expect(content.hasItems, false);
      expect(content.items.isEmpty, true);
    });

    test('should filter items by type', () {
      final content = WhatsNewContent(
        version: '1.0.0',
        title: 'Test',
        items: [
          const WhatsNewItem(
            title: 'Feature 1',
            description: 'Desc',
            iconName: 'star',
            type: WhatsNewItemType.feature,
          ),
          const WhatsNewItem(
            title: 'Improvement 1',
            description: 'Desc',
            iconName: 'speed',
            type: WhatsNewItemType.improvement,
          ),
          const WhatsNewItem(
            title: 'Bug Fix 1',
            description: 'Desc',
            iconName: 'bug_fix',
            type: WhatsNewItemType.bugfix,
          ),
        ],
      );

      expect(content.features.length, 1);
      expect(content.improvements.length, 1);
      expect(content.bugfixes.length, 1);
    });
  });

  group('WhatsNewReleaseCatalog', () {
    test('parses versioned releases', () {
      final catalog = WhatsNewReleaseCatalog.fromJson({
        'releases': [
          {
            'version': '4.13.54',
            'title': 'Baskit 4.13.54',
            'items': [
              {
                'type': 'improvement',
                'importance': 'high',
                'userFacing': true,
                'group': 'sharing',
                'title': 'Cleaner sharing',
                'description': 'Sharing is easier.',
                'icon': 'group',
              },
            ],
          },
        ],
      });

      expect(catalog.releases, hasLength(1));
      expect(catalog.latestVersion, '4.13.54');
      expect(
        catalog.releases.first.items.single.importance,
        WhatsNewItemImportance.high,
      );
      expect(catalog.releases.first.items.single.group, 'sharing');
    });

    test('selects one-version update highlights', () {
      final catalog = _catalogWithReleases([
        _release('1.0.1', [
          _item('Visible high', importance: 'high'),
          _item('Hidden technical', userFacing: false),
          _item('Visible medium', importance: 'medium'),
        ]),
      ]);

      final content = catalog.selectHighlights(
        lastSeenVersion: '1.0.0',
        currentVersion: '1.0.1',
      );

      expect(content, isNotNull);
      expect(content!.title, 'What\'s New in Baskit');
      expect(content.version, '1.0.1');
      expect(content.items.map((item) => item.title), [
        'Visible high',
        'Visible medium',
      ]);
    });

    test('selects skipped-version summary with prioritization and dedupe', () {
      final catalog = _catalogWithReleases([
        _release('1.0.1', [
          _item('Older sharing', importance: 'medium', group: 'sharing'),
          _item('Low priority', importance: 'low', group: 'low'),
        ]),
        _release('1.0.2', [
          _item('Newer sharing', importance: 'high', group: 'sharing'),
          _item('Account cleanup', importance: 'medium', group: 'account'),
        ]),
      ]);

      final content = catalog.selectHighlights(
        lastSeenVersion: '1.0.0',
        currentVersion: '1.0.2',
      );

      expect(content, isNotNull);
      expect(content!.title, 'Highlights since your last update');
      expect(content.items.map((item) => item.title), [
        'Newer sharing',
        'Account cleanup',
        'Low priority',
      ]);
    });

    test('caps selected highlights for skipped-version updates', () {
      final catalog = _catalogWithReleases([
        _release('1.0.1', [
          for (var i = 1; i <= 6; i++) _item('Highlight $i', group: 'g$i'),
        ]),
        _release('1.0.2', [_item('Highlight 7', group: 'g7')]),
      ]);

      final content = catalog.selectHighlights(
        lastSeenVersion: '1.0.0',
        currentVersion: '1.0.2',
        multipleReleaseLimit: 5,
      );

      expect(content, isNotNull);
      expect(content!.items, hasLength(5));
    });

    test('returns null when no eligible user-facing highlights exist', () {
      final catalog = _catalogWithReleases([
        _release('1.0.1', [_item('Internal only', userFacing: false)]),
      ]);

      final content = catalog.selectHighlights(
        lastSeenVersion: '1.0.0',
        currentVersion: '1.0.1',
      );

      expect(content, isNull);
    });

    test('excludes releases outside the version range', () {
      final catalog = _catalogWithReleases([
        _release('1.0.0', [_item('Already seen')]),
        _release('1.0.1', [_item('Current')]),
        _release('1.0.2', [_item('Future')]),
      ]);

      final content = catalog.selectHighlights(
        lastSeenVersion: '1.0.0',
        currentVersion: '1.0.1',
      );

      expect(content, isNotNull);
      expect(content!.items.map((item) => item.title), ['Current']);
    });
  });

  group('WhatsNewItem', () {
    test('should create from JSON correctly', () {
      final json = {
        'type': 'feature',
        'importance': 'high',
        'userFacing': true,
        'group': 'test',
        'title': 'New Feature',
        'description': 'A cool new feature',
        'icon': 'star',
      };

      final item = WhatsNewItem.fromJson(json);

      expect(item.type, WhatsNewItemType.feature);
      expect(item.importance, WhatsNewItemImportance.high);
      expect(item.userFacing, true);
      expect(item.group, 'test');
      expect(item.title, 'New Feature');
      expect(item.description, 'A cool new feature');
      expect(item.iconName, 'star');
    });

    test('should convert to JSON correctly', () {
      const item = WhatsNewItem(
        title: 'Test Feature',
        description: 'Test description',
        iconName: 'star',
        type: WhatsNewItemType.feature,
        importance: WhatsNewItemImportance.low,
        userFacing: false,
        group: 'test',
      );

      final json = item.toJson();

      expect(json['title'], 'Test Feature');
      expect(json['description'], 'Test description');
      expect(json['icon'], 'star');
      expect(json['type'], 'feature');
      expect(json['importance'], 'low');
      expect(json['userFacing'], false);
      expect(json['group'], 'test');
    });

    test('should return correct icons', () {
      const item = WhatsNewItem(
        title: 'Test',
        description: 'Test',
        iconName: 'star',
        type: WhatsNewItemType.feature,
      );

      expect(item.icon, Icons.star);
    });

    test('should return default icon for unknown icon name', () {
      const item = WhatsNewItem(
        title: 'Test',
        description: 'Test',
        iconName: 'unknown_icon',
        type: WhatsNewItemType.feature,
      );

      expect(item.icon, Icons.info);
    });

    test('should return correct emoji for type', () {
      const feature = WhatsNewItem(
        title: 'Test',
        description: 'Test',
        iconName: 'star',
        type: WhatsNewItemType.feature,
      );

      const improvement = WhatsNewItem(
        title: 'Test',
        description: 'Test',
        iconName: 'speed',
        type: WhatsNewItemType.improvement,
      );

      const bugfix = WhatsNewItem(
        title: 'Test',
        description: 'Test',
        iconName: 'bug_fix',
        type: WhatsNewItemType.bugfix,
      );

      expect(feature.emoji, '✨');
      expect(improvement.emoji, '🚀');
      expect(bugfix.emoji, '🛠️');
    });
  });

  group('WhatsNewItemType', () {
    test('should create from string correctly', () {
      expect(WhatsNewItemType.fromString('feature'), WhatsNewItemType.feature);
      expect(WhatsNewItemType.fromString('new'), WhatsNewItemType.feature);
      expect(
        WhatsNewItemType.fromString('improvement'),
        WhatsNewItemType.improvement,
      );
      expect(
        WhatsNewItemType.fromString('enhance'),
        WhatsNewItemType.improvement,
      );
      expect(WhatsNewItemType.fromString('bugfix'), WhatsNewItemType.bugfix);
      expect(WhatsNewItemType.fromString('fix'), WhatsNewItemType.bugfix);
      expect(WhatsNewItemType.fromString('unknown'), WhatsNewItemType.feature);
    });

    test('should return correct display names', () {
      expect(WhatsNewItemType.feature.displayName, 'New Feature');
      expect(WhatsNewItemType.improvement.displayName, 'Improvement');
      expect(WhatsNewItemType.bugfix.displayName, 'Bug Fix');
    });
  });

  group('WhatsNewItemImportance', () {
    test('should create from string correctly', () {
      expect(
        WhatsNewItemImportance.fromString('high'),
        WhatsNewItemImportance.high,
      );
      expect(
        WhatsNewItemImportance.fromString('medium'),
        WhatsNewItemImportance.medium,
      );
      expect(
        WhatsNewItemImportance.fromString('low'),
        WhatsNewItemImportance.low,
      );
      expect(
        WhatsNewItemImportance.fromString('unknown'),
        WhatsNewItemImportance.medium,
      );
    });
  });

  group('WhatsNewVersion', () {
    test('compares semantic versions', () {
      expect(WhatsNewVersion.compare('1.0.1', '1.0.0'), greaterThan(0));
      expect(WhatsNewVersion.compare('1.2.0', '1.10.0'), lessThan(0));
      expect(WhatsNewVersion.compare('2.0', '2.0.0'), 0);
      expect(WhatsNewVersion.compare('1.0.0+2', '1.0.0+1'), 0);
    });
  });
}

WhatsNewReleaseCatalog _catalogWithReleases(List<WhatsNewRelease> releases) {
  return WhatsNewReleaseCatalog(releases: releases);
}

WhatsNewRelease _release(String version, List<WhatsNewItem> items) {
  return WhatsNewRelease(
    version: version,
    title: 'Baskit $version',
    items: items,
  );
}

WhatsNewItem _item(
  String title, {
  String type = 'improvement',
  String importance = 'medium',
  bool userFacing = true,
  String? group,
}) {
  return WhatsNewItem(
    title: title,
    description: '$title description',
    iconName: 'star',
    type: WhatsNewItemType.fromString(type),
    importance: WhatsNewItemImportance.fromString(importance),
    userFacing: userFacing,
    group: group,
  );
}
