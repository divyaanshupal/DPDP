import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kyrotics/features/documents/model/local_document_model.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:kyrotics/Widgets/cool_toast.dart';


class DocumentViewerScreen extends StatelessWidget {
  final LocalDocument document;

  const DocumentViewerScreen({super.key, required this.document});


  Future<void> _downloadDocument(BuildContext context) async {
    final canDownload = document.requestType == 'download';
    
    if (!canDownload) {
      if (context.mounted) {
        CoolToast.error(context, 'This document is view-only. Download is not permitted.');
      }
      return;
    }

    try {
      // Get temporary directory to save file temporarily before showing save dialog
      final tempDir = await getTemporaryDirectory();
      
      // Create file with proper extension
      final fileName = document.name.contains('.') 
          ? document.name 
          : '${document.name}.${document.fileType}';
      final tempFilePath = '${tempDir.path}/$fileName';
      
      // Write file data to temporary location
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(document.data);
      
      // Use flutter_file_dialog to save the file (shows native save dialog)
      final params = SaveFileDialogParams(
        sourceFilePath: tempFilePath,
        fileName: fileName,
      );
      
      final savedFilePath = await FlutterFileDialog.saveFile(params: params);
      
      if (savedFilePath != null && context.mounted) {
        // Show success toast with file path
        CoolToast.success(
          context,
          'File saved successfully!\nPath: $savedFilePath',
        );
        debugPrint('File saved to: $savedFilePath');
      } else if (context.mounted) {
        // User cancelled the save dialog
        CoolToast.info(context, 'Download cancelled');
      }
      
      // Clean up temporary file
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        debugPrint('Error cleaning up temp file: $e');
      }
    } catch (e) {
      if (context.mounted) {
        CoolToast.error(
          context,
          'Error downloading file: $e',
        );
      }
      debugPrint('Download error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDownload = document.requestType == 'download';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(document.name),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (canDownload)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadDocument(context),
              tooltip: 'Download document',
            )
          else
            Tooltip(
              message: 'View Only - Download not permitted',
              child: IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: null,
                tooltip: 'View Only',
              ),
            ),
        ],
      ),
      body: Center(
        child: _buildDocumentView(),
      ),
    );
  }

  Widget _buildDocumentView() {
    // Check the file type to decide which viewer to use
    if (document.fileType == 'pdf') {
      // This is the only part that changes
      return PDFView(
        pdfData: document.data, // Use the pdfData property
        enableSwipe: true,
        swipeHorizontal: true,
      );
    } else if (['jpg', 'jpeg', 'png'].contains(document.fileType)) {
      return Image.memory(document.data);
    } else {
      return Text('Unsupported file type: .${document.fileType}');
    }
  }
}