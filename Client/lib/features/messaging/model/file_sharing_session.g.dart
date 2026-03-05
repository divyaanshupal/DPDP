// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_sharing_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FileSharingSessionAdapter extends TypeAdapter<FileSharingSession> {
  @override
  final int typeId = 4;

  @override
  FileSharingSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FileSharingSession(
      sessionId: fields[0] as String,
      senderUuid: fields[1] as String,
      receiverUuid: fields[2] as String,
      requestedDocuments: (fields[3] as List).cast<String>(),
      expirationTime: fields[4] as DateTime,
      createdAt: fields[5] as DateTime,
      status: fields[6] as SharingStatus,
      note: fields[7] as String?,
      acceptedAt: fields[8] as DateTime?,
      completedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FileSharingSession obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.senderUuid)
      ..writeByte(2)
      ..write(obj.receiverUuid)
      ..writeByte(3)
      ..write(obj.requestedDocuments)
      ..writeByte(4)
      ..write(obj.expirationTime)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.acceptedAt)
      ..writeByte(9)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileSharingSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SharingStatusAdapter extends TypeAdapter<SharingStatus> {
  @override
  final int typeId = 5;

  @override
  SharingStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SharingStatus.pending;
      case 1:
        return SharingStatus.accepted;
      case 2:
        return SharingStatus.expired;
      case 3:
        return SharingStatus.completed;
      case 4:
        return SharingStatus.rejected;
      default:
        return SharingStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SharingStatus obj) {
    switch (obj) {
      case SharingStatus.pending:
        writer.writeByte(0);
        break;
      case SharingStatus.accepted:
        writer.writeByte(1);
        break;
      case SharingStatus.expired:
        writer.writeByte(2);
        break;
      case SharingStatus.completed:
        writer.writeByte(3);
        break;
      case SharingStatus.rejected:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharingStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
