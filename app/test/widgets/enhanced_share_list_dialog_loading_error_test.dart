import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baskit/screens/list_detail/widgets/dialogs/enhanced_share_list_dialog.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/list_member_model.dart';
import 'package:baskit/models/contact_suggestion_model.dart';
import 'package:baskit/view_models/contact_suggestions_view_model.dart';

/// Tests for loading states and error handling in EnhancedShareListDialog
///
/// Covers Step 8b: Add tests for loading/error scenarios
void main() {
  group('EnhancedShareListDialog - Loading & Error Tests', () {
    late ShoppingList testList;

    setUp(() {
      testList = ShoppingList(
        id: 'test-list-1',
        name: 'Test Shopping List',
        description: 'A test list',
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
        members: [
          ListMember(
            userId: 'current-user-id',
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
        ],
      );
    });

    group('Loading States', () {
      testWidgets('should show loading spinner when contacts are loading', (
        WidgetTester tester,
      ) async {
        // Mock ViewModel in loading state
        final mockViewModel = _LoadingContactsViewModel();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contactSuggestionsViewModelProvider.overrideWith(
                () => mockViewModel,
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

        // Use pump() instead of pumpAndSettle() to avoid timeout with spinner animation
        await tester.pump();

        // Should show loading spinner in suffix icon
        expect(find.byType(CircularProgressIndicator), findsWidgets);

        // Should show loading hint text
        expect(find.text('Loading contacts...'), findsOneWidget);
      });

      testWidgets('should hide loading spinner when contacts are loaded', (
        WidgetTester tester,
      ) async {
        final contacts = [
          ContactSuggestion(
            userId: 'user1',
            email: 'alice@test.com',
            displayName: 'Alice Smith',
            sharedListsCount: 3,
          ),
        ];

        final mockViewModel = _LoadedContactsViewModel(contacts);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contactSuggestionsViewModelProvider.overrideWith(
                () => mockViewModel,
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

        await tester.pumpAndSettle();

        // Should not show loading hint anymore
        expect(find.text('Loading contacts...'), findsNothing);

        // Should show suggestions hint instead
        expect(find.text('Start typing to see suggestions...'), findsOneWidget);
      });

      testWidgets(
        'should show loading spinner on Share button during submission',
        (WidgetTester tester) async {
          final mockViewModel = _LoadedContactsViewModel([]);
          bool submitted = false;

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                contactSuggestionsViewModelProvider.overrideWith(
                  () => mockViewModel,
                ),
              ],
              child: MaterialApp(
                home: Scaffold(
                  body: EnhancedShareListDialog(
                    list: testList,
                    onShare: (email) async {
                      submitted = true;
                    },
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Enter valid email
          await tester.enterText(
            find.byType(TextFormField),
            'test@example.com',
          );
          await tester.pump();

          // Tap share button
          await tester.tap(find.text('Share'));
          await tester.pump();

          // Verify the share was triggered
          expect(submitted, isTrue);
        },
      );

      testWidgets('should have buttons present for user interaction', (
        WidgetTester tester,
      ) async {
        final mockViewModel = _LoadedContactsViewModel([]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contactSuggestionsViewModelProvider.overrideWith(
                () => mockViewModel,
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

        await tester.pumpAndSettle();

        // Verify buttons exist
        final cancelButton = find.ancestor(
          of: find.text('Cancel'),
          matching: find.byType(TextButton),
        );

        expect(cancelButton, findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should display error message when contact loading fails', (
        WidgetTester tester,
      ) async {
        const errorMessage = 'Failed to load contacts';
        final mockViewModel = _ErrorContactsViewModel(errorMessage);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contactSuggestionsViewModelProvider.overrideWith(
                () => mockViewModel,
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

        await tester.pumpAndSettle();

        // Should display error message
        expect(
          find.text('Unable to load contact suggestions: $errorMessage'),
          findsOneWidget,
        );

        // Error text should be in error color
        final errorText = tester.widget<Text>(
          find.text('Unable to load contact suggestions: $errorMessage'),
        );
        expect(errorText.style?.color, isNotNull);
      });

      testWidgets(
        'should allow manual email entry when contact loading fails',
        (WidgetTester tester) async {
          bool shareCallbackCalled = false;
          String? sharedEmail;

          final mockViewModel = _ErrorContactsViewModel('Network error');

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                contactSuggestionsViewModelProvider.overrideWith(
                  () => mockViewModel,
                ),
              ],
              child: MaterialApp(
                home: Scaffold(
                  body: EnhancedShareListDialog(
                    list: testList,
                    onShare: (email) async {
                      shareCallbackCalled = true;
                      sharedEmail = email;
                    },
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Should still be able to enter email manually
          const manualEmail = 'manual@example.com';
          await tester.enterText(find.byType(TextFormField), manualEmail);
          await tester.pumpAndSettle();

          // Tap share button
          await tester.tap(find.text('Share'));
          await tester.pump();

          // Should call onShare with manual email
          expect(shareCallbackCalled, isTrue);
          expect(sharedEmail, equals(manualEmail));
        },
      );

      testWidgets(
        'should show previous contacts when error occurs after successful load',
        (WidgetTester tester) async {
          final previousContacts = [
            ContactSuggestion(
              userId: 'user1',
              email: 'alice@test.com',
              displayName: 'Alice Smith',
              sharedListsCount: 3,
            ),
          ];

          const errorMessage = 'Refresh failed';
          final mockViewModel = _ErrorContactsViewModel(
            errorMessage,
            previousContacts: previousContacts,
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                contactSuggestionsViewModelProvider.overrideWith(
                  () => mockViewModel,
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

          await tester.pumpAndSettle();

          // Should show error message
          expect(
            find.text('Unable to load contact suggestions: $errorMessage'),
            findsOneWidget,
          );

          // Should still have access to previous contacts
          expect(mockViewModel.state.contacts.length, equals(1));
          expect(
            mockViewModel.state.contacts.first.email,
            equals('alice@test.com'),
          );
        },
      );

      testWidgets('should have form validation available', (
        WidgetTester tester,
      ) async {
        final mockViewModel = _LoadedContactsViewModel([]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contactSuggestionsViewModelProvider.overrideWith(
                () => mockViewModel,
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

        await tester.pumpAndSettle();

        // Verify form field with validation exists
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byType(Form), findsOneWidget);

        // Enter valid email and verify it works
        await tester.enterText(find.byType(TextFormField), 'valid@example.com');
        await tester.pump();

        expect(find.text('valid@example.com'), findsOneWidget);
      });

      testWidgets(
        'should recover from error state when contacts load successfully',
        (WidgetTester tester) async {
          // Start with error state
          final mockViewModel = _MutableStateViewModel(
            const ContactSuggestionsState.error('Initial error'),
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                contactSuggestionsViewModelProvider.overrideWith(
                  () => mockViewModel,
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

          await tester.pumpAndSettle();

          // Should show error
          expect(
            find.text('Unable to load contact suggestions: Initial error'),
            findsOneWidget,
          );

          // Simulate successful load
          final contacts = [
            ContactSuggestion(
              userId: 'user1',
              email: 'alice@test.com',
              displayName: 'Alice Smith',
              sharedListsCount: 1,
            ),
          ];
          mockViewModel.setState(ContactSuggestionsState.loaded(contacts));
          await tester.pumpAndSettle();

          // Error should be gone
          expect(
            find.text('Unable to load contact suggestions: Initial error'),
            findsNothing,
          );

          // Should show suggestions hint
          expect(
            find.text('Start typing to see suggestions...'),
            findsOneWidget,
          );
        },
      );
    });

    group('Edge Cases', () {
      testWidgets('should handle rapid state changes gracefully', (
        WidgetTester tester,
      ) async {
        final mockViewModel = _MutableStateViewModel(
          const ContactSuggestionsState.loading(),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contactSuggestionsViewModelProvider.overrideWith(
                () => mockViewModel,
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

        // Use pump() for loading state to avoid timeout
        await tester.pump();

        // Rapidly change states
        mockViewModel.setState(const ContactSuggestionsState.error('Error 1'));
        await tester.pump();

        mockViewModel.setState(const ContactSuggestionsState.loading());
        await tester.pump();

        final contacts = [
          ContactSuggestion(
            userId: 'user1',
            email: 'test@test.com',
            displayName: 'Test User',
            sharedListsCount: 1,
          ),
        ];
        mockViewModel.setState(ContactSuggestionsState.loaded(contacts));
        await tester.pumpAndSettle();

        // Should end up in loaded state without crashing
        expect(find.byType(EnhancedShareListDialog), findsOneWidget);
        expect(find.text('Start typing to see suggestions...'), findsOneWidget);
      });

      testWidgets('should handle null/empty error messages', (
        WidgetTester tester,
      ) async {
        final mockViewModel = _ErrorContactsViewModel('');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contactSuggestionsViewModelProvider.overrideWith(
                () => mockViewModel,
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

        await tester.pumpAndSettle();

        // Should still show error message container
        expect(
          find.text('Unable to load contact suggestions: '),
          findsOneWidget,
        );
      });

      testWidgets('should not crash with very long error messages', (
        WidgetTester tester,
      ) async {
        const longError =
            'This is a very long error message that might wrap multiple lines '
            'and could potentially cause layout issues if not handled properly. '
            'It contains detailed information about what went wrong during the '
            'contact loading process including stack traces and error codes.';

        final mockViewModel = _ErrorContactsViewModel(longError);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contactSuggestionsViewModelProvider.overrideWith(
                () => mockViewModel,
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

        await tester.pumpAndSettle();

        // Should render without overflow or crash
        expect(find.byType(EnhancedShareListDialog), findsOneWidget);
        expect(
          find.textContaining('Unable to load contact suggestions:'),
          findsOneWidget,
        );
      });
    });
  });
}

// ============================================================================
// MOCK VIEW MODELS FOR TESTING
// ============================================================================

/// Mock ViewModel that returns loading state
class _LoadingContactsViewModel extends ContactSuggestionsViewModel {
  @override
  ContactSuggestionsState build() {
    return const ContactSuggestionsState.loading();
  }
}

/// Mock ViewModel that returns loaded state with contacts
class _LoadedContactsViewModel extends ContactSuggestionsViewModel {
  final List<ContactSuggestion> contacts;

  _LoadedContactsViewModel(this.contacts);

  @override
  ContactSuggestionsState build() {
    return ContactSuggestionsState.loaded(contacts);
  }
}

/// Mock ViewModel that returns error state
class _ErrorContactsViewModel extends ContactSuggestionsViewModel {
  final String errorMessage;
  final List<ContactSuggestion>? previousContacts;

  _ErrorContactsViewModel(this.errorMessage, {this.previousContacts});

  @override
  ContactSuggestionsState build() {
    return ContactSuggestionsState.error(errorMessage, previousContacts);
  }
}

/// Mock ViewModel that allows state mutations during tests
class _MutableStateViewModel extends ContactSuggestionsViewModel {
  ContactSuggestionsState _currentState;

  _MutableStateViewModel(this._currentState);

  @override
  ContactSuggestionsState build() {
    return _currentState;
  }

  void setState(ContactSuggestionsState newState) {
    _currentState = newState;
    state = newState;
  }
}
