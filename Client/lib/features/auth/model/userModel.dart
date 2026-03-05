class UserModel {
  final String uuid;
  final String name;
  final String phone;
  final List<DocumentInfo> documents;

  UserModel({
    required this.uuid,
    required this.name,
    required this.phone,
    // ✨ ADDED: Make it required in the constructor.
    required this.documents,
  });

  /// Creates a UserModel object from a JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // ✨ ADDED: Logic to parse the list of documents from the JSON.
    // We check if 'documents' exists and is a list; otherwise, we default to an empty list.
    // This makes the model backward-compatible.
    var documentsList = <DocumentInfo>[];
    if (json['documents'] != null && json['documents'] is List) {
      documentsList = (json['documents'] as List)
          .map((docJson) => DocumentInfo.fromJson(docJson))
          .toList();
    }

    return UserModel(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      // The public profile endpoint doesn't return a phone, so this will correctly default to ''.
      phone: json['phone'] ?? '',
      // ✨ ADDED: Assign the parsed documents list.
      documents: documentsList,
    );
  }

  /// Converts a UserModel object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'phone': phone,
      // ✨ ADDED: Convert the list of DocumentInfo objects back to a list of JSON maps.
      'documents': documents.map((doc) => doc.toJson()).toList(),
    };
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
}