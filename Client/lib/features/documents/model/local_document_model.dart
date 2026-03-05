import 'dart:convert';
import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'local_document_model.g.dart';

@HiveType(typeId: 3) // <-- Use a new, unique typeId
class LocalDocument extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final Uint8List data;

  @HiveField(2)
  final String fileType; // e.g., 'pdf', 'jpg'

  @HiveField(3)
  final DateTime? expirationTime; // When this file access expires

  @HiveField(4)
  final String? sharingSessionId; // Link to sharing session

  @HiveField(5)
  final bool? isSharedFile; // True if received via sharing, false if uploaded by user

  @HiveField(6)
  final String? requestType; // 'view' or 'download' - indicates if document can be downloaded or only viewed

  @HiveField(7)
  final String? senderUuid; // UUID of the sender (for received files)

  @HiveField(8)
  final String? senderName; // Name of the sender (for received files)

  @HiveField(9)
  final DateTime? receivedAt; // When the document was received

  LocalDocument({
    required this.name,
    required this.data,
    required this.fileType,
    this.expirationTime,
    this.sharingSessionId,
    this.isSharedFile,
    this.requestType,
    this.senderUuid,
    this.senderName,
    this.receivedAt,
  });

Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fileType': fileType,
      'data': base64Encode(data), // Encode bytes to a Base64 string
      'expirationTime': expirationTime?.toIso8601String(),
      'sharingSessionId': sharingSessionId,
      'isSharedFile': isSharedFile,
      'requestType': requestType,
      'senderUuid': senderUuid,
      'senderName': senderName,
      'receivedAt': receivedAt?.toIso8601String(),
    };
  }

  factory LocalDocument.fromJson(Map<String, dynamic> json) {
    return LocalDocument(
      name: json['name'],
      fileType: json['fileType'],
      data: base64Decode(json['data']), // Decode Base64 string back to bytes
      expirationTime: json['expirationTime'] != null 
          ? DateTime.parse(json['expirationTime']) 
          : null,
      sharingSessionId: json['sharingSessionId'],
      isSharedFile: json['isSharedFile'],
      requestType: json['requestType'],
      senderUuid: json['senderUuid'],
      senderName: json['senderName'],
      receivedAt: json['receivedAt'] != null 
          ? DateTime.parse(json['receivedAt']) 
          : null,
    );
  }
}