// ✨ OLD CODE - COMMENTED OUT - NEW CODE IS IN approved_new.dart
// This file has been replaced with a new implementation that groups received files by sender.
// The new code is in approved_new.dart. This old code is kept for reference.

/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:kyrotics/features/documents/model/local_document_model.dart';
import 'package:kyrotics/features/documents/presentation/document-viewer.dart';
import 'package:kyrotics/services/file_access_service.dart';
import 'package:kyrotics/services/webrtcController.dart';

class ApprovedScreen extends ConsumerStatefulWidget {
  const ApprovedScreen({super.key});

  @override
  ConsumerState<ApprovedScreen> createState() => _ApprovedScreenState();
}

class _ApprovedScreenState extends ConsumerState<ApprovedScreen> {
  Box<LocalDocument>? _documentsBox;
  List<LocalDocument> _receivedDocuments = [];

  @override
  void initState() {
    super.initState();
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    final webrtcController = ref.read(webrtcProvider);
    final uuid = webrtcController.selfUuid;
    
    if (uuid != null) {
      try {
        _documentsBox = Hive.box<LocalDocument>('documents_$uuid');
      } catch (e) {
        _documentsBox = await Hive.openBox<LocalDocument>('documents_$uuid');
      }
      _loadReceivedDocuments();
    }
  }

  void _loadReceivedDocuments() {
    if (_documentsBox == null) return;
    
    setState(() {
      _receivedDocuments = _documentsBox!.values
          .where((doc) => doc.isSharedFile == true) // Only shared files
          .toList();
      
      // Debug logging
      print('🔍 [Received Tab] Total documents in Hive: ${_documentsBox!.length}');
      print('🔍 [Received Tab] Shared files found: ${_receivedDocuments.length}');
      for (var doc in _receivedDocuments) {
        print('🔍 [Received Tab] - ${doc.name} (isSharedFile: ${doc.isSharedFile}, expiration: ${doc.expirationTime})');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to WebRTC controller changes to refresh when new files are received
    ref.listen<WebRTCController>(webrtcProvider, (previous, next) {
      if (previous?.receivedDocuments.length != next.receivedDocuments.length) {
        print('🔄 [Received Tab] New files detected, refreshing...');
        _loadReceivedDocuments();
      }
    });

    final fileAccessService = ref.watch(fileAccessServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Received Documents'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔍 [Debug] Manual refresh triggered');
              _loadReceivedDocuments();
            },
          ),
        ],
      ),
      body: _receivedDocuments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.download_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No received documents yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Files you receive from others will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  // Debug button to test UI
                  ElevatedButton(
                    onPressed: () {
                      print('🔍 [Debug] Manually refreshing received documents...');
                      _loadReceivedDocuments();
                    },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Debug info and refresh button
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Received: ${_receivedDocuments.length} files',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          print('🔍 [Debug] Manual refresh triggered');
                          _loadReceivedDocuments();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        child: const Text('Refresh', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                // Main list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _loadReceivedDocuments();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _receivedDocuments.length,
                      itemBuilder: (context, index) {
                        final doc = _receivedDocuments[index];
                        final isAccessible = fileAccessService.isFileAccessible(doc);
                        final timeRemaining = fileAccessService.getTimeRemaining(doc);
                        final status = fileAccessService.getFileStatus(doc);

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(
                              doc.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                              color: isAccessible ? Colors.deepPurple : Colors.grey,
                            ),
                            title: Text(
                              doc.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isAccessible ? null : Colors.grey,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Expiration status with color coding
                                if (status == FileAccessStatus.expired)
                                  const Text(
                                    '❌ EXPIRED',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  )
                                else if (status == FileAccessStatus.expiringSoon)
                                  Text(
                                    '⚠️ Expires in ${fileAccessService.formatTimeRemaining(timeRemaining!)}',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  )
                                else if (status == FileAccessStatus.active)
                                  Text(
                                    '⏰ Expires in ${fileAccessService.formatTimeRemaining(timeRemaining!)}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                // Request type badge
                                Row(
                                  children: [
                                    Icon(
                                      doc.requestType == 'download' ? Icons.download : Icons.visibility,
                                      size: 14,
                                      color: doc.requestType == 'download' ? Colors.green : Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      doc.requestType == 'download' ? 'Downloadable' : 'View Only',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: doc.requestType == 'download' ? Colors.green : Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Action text
                                Text(
                                  isAccessible ? 'Tap to view' : 'File no longer accessible',
                                  style: TextStyle(
                                    color: isAccessible ? Colors.blue : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            onTap: isAccessible ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DocumentViewerScreen(document: doc),
                                ),
                              );
                            } : null,
                            trailing: isAccessible 
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (doc.requestType == 'download')
                                        IconButton(
                                          icon: const Icon(Icons.download, size: 20),
                                          color: Colors.green,
                                          onPressed: () {
                                            // Open document viewer which will handle download
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => DocumentViewerScreen(document: doc),
                                              ),
                                            );
                                          },
                                          tooltip: 'Download',
                                        ),
                                      const Icon(Icons.arrow_forward_ios, size: 16),
                                    ],
                                  )
                                : const Icon(Icons.block, color: Colors.red, size: 16),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
*/

// ✨ NEW CODE - Import from approved_new.dart
export 'approved_new.dart';