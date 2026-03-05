import 'package:hive/hive.dart';

part 'file_sharing_session.g.dart';

@HiveType(typeId: 4)
class FileSharingSession extends HiveObject {
  @HiveField(0)
  final String sessionId;

  @HiveField(1)
  final String senderUuid;

  @HiveField(2)
  final String receiverUuid;

  @HiveField(3)
  final List<String> requestedDocuments;

  @HiveField(4)
  final DateTime expirationTime;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final SharingStatus status;

  @HiveField(7)
  final String? note;

  @HiveField(8)
  final DateTime? acceptedAt;

  @HiveField(9)
  final DateTime? completedAt;

  FileSharingSession({
    required this.sessionId,
    required this.senderUuid,
    required this.receiverUuid,
    required this.requestedDocuments,
    required this.expirationTime,
    required this.createdAt,
    required this.status,
    this.note,
    this.acceptedAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'senderUuid': senderUuid,
      'receiverUuid': receiverUuid,
      'requestedDocuments': requestedDocuments,
      'expirationTime': expirationTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'note': note,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory FileSharingSession.fromJson(Map<String, dynamic> json) {
    return FileSharingSession(
      sessionId: json['sessionId'],
      senderUuid: json['senderUuid'],
      receiverUuid: json['receiverUuid'],
      requestedDocuments: List<String>.from(json['requestedDocuments']),
      expirationTime: DateTime.parse(json['expirationTime']),
      createdAt: DateTime.parse(json['createdAt']),
      status: SharingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SharingStatus.pending,
      ),
      note: json['note'],
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }

  FileSharingSession copyWith({
    String? sessionId,
    String? senderUuid,
    String? receiverUuid,
    List<String>? requestedDocuments,
    DateTime? expirationTime,
    DateTime? createdAt,
    SharingStatus? status,
    String? note,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) {
    return FileSharingSession(
      sessionId: sessionId ?? this.sessionId,
      senderUuid: senderUuid ?? this.senderUuid,
      receiverUuid: receiverUuid ?? this.receiverUuid,
      requestedDocuments: requestedDocuments ?? this.requestedDocuments,
      expirationTime: expirationTime ?? this.expirationTime,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      note: note ?? this.note,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expirationTime);
  bool get isActive => status == SharingStatus.accepted && !isExpired;
  Duration get timeRemaining => expirationTime.difference(DateTime.now());
}

@HiveType(typeId: 5)
enum SharingStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  accepted,
  @HiveField(2)
  expired,
  @HiveField(3)
  completed,
  @HiveField(4)
  rejected,
}
