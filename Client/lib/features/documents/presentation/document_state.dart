import 'package:flutter/foundation.dart';
import 'package:kyrotics/features/documents/model/local_document_model.dart';

// Enum to represent the sync status of a document
enum SyncedStatus { available, expired }

// A model that combines server info with local data
class SyncedDocument {
  final String name;
  final String fileType;
  final SyncedStatus status;
  final LocalDocument? localDocument; // Will be null if expired

  SyncedDocument({
    required this.name,
    required this.fileType,
    required this.status,
    this.localDocument,
  });
}

// The overall state for our screen's UI
@immutable
class DocumentsState {
  final bool isLoading;
  final String? error;
  final List<SyncedDocument> documents;

  const DocumentsState({
    this.isLoading = false,
    this.error,
    this.documents = const [],
  });

  // Helper method to create copies of the state
  DocumentsState copyWith({
    bool? isLoading,
    String? error,
    List<SyncedDocument>? documents,
  }) {
    return DocumentsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      documents: documents ?? this.documents,
    );
  }
}