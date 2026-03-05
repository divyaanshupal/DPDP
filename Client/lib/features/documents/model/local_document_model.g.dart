// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_document_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalDocumentAdapter extends TypeAdapter<LocalDocument> {
  @override
  final int typeId = 3;

  @override
  LocalDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalDocument(
      name: fields[0] as String,
      data: fields[1] as Uint8List,
      fileType: fields[2] as String,
      expirationTime: fields[3] as DateTime?,
      sharingSessionId: fields[4] as String?,
      isSharedFile: fields[5] as bool?,
      requestType: fields[6] as String?,
      senderUuid: fields[7] as String?,
      senderName: fields[8] as String?,
      receivedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalDocument obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.data)
      ..writeByte(2)
      ..write(obj.fileType)
      ..writeByte(3)
      ..write(obj.expirationTime)
      ..writeByte(4)
      ..write(obj.sharingSessionId)
      ..writeByte(5)
      ..write(obj.isSharedFile)
      ..writeByte(6)
      ..write(obj.requestType)
      ..writeByte(7)
      ..write(obj.senderUuid)
      ..writeByte(8)
      ..write(obj.senderName)
      ..writeByte(9)
      ..write(obj.receivedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
