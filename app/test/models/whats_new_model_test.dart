import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baskit/models/whats_new_model.dart';

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

  group('WhatsNewItem', () {
    test('should create from JSON correctly', () {
      final json = {
        'type': 'feature',
        'title': 'New Feature',
        'description': 'A cool new feature',
        'icon': 'star',
      };

      final item = WhatsNewItem.fromJson(json);

      expect(item.type, WhatsNewItemType.feature);
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
      );

      final json = item.toJson();

      expect(json['title'], 'Test Feature');
      expect(json['description'], 'Test description');
      expect(json['icon'], 'star');
      expect(json['type'], 'feature');
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
}
