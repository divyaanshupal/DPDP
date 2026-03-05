import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  Map<String, List<LocalDocument>> _groupedBySender = {};

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

    // Group received documents by sender
    final receivedDocs = _documentsBox!.values
        .where((doc) => doc.isSharedFile == true)
        .toList();

    final grouped = <String, List<LocalDocument>>{};
    for (var doc in receivedDocs) {
      // Use sender UUID as key, fallback to 'Unknown' if not available
      final senderKey = doc.senderUuid ?? doc.senderName ?? 'Unknown';
      grouped.putIfAbsent(senderKey, () => []).add(doc);
    }

    setState(() {
      _groupedBySender = grouped;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Listen to WebRTC controller changes to refresh when new files are received
    ref.listen<WebRTCController>(webrtcProvider, (previous, next) {
      if (previous?.receivedDocuments.length != next.receivedDocuments.length) {
        _loadReceivedDocuments();
      }
    });

    final fileAccessService = ref.watch(fileAccessServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Received Files'),
        backgroundColor: const Color(0xFF5170FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReceivedDocuments,
          ),
        ],
      ),
      body: _groupedBySender.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.download_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No received files yet',
                    style: TextStyle(fontSize: 18.sp, color: Colors.grey),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Files you receive from others will appear here',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                _loadReceivedDocuments();
              },
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: _groupedBySender.length,
                itemBuilder: (context, index) {
                  final senderKey = _groupedBySender.keys.elementAt(index);
                  final documents = _groupedBySender[senderKey]!;
                  final firstDoc = documents.first;
                  final senderName = firstDoc.senderName ?? 'Unknown';

                  // Count view-only vs downloadable
                  final viewOnlyCount =
                      documents.where((d) => d.requestType == 'view').length;
                  final downloadCount =
                      documents.where((d) => d.requestType == 'download').length;

                  return Card(
                    margin: EdgeInsets.only(bottom: 16.h),
                    elevation: 2,
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF5170FF),
                        child: Text(
                          senderName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        senderName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4.h),
                          Text(
                            '${documents.length} document(s)',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              if (viewOnlyCount > 0)
                                Row(
                                  children: [
                                    Icon(Icons.visibility,
                                        size: 14.sp, color: Colors.blue),
                                    SizedBox(width: 4.w),
                                    Text('$viewOnlyCount View Only',
                                        style: TextStyle(fontSize: 12.sp)),
                                  ],
                                ),
                              if (viewOnlyCount > 0 && downloadCount > 0)
                                SizedBox(width: 12.w),
                              if (downloadCount > 0)
                                Row(
                                  children: [
                                    Icon(Icons.download,
                                        size: 14.sp, color: Colors.green),
                                    SizedBox(width: 4.w),
                                    Text('$downloadCount Downloadable',
                                        style: TextStyle(fontSize: 12.sp)),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                      children: documents.map((doc) {
                        final isAccessible =
                            fileAccessService.isFileAccessible(doc);
                        final timeRemaining =
                            fileAccessService.getTimeRemaining(doc);
                        final status = fileAccessService.getFileStatus(doc);
                        final isDownloadable =
                            doc.requestType == 'download' && isAccessible;

                        return ListTile(
                          leading: Icon(
                            doc.fileType == 'pdf'
                                ? Icons.picture_as_pdf
                                : Icons.image,
                            color: isAccessible
                                ? (isDownloadable ? Colors.green : Colors.blue)
                                : Colors.grey,
                          ),
                          title: Text(
                            doc.name,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: isAccessible ? null : Colors.grey,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4.h),
                              // Request type badge
                              Row(
                                children: [
                                  Icon(
                                    doc.requestType == 'download'
                                        ? Icons.download
                                        : Icons.visibility,
                                    size: 12.sp,
                                    color: doc.requestType == 'download'
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    doc.requestType == 'download'
                                        ? 'Downloadable'
                                        : 'View Only',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: doc.requestType == 'download'
                                          ? Colors.green
                                          : Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              // Expiration status
                              if (status == FileAccessStatus.expired)
                                Text(
                                  '❌ EXPIRED',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else if (status == FileAccessStatus.expiringSoon)
                                Text(
                                  '⚠️ Expires in ${fileAccessService.formatTimeRemaining(timeRemaining!)}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              else if (status == FileAccessStatus.active)
                                Text(
                                  '⏰ Expires in ${fileAccessService.formatTimeRemaining(timeRemaining!)}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (doc.receivedAt != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 4.h),
                                  child: Text(
                                    'Received: ${_formatDate(doc.receivedAt)}',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: isAccessible
                              ? (isDownloadable
                                  ? IconButton(
                                      icon: const Icon(Icons.download,
                                          color: Colors.green),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DocumentViewerScreen(
                                                document: doc),
                                          ),
                                        );
                                      },
                                    )
                                  : const Icon(Icons.visibility,
                                      color: Colors.blue))
                              : const Icon(Icons.block, color: Colors.red),
                          onTap: isAccessible
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DocumentViewerScreen(document: doc),
                                    ),
                                  );
                                }
                              : null,
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

