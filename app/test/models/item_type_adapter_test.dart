import 'dart:io';

import 'package:baskit/models/item_type_adapter.dart';
import 'package:baskit/models/shopping_item_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  test('Hive adapter persists each item type across box reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'item_type_adapter',
    );
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(ItemTypeAdapter());
    try {
      var box = await Hive.openBox<ItemType>('item_types');
      for (final type in ItemType.values) {
        await box.put(type.name, type);
      }
      await box.close();
      box = await Hive.openBox<ItemType>('item_types');
      for (final type in ItemType.values) {
        expect(box.get(type.name), type);
      }
      await box.close();
    } finally {
      await Hive.deleteFromDisk();
      await directory.delete(recursive: true);
    }
  });

  test('adapters compare by type ID', () {
    expect(ItemTypeAdapter().typeId, 10);
    expect(ItemTypeAdapter(), ItemTypeAdapter());
    expect(ItemTypeAdapter().hashCode, ItemTypeAdapter().hashCode);
    expect(ItemTypeAdapter(), isNot(equals(Object())));
  });
}
