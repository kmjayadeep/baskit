import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/screens/list_detail/widgets/dialogs/enhanced_share_list_dialog.dart';
import 'package:baskit/view_models/contact_suggestions_view_model.dart';

class _LoadingContactSuggestionsViewModel extends ContactSuggestionsViewModel {
  @override
  ContactSuggestionsState build() {
    return const ContactSuggestionsState.loading();
  }
}

void main() {
  group('EnhancedShareListDialog', () {
    late ShoppingList testList;

    setUp(() {
      testList = ShoppingList(
        id: 'test-list-1',
        name: 'Test Shopping List',
        description: 'A test list for sharing',
        color: '#FF5722',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          ShoppingItem(
            id: 'item-1',
            name: 'Test Item',
            createdAt: DateTime.now(),
          ),
        ],
      );
    });

    Widget buildDialog({required Future<void> Function(String email) onShare}) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: EnhancedShareListDialog(list: testList, onShare: onShare),
          ),
        ),
      );
    }

    testWidgets('renders title and actions', (WidgetTester tester) async {
      await tester.pumpWidget(buildDialog(onShare: (_) async {}));

      expect(find.text('Share "Test Shopping List"'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('submits email via Share button', (WidgetTester tester) async {
      String? sharedEmail;

      await tester.pumpWidget(
        buildDialog(
          onShare: (email) async {
            sharedEmail = email;
          },
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.tap(find.text('Share'));
      await tester.pump();

      expect(sharedEmail, equals('test@example.com'));
    });

    testWidgets('shows loading hint when contacts load', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contactSuggestionsViewModelProvider.overrideWith(
              () => _LoadingContactSuggestionsViewModel(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedShareListDialog(
                list: testList,
                onShare: (_) async {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Loading contacts...'), findsOneWidget);
    });
  });
}
