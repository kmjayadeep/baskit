import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/providers/repository_providers.dart';
import 'package:baskit/repositories/shopping_repository.dart';
import 'package:baskit/screens/lists/view_models/lists_view_model.dart';
import 'package:baskit/view_models/auth_view_model.dart';

class FakeListsRepository implements ShoppingRepository {
  FakeListsRepository(this.controller);

  final StreamController<List<ShoppingList>> controller;
  int watchListsCalls = 0;
  int syncCalls = 0;

  @override
  Stream<List<ShoppingList>> watchLists() {
    watchListsCalls += 1;
    return controller.stream;
  }

  @override
  Future<void> sync() async {
    syncCalls += 1;
  }

  @override
  void disposeListStream(String id) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestUser extends Fake implements User {
  TestUser(this.userId);

  final String userId;

  @override
  String get uid => userId;
}

class FakeAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState.initial();
}

void main() {
  late StreamController<List<ShoppingList>> listsController;
  late FakeListsRepository repository;
  late ProviderContainer container;

  ShoppingList list(String name) => ShoppingList(
    id: name,
    name: name,
    description: '',
    color: '#2E7D32',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );

  setUp(() {
    listsController = StreamController<List<ShoppingList>>.broadcast();
    repository = FakeListsRepository(listsController);
    container = ProviderContainer(
      overrides: [
        shoppingRepositoryProvider.overrideWithValue(repository),
        authViewModelProvider.overrideWith(() => FakeAuthViewModel()),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await listsController.close();
  });

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  group('ListsViewModel.refreshLists', () {
    test('keeps existing lists visible while re-subscribing', () async {
      final viewModel = container.read(listsViewModelProvider.notifier);
      expect(viewModel.state.isLoading, isTrue);

      final loaded = [list('Groceries'), list('Party')];
      listsController.add(loaded);
      await pump();
      expect(viewModel.state.lists, loaded);
      expect(viewModel.state.isLoading, isFalse);

      // Pull-to-refresh re-subscribes to the stream. Until the stream
      // emits again the previous lists must stay visible.
      await viewModel.refreshLists();
      expect(viewModel.state.lists, loaded);
      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.isRefreshing, isFalse);
      expect(repository.watchListsCalls, 2);
      expect(repository.syncCalls, 1);
    });

    test('shows loading state on the initial load only', () async {
      final viewModel = container.read(listsViewModelProvider.notifier);
      expect(viewModel.state.isLoading, isTrue);
      expect(viewModel.state.lists, isEmpty);

      listsController.add([list('Groceries')]);
      await pump();
      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.lists, hasLength(1));
    });

    test(
      'surfaces stream errors and clears them on the next emission',
      () async {
        final viewModel = container.read(listsViewModelProvider.notifier);
        final loaded = [list('Groceries')];
        listsController.add(loaded);
        await pump();
        expect(viewModel.state.lists, loaded);

        listsController.addError('boom');
        await pump();
        expect(viewModel.state.error, contains('boom'));
        expect(viewModel.state.isRefreshing, isFalse);

        listsController.add(loaded);
        await pump();
        expect(viewModel.state.error, isNull);
        expect(viewModel.state.lists, loaded);
      },
    );
  });
}
