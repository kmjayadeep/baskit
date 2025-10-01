// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_member_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ListMemberAdapter extends TypeAdapter<ListMember> {
  @override
  final int typeId = 5;

  @override
  ListMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ListMember(
      userId: fields[0] as String,
      displayName: fields[1] as String,
      email: fields[2] as String?,
      avatarUrl: fields[3] as String?,
      role: fields[4] as MemberRole,
      joinedAt: fields[5] as DateTime,
      isActive: fields[6] as bool,
      permissions: (fields[7] as Map).cast<String, bool>(),
    );
  }

  @override
  void write(BinaryWriter writer, ListMember obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.avatarUrl)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.joinedAt)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.permissions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MemberRoleAdapter extends TypeAdapter<MemberRole> {
  @override
  final int typeId = 4;

  @override
  MemberRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MemberRole.owner;
      case 1:
        return MemberRole.member;
      default:
        return MemberRole.owner;
    }
  }

  @override
  void write(BinaryWriter writer, MemberRole obj) {
    switch (obj) {
      case MemberRole.owner:
        writer.writeByte(0);
        break;
      case MemberRole.member:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
