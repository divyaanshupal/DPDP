class UserModel {
  final String uuid;          // UUID (User ID)
  final String name;          // Name
  final String? email;        // Mail ID (Optional)
  final String? phone;        // Phone Number (Optional)
  final DateTime? dob;        // Date of Birth (Optional)
  final String gender;        // Gender
  final String? address;      // Address (Optional)
  final List<DocumentInfo> documents; // Documents array

  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uuid,
    required this.name,
    this.email,
    this.phone,
    this.dob,
    required this.gender,
    this.address,
    required this.documents,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse documents array
    var documentsList = <DocumentInfo>[];
    if (json['documents'] != null && json['documents'] is List) {
      documentsList = (json['documents'] as List)
          .map((docJson) => DocumentInfo.fromJson(docJson))
          .toList();
    }

    return UserModel(
      uuid: json['uuid'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
      gender: json['gender'] ?? '',
      address: json['address'],
      documents: documentsList,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'email': email,
      'phone': phone,
      'dob': dob?.toIso8601String(),
      'gender': gender,
      'address': address,
      'documents': documents.map((doc) => doc.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uuid,
    String? name,
    String? email,
    String? phone,
    DateTime? dob,
    String? gender,
    String? address,
    List<DocumentInfo>? documents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uuid: $uuid, name: $name, email: $email, phone: $phone, dob: $dob, gender: $gender, address: $address, documents: ${documents.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uuid == uuid &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.dob == dob &&
        other.gender == gender &&
        other.address == address &&
        other.documents.length == documents.length;
  }

  @override
  int get hashCode {
    return uuid.hashCode ^
        name.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        dob.hashCode ^
        gender.hashCode ^
        address.hashCode ^
        documents.length.hashCode;
  }
}

/// Represents a single document's information.
class DocumentInfo {
  final String name;
  final String fileType;

  DocumentInfo({required this.name, required this.fileType});

  /// Creates a DocumentInfo object from a JSON map.
  factory DocumentInfo.fromJson(Map<String, dynamic> json) {
    return DocumentInfo(
      name: json['name'] ?? '',
      fileType: json['fileType'] ?? '',
    );
  }

  /// Converts a DocumentInfo object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fileType': fileType,
    };
  }

  @override
  String toString() {
    return 'DocumentInfo(name: $name, fileType: $fileType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentInfo &&
        other.name == name &&
        other.fileType == fileType;
  }

  @override
  int get hashCode {
    return name.hashCode ^ fileType.hashCode;
  }
}
