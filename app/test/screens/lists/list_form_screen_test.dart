import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:baskit/screens/lists/list_form_screen.dart';
import 'package:baskit/screens/lists/view_models/list_form_view_model.dart';

class _FakeListFormViewModel extends ListFormViewModel {
  @override
  ListFormState build() => const ListFormState.initial();

  @override
  Future<bool> createList() async {
    // Mirrors production success path where create resets form state.
    state = const ListFormState.initial();
    return true;
  }
}

void main() {
  testWidgets('create success snackbar uses submitted list name', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => binding.setSurfaceSize(null));

    final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    final router = GoRouter(
      initialLocation: '/form',
      routes: [
        GoRoute(
          path: '/form',
          builder: (context, state) => const ListFormScreen(),
        ),
        GoRoute(
          path: '/lists',
          builder:
              (context, state) =>
                  const Scaffold(body: Center(child: Text('Lists Page'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listFormViewModelProvider.overrideWith(
            () => _FakeListFormViewModel(),
          ),
        ],
        child: MaterialApp.router(
          scaffoldMessengerKey: scaffoldMessengerKey,
          routerConfig: router,
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Weekend Shop');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(
      find.text('List "Weekend Shop" created successfully!'),
      findsOneWidget,
    );
  });
}
