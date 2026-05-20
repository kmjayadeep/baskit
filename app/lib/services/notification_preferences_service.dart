import 'package:shared_preferences/shared_preferences.dart';

enum NotificationEventType { sharedListChange, itemCompletion, newMember }

class NotificationPreferences {
  final bool sharedListChanges;
  final bool itemCompletions;
  final bool newMembers;

  const NotificationPreferences({
    this.sharedListChanges = true,
    this.itemCompletions = true,
    this.newMembers = true,
  });

  NotificationPreferences copyWith({
    bool? sharedListChanges,
    bool? itemCompletions,
    bool? newMembers,
  }) {
    return NotificationPreferences(
      sharedListChanges: sharedListChanges ?? this.sharedListChanges,
      itemCompletions: itemCompletions ?? this.itemCompletions,
      newMembers: newMembers ?? this.newMembers,
    );
  }

  bool allows(NotificationEventType type) {
    return switch (type) {
      NotificationEventType.sharedListChange => sharedListChanges,
      NotificationEventType.itemCompletion => itemCompletions,
      NotificationEventType.newMember => newMembers,
    };
  }
}

class NotificationPreferencesService {
  static const String _sharedListChangesKey =
      'notification_shared_list_changes';
  static const String _itemCompletionsKey = 'notification_item_completions';
  static const String _newMembersKey = 'notification_new_members';

  static Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      sharedListChanges: prefs.getBool(_sharedListChangesKey) ?? true,
      itemCompletions: prefs.getBool(_itemCompletionsKey) ?? true,
      newMembers: prefs.getBool(_newMembersKey) ?? true,
    );
  }

  static Future<void> save(NotificationPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_sharedListChangesKey, preferences.sharedListChanges),
      prefs.setBool(_itemCompletionsKey, preferences.itemCompletions),
      prefs.setBool(_newMembersKey, preferences.newMembers),
    ]);
  }

  static Future<bool> shouldNotify(NotificationEventType type) async {
    final preferences = await load();
    return preferences.allows(type);
  }
}
