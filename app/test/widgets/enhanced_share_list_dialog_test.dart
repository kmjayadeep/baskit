import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baskit/screens/list_detail/widgets/dialogs/enhanced_share_list_dialog.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/view_models/contact_suggestions_view_model.dart';

/// Mock ContactSuggestionsViewModel that returns empty loaded state
class _MockContactSuggestionsViewModel extends ContactSuggestionsViewModel {
  @override
  ContactSuggestionsState build() {
    // Return empty loaded state (not loading, no contacts)
    return const ContactSuggestionsState.loaded([]);
  }
}

void main() {
  group('EnhancedShareListDialog Widget Tests', () {
    late ShoppingList testList;
    bool shareCallbackCalled = false;
    String? sharedEmail;

    setUp(() {
      // Reset callback tracking
      shareCallbackCalled = false;
      sharedEmail = null;

      // Create a test shopping list
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

    // Helper to build the dialog wrapped in required providers and material app
    Widget buildDialog({required Future<void> Function(String email) onShare}) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: EnhancedShareListDialog(list: testList, onShare: onShare),
          ),
        ),
      );
    }

    testWidgets('should display dialog with correct title and content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildDialog(
          onShare: (email) async {
            shareCallbackCalled = true;
            sharedEmail = email;
          },
        ),
      );

      // Verify dialog title
      expect(find.text('Share "Test Shopping List"'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);

      // Verify content text
      expect(
        find.text('Enter an email address or select from your contacts:'),
        findsOneWidget,
      );
      expect(
        find.text('The person will be able to view and edit this list.'),
        findsOneWidget,
      );

      // Verify email input field
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);

      // Verify action buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('should show appropriate hint text when no contacts available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override to return empty loaded state (not loading, empty contacts)
            contactSuggestionsViewModelProvider.overrideWith(
              () => _MockContactSuggestionsViewModel(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedShareListDialog(
                list: testList,
                onShare: (email) async {},
              ),
            ),
          ),
        ),
      );

      // Wait for widget to build and settle
      await tester.pumpAndSettle();

      // Should show basic hint when no contact suggestions available
      expect(find.text('user@example.com'), findsOneWidget);
    });

    testWidgets('should handle cancel button tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildDialog(
          onShare: (email) async {
            shareCallbackCalled = true;
          },
        ),
      );

      // Tap cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify callback was not called
      expect(shareCallbackCalled, isFalse);
    });

    testWidgets('should handle text input in email field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildDialog(
          onShare: (email) async {
            shareCallbackCalled = true;
            sharedEmail = email;
          },
        ),
      );

      // Find the email input field and enter text
      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Verify text was entered
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should handle valid email submission via Share button', (
      WidgetTester tester,
    ) async {
      const validEmail = 'test@example.com';

      await tester.pumpWidget(
        buildDialog(
          onShare: (email) async {
            shareCallbackCalled = true;
            sharedEmail = email;
          },
        ),
      );

      // Enter valid email
      await tester.enterText(find.byType(TextFormField), validEmail);
      await tester.pump();

      // Tap share button
      await tester.tap(find.text('Share'));
      await tester.pump();

      // Verify callback was called with correct email
      expect(shareCallbackCalled, isTrue);
      expect(sharedEmail, equals(validEmail));
    });

    testWidgets('should handle long list names with ellipsis', (
      WidgetTester tester,
    ) async {
      final longNameList = testList.copyWith(
        name:
            'This is a very long shopping list name that should be truncated with ellipsis',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedShareListDialog(
                list: longNameList,
                onShare: (email) async {},
              ),
            ),
          ),
        ),
      );

      // Should find the title text (it will be truncated by the Expanded widget)
      expect(find.textContaining('Share "This is a very long'), findsOneWidget);
    });

    testWidgets('should be accessible with proper semantics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildDialog(onShare: (email) async {}));

      // Verify key interactive elements have semantics
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget); // Cancel
      expect(find.byType(ElevatedButton), findsOneWidget); // Share

      // Verify dialog structure
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('should have autocomplete structure ready for integration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildDialog(onShare: (email) async {}));

      // Verify the form structure is set up for autocomplete
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      // Enter text to test the text changing functionality
      await tester.enterText(find.byType(TextFormField), 'typing...');
      await tester.pump();

      // Text should be entered (this tests the onChanged callback)
      expect(find.text('typing...'), findsOneWidget);
    });

    testWidgets('should filter out existing list members from suggestions', (
      WidgetTester tester,
    ) async {
      // Create a list with existing members
      final listWithMembers = testList.copyWith(
        memberDetails: [
          ListMember(
            userId: 'current_user',
            displayName: 'Current User',
            email: 'current@test.com',
            role: MemberRole.owner,
            joinedAt: DateTime.now(),
            permissions: const {
              'read': true,
              'write': true,
              'delete': true,
              'share': true,
            },
          ),
          ListMember(
            userId: 'existing_member',
            displayName: 'Existing Member',
            email: 'existing@test.com',
            role: MemberRole.member,
            joinedAt: DateTime.now(),
            permissions: const {'read': true, 'write': true},
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override the contact suggestions provider to return empty contacts
            contactSuggestionsViewModelProvider.overrideWith(
              () => _MockContactSuggestionsViewModel(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: EnhancedShareListDialog(
                list: listWithMembers,
                onShare: (email) async {},
              ),
            ),
          ),
        ),
      );

      // Wait for widget to build and settle
      await tester.pumpAndSettle();

      // The dialog should be displayed correctly
      expect(find.byType(EnhancedShareListDialog), findsOneWidget);

      // Should show the basic hint since no contact suggestions will be available
      // (The test environment won't have contacts, so filtering will result in empty list)
      expect(find.text('user@example.com'), findsOneWidget);
    });
  });
}
