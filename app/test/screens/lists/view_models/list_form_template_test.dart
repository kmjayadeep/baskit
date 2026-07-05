import 'dart:async';

import 'package:baskit/models/share_result.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:baskit/models/shopping_list_model.dart';
import 'package:baskit/models/shopping_list_template.dart';
import 'package:baskit/providers/repository_providers.dart';
import 'package:baskit/repositories/shopping_repository.dart';
import 'package:baskit/screens/lists/view_models/list_form_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _RecordingRepository implements ShoppingRepository {
  ShoppingList? createdList;

  @override
  Future<bool> createList(ShoppingList list) async {
    createdList = list;
    return true;
  }

  @override
  Future<bool> updateList(ShoppingList list) async => true;

  @override
  Future<bool> deleteList(String id) async => true;

  @override
  Stream<List<ShoppingList>> watchLists() => const Stream.empty();

  @override
  Stream<ShoppingList?> watchList(String id) => const Stream.empty();

  @override
  Future<bool> addItem(String listId, ShoppingItem item) async => true;

  @override
  Future<bool> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? quantity,
    bool? completed,
  }) async => true;

  @override
  Future<bool> deleteItem(String listId, String itemId) async => true;

  @override
  Future<bool> clearCompleted(String listId) async => true;

  @override
  Future<ShareResult> shareList(String listId, String email) async =>
      ShareResult.success();

  @override
  Future<bool> removeMember(String listId, String userId) async => true;

  @override
  Future<void> sync() async {}

  @override
  Future<DateTime?> getLastSyncTime() async => null;

  @override
  void disposeListStream(String id) {}

  @override
  Future<void> init() async {}

  @override
  void dispose() {}
}

void main() {
  test('built in list templates cover common shopping use cases', () {
    expect(builtInShoppingListTemplates, hasLength(greaterThanOrEqualTo(5)));
    expect(
      builtInShoppingListTemplates.map((template) => template.name),
      containsAll(<String>[
        'Weekly Groceries',
        'Party Supplies',
        'Household Essentials',
        'Travel Packing',
        'Baby & Kids Essentials',
      ]),
    );
    expect(
      builtInShoppingListTemplates.every(
        (template) => template.items.isNotEmpty,
      ),
      isTrue,
    );
  });

  test(
    'applying a template fills the form and creates a prefilled list',
    () async {
      final repository = _RecordingRepository();
      final container = ProviderContainer(
        overrides: [shoppingRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final template = builtInShoppingListTemplates.firstWhere(
        (template) => template.name == 'Weekly Groceries',
      );
      final viewModel = container.read(listFormViewModelProvider.notifier);

      viewModel.applyTemplate(template);

      final state = container.read(listFormViewModelProvider);
      expect(state.name, template.name);
      expect(state.description, template.description);
      expect(state.selectedTemplate, template);
      expect(state.isValid, isTrue);

      final success = await viewModel.createList();

      expect(success, isTrue);
      expect(repository.createdList, isNotNull);
      expect(repository.createdList!.name, template.name);
      expect(repository.createdList!.description, template.description);
      expect(
        repository.createdList!.items.map((item) => item.name),
        template.items,
      );
      expect(
        repository.createdList!.items.every((item) => !item.isCompleted),
        isTrue,
      );
    },
  );
}
