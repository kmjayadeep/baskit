import 'package:baskit/screens/profile/widgets/notification_preferences_widget.dart';
import 'package:baskit/services/notification_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows notification toggles with defaults enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NotificationPreferencesWidget())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Shared list changes'), findsOneWidget);
    expect(find.text('Item completions'), findsOneWidget);
    expect(find.text('New members'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).at(0)).value,
      isTrue,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).at(1)).value,
      isTrue,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).at(2)).value,
      isTrue,
    );
  });

  testWidgets('persists changed notification toggle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NotificationPreferencesWidget())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();

    final preferences = await NotificationPreferencesService.load();
    expect(preferences.sharedListChanges, isFalse);
    expect(preferences.itemCompletions, isTrue);
    expect(preferences.newMembers, isTrue);
  });
}
