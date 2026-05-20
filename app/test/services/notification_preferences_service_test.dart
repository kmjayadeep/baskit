import 'package:baskit/services/notification_preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NotificationPreferencesService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to shared list notifications enabled', () async {
      final preferences = await NotificationPreferencesService.load();

      expect(preferences.sharedListChanges, isTrue);
      expect(preferences.itemCompletions, isTrue);
      expect(preferences.newMembers, isTrue);
    });

    test('persists updated notification preferences', () async {
      await NotificationPreferencesService.save(
        const NotificationPreferences(
          sharedListChanges: false,
          itemCompletions: false,
          newMembers: true,
        ),
      );

      final preferences = await NotificationPreferencesService.load();

      expect(preferences.sharedListChanges, isFalse);
      expect(preferences.itemCompletions, isFalse);
      expect(preferences.newMembers, isTrue);
    });

    test('resolves whether an event type should notify', () async {
      await NotificationPreferencesService.save(
        const NotificationPreferences(
          sharedListChanges: true,
          itemCompletions: false,
          newMembers: true,
        ),
      );

      expect(
        await NotificationPreferencesService.shouldNotify(
          NotificationEventType.sharedListChange,
        ),
        isTrue,
      );
      expect(
        await NotificationPreferencesService.shouldNotify(
          NotificationEventType.itemCompletion,
        ),
        isFalse,
      );
      expect(
        await NotificationPreferencesService.shouldNotify(
          NotificationEventType.newMember,
        ),
        isTrue,
      );
    });
  });
}
