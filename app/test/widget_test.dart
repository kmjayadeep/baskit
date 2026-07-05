// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:baskit/main.dart';
import 'package:baskit/repositories/storage_shopping_repository.dart';
import 'package:baskit/services/local_storage_service.dart';

void main() {
  late StorageShoppingRepository repository;

  setUp(() async {
    // Initialize Hive for tests with a temporary directory
    final tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);

    StorageShoppingRepository.resetOverridesForTest();
    LocalStorageService.resetInstanceForTest();
    repository = StorageShoppingRepository.instance();
    await repository.init();
  });

  tearDown(() async {
    // Clean up after each test
    await Hive.deleteFromDisk();
    repository.dispose();
    StorageShoppingRepository.resetOverridesForTest();
    LocalStorageService.resetInstanceForTest();
  });

  testWidgets('App loads and shows lists screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: BaskitApp(firebaseEnabled: false)),
    );
    await tester.pumpAndSettle();

    // Verify that the lists screen loads (app starts on /lists, not login)
    expect(find.text('My Lists'), findsOneWidget);
    expect(find.text('Your Lists (0)'), findsOneWidget);
    expect(find.text('No lists yet'), findsOneWidget);
    expect(find.text('Create List'), findsOneWidget);
    expect(find.text('Shopping snapshot'), findsNothing);
  });

  // TODO: Add profile navigation test when profile access is re-enabled
}
