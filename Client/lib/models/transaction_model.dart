class RequestedDocument {
  final String name;
  final String fileType;
  final String requestType; // 'view' or 'download'

  RequestedDocument({
    required this.name,
    required this.fileType,
    required this.requestType,
  });

  factory RequestedDocument.fromJson(Map<String, dynamic> json) {
    return RequestedDocument(
      name: json['name'] ?? '',
      fileType: json['fileType'] ?? 'unknown',
      requestType: json['requestType'] ?? 'view',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fileType': fileType,
      'requestType': requestType,
    };
  }
}

class DocumentTransaction {
  final String id;
  final String senderUuid;
  final String senderName;
  final String receiverUuid;
  final String receiverName;
  final List<RequestedDocument> requestedDocuments;
  final String? note;
  final int expirationDays;
  final String status; // 'pending', 'accepted', 'rejected', 'completed', 'expired'
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final int totalDocumentsRequested;
  final int documentsReceivedCount;

  DocumentTransaction({
    required this.id,
    required this.senderUuid,
    required this.senderName,
    required this.receiverUuid,
    required this.receiverName,
    required this.requestedDocuments,
    this.note,
    required this.expirationDays,
    required this.status,
    required this.requestedAt,
    this.respondedAt,
    this.completedAt,
    this.expiresAt,
    required this.totalDocumentsRequested,
    required this.documentsReceivedCount,
  });

  factory DocumentTransaction.fromJson(Map<String, dynamic> json) {
    return DocumentTransaction(
      id: json['_id'] ?? json['id'] ?? '',
      senderUuid: json['senderUuid'] ?? '',
      senderName: json['senderName'] ?? '',
      receiverUuid: json['receiverUuid'] ?? '',
      receiverName: json['receiverName'] ?? '',
      requestedDocuments: (json['requestedDocuments'] as List<dynamic>?)
              ?.map((doc) => RequestedDocument.fromJson(doc))
              .toList() ??
          [],
      note: json['note'],
      expirationDays: json['expirationDays'] ?? 7,
      status: json['status'] ?? 'pending',
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'])
          : DateTime.now(),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      totalDocumentsRequested: json['totalDocumentsRequested'] ?? 0,
      documentsReceivedCount: json['documentsReceivedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderUuid': senderUuid,
      'senderName': senderName,
      'receiverUuid': receiverUuid,
      'receiverName': receiverName,
      'requestedDocuments': requestedDocuments.map((doc) => doc.toJson()).toList(),
      'note': note,
      'expirationDays': expirationDays,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'totalDocumentsRequested': totalDocumentsRequested,
      'documentsReceivedCount': documentsReceivedCount,
    };
  }
}

