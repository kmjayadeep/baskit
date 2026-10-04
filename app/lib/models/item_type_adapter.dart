import 'package:hive/hive.dart';

import 'shopping_item_model.dart';

/// Hive adapter for the [ItemType] enum.
class ItemTypeAdapter extends TypeAdapter<ItemType> {
  @override
  final int typeId = 10;

  @override
  ItemType read(BinaryReader reader) {
    final index = reader.readByte();
    return ItemType.values[index];
  }

  @override
  void write(BinaryWriter writer, ItemType obj) {
    writer.writeByte(obj.index);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
