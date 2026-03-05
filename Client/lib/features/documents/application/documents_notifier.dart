import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:kyrotics/features/documents/model/local_document_model.dart';
import 'package:kyrotics/features/documents/presentation/document_state.dart';
import 'package:kyrotics/services/api_service.dart';
import 'package:kyrotics/services/webrtcController.dart';

// This provider definition is correct.
final documentsProvider = StateNotifierProvider<DocumentsNotifier, DocumentsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final webrtcController = ref.watch(webrtcProvider);
  return DocumentsNotifier(apiService, webrtcController);
});

class DocumentsNotifier extends StateNotifier<DocumentsState> {
  final ApiService _apiService;
  final WebRTCController _webrtcController;

  DocumentsNotifier(this._apiService, this._webrtcController) : super(const DocumentsState());

  /// Ensures the user-specific documents box is opened
  Future<Box<LocalDocument>> _getUserDocumentsBox(String uuid) async {
    try {
      return Hive.box<LocalDocument>('documents_$uuid');
    } catch (e) {
      // If box doesn't exist, open it
      return await Hive.openBox<LocalDocument>('documents_$uuid');
    }
  }

  /// Fetches the master document list from the server and syncs it with local Hive data.
  Future<void> fetchAndSyncDocuments() async {
    log("called fetch and syncdocuments");
    state = state.copyWith(isLoading: true, error: null);

    final uuid = _webrtcController.selfUuid;
    if (uuid == null) {
      state = state.copyWith(isLoading: false, error: "User is not signed in.");
      return;
    }

    try {
      // 1. Fetch the official document list from the backend
      final userProfile = await _apiService.searchUser(uuid);
      if (userProfile == null) {
        // If the profile is null, it might be a new user. Show an empty list.
        state = state.copyWith(isLoading: false, documents: []);
        return;
      }
      final serverDocs = userProfile.documents;

      // 2. Open the user-specific Hive box
      final box = await _getUserDocumentsBox(uuid);
      // Only get user-owned documents (not received files)
      final userOwnedDocs = box.values
          .where((doc) => doc.isSharedFile != true)
          .toList();

      // 3. Sync server list with local user-owned documents only
      final List<SyncedDocument> syncedList = [];
      for (final serverDoc in serverDocs) {
        // Find a local user-owned document with the same name
        final localMatch = userOwnedDocs.firstWhere(
          (local) => local.name == serverDoc.name,
          // Create a temporary non-matching object if not found
          orElse: () => LocalDocument(name: 'not-found', data: Uint8List(0), fileType: ''),
        );

        if (localMatch.name != 'not-found') {
          // MATCH FOUND: The document is available locally
          syncedList.add(SyncedDocument(
            name: serverDoc.name,
            fileType: serverDoc.fileType,
            status: SyncedStatus.available,
            localDocument: localMatch,
          ));
        } else {
          // NO MATCH: The document is "expired" or missing from this device
          syncedList.add(SyncedDocument(
            name: serverDoc.name,
            fileType: serverDoc.fileType,
            status: SyncedStatus.expired,
          ));
        }
      }

      state = state.copyWith(isLoading: false, documents: syncedList);

    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Re-uploads the file data for a document that already exists on the server profile.
  Future<void> resyncExpiredDocument(String documentName, String fileType) async {
    // Note: Removed BuildContext. Error handling should be done in the UI.
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null) return; // User canceled picker

      final file = result.files.single;
      Uint8List? fileBytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);

      if (fileBytes == null) throw Exception("Could not read file data.");

      final updatedDocument = LocalDocument(
        name: documentName,
        data: fileBytes,
        fileType: file.extension?.toLowerCase() ?? fileType,
      );

      final box = await _getUserDocumentsBox(_webrtcController.selfUuid!);
      
      // Find and delete any old entry with the same name before adding the new one.
      final existingKey = box.keys.firstWhere((key) {
        final doc = box.get(key);
        return doc?.name == documentName;
      }, orElse: () => null);

      if (existingKey != null) {
        await box.delete(existingKey);
      }
      
      await box.add(updatedDocument);

      // ✅ CORRECTION: The refresh call does not take parameters.
      await fetchAndSyncDocuments();

    } catch (e) {
      // Re-throw the error to be caught in the UI for showing a SnackBar.
      rethrow;
    }
  }

  /// Adds a completely new document, saves to Hive, and syncs the new list to the backend.
  /// If [predefinedDocumentName] is provided, uses that name without showing dialog.
  /// If [predefinedDocumentName] is null, shows dialog for custom document name.
  Future<void> addNewDocument(BuildContext context, {String? predefinedDocumentName}) async {
    // This method needs context to show the name dialog for custom documents.
    final uuid = _webrtcController.selfUuid;
    if (uuid == null) throw Exception("Cannot add document: User not signed in.");

    try {
      // 1. Pick the file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null) return;

      final file = result.files.single;
      Uint8List? fileBytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (fileBytes == null) throw Exception("Could not read file data.");
      
      // 2. Get document name - either use predefined or show dialog for custom
      String? documentName;
      
      if (predefinedDocumentName != null && predefinedDocumentName.isNotEmpty) {
        // Use predefined document name
        documentName = predefinedDocumentName;
      } else {
        // Show dialog for custom document name
        final docNameController = TextEditingController();
        documentName = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enter Document Name'),
            content: TextField(
              controller: docNameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'e.g., Passport'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, docNameController.text.trim()), child: const Text('Save')),
            ],
          ),
        );
      }

      if (documentName == null || documentName.isEmpty) return;

      // 3. Save the new document locally to Hive
      final newDocument = LocalDocument(
        name: documentName,
        data: fileBytes,
        fileType: file.extension?.toLowerCase() ?? 'unknown',
      );
      final box = await _getUserDocumentsBox(uuid);
      await box.add(newDocument);

      // 4. Sync only user-owned documents to the backend (filter out shared files)
      final userOwnedDocs = box.values
          .where((doc) => doc.isSharedFile != true) // Only user's own documents
          .toList();

      await _apiService.syncLocalDocumentsToBackend(
        uuid: uuid,
        localDocs: userOwnedDocs, // Only user's own documents
      );

      // 5. Refresh the UI from the server's source of truth
      await fetchAndSyncDocuments();

    } catch (e) {
      rethrow;
    }
  }
}