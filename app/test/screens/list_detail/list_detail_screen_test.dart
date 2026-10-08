import 'package:baskit/screens/list_detail/list_detail_screen.dart';
import 'package:baskit/screens/list_detail/view_models/list_detail_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeListDetailViewModel extends ListDetailViewModel {
  FakeListDetailViewModel(this.initialState) : super('list-1');

  final ListDetailState initialState;
  int retryCount = 0;

  @override
  ListDetailState build() => initialState;

  @override
  void retryLoad() {
    retryCount++;
    state = const ListDetailState.loading();
  }
}

void main() {
  testWidgets(
    'shows load errors and retries without treating them as missing',
    (tester) async {
      final viewModel = FakeListDetailViewModel(
        ListDetailState.error('Connection lost'),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            listDetailViewModelProvider('list-1').overrideWith(() => viewModel),
          ],
          child: const MaterialApp(home: ListDetailScreen(listId: 'list-1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Error loading list'), findsOneWidget);
      expect(find.text('Connection lost'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('List Not Found'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(viewModel.retryCount, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Error loading list'), findsNothing);
    },
  );
}
