import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:kyrotics/features/documents/model/local_document_model.dart';
import 'package:kyrotics/services/webrtcController.dart';

class IncomingRequestDialog extends ConsumerStatefulWidget {
  final String fromUuid;
  final String fromName; // ✨ NEW: Sender's name
  final String note;
  final List<String> requestedDocs;
  final Map<String, String> requestTypes; // ✨ NEW: docName -> 'view' or 'download'
  final int expirationDays; // ✨ NEW: Expiration time in days

  const IncomingRequestDialog({
    super.key,
    required this.fromUuid,
    required this.fromName, // ✨ NEW: Required sender's name
    required this.note,
    required this.requestedDocs,
    required this.requestTypes, // ✨ NEW: Required request types
    required this.expirationDays, // ✨ NEW: Required expiration days
  });

  @override
  ConsumerState<IncomingRequestDialog> createState() => _IncomingRequestDialogState();
}

class _IncomingRequestDialogState extends ConsumerState<IncomingRequestDialog> {
  late Map<String, bool> _docStatus;
  bool _allFilesFound = false;
  bool _isConnecting = false;
  Map<String, String?> _docApprovalStatus = {}; // 'approved', 'rejected', or null

  @override
  void initState() {
    super.initState();
    _checkLocalFiles();
  }

  void _checkLocalFiles() async {
    final webrtcController = ref.read(webrtcProvider);
    final uuid = webrtcController.selfUuid;
    
    if (uuid == null) return;
    
    try {
      final box = Hive.box<LocalDocument>('documents_$uuid');
      final localDocNames = box.values.map((e) => e.name).toSet();
      final status = <String, bool>{};
      for (final requestedName in widget.requestedDocs) {
        status[requestedName] = localDocNames.contains(requestedName);
      }
      setState(() {
        _docStatus = status;
        _allFilesFound = status.values.every((found) => found == true);
        // Initialize approval status as null for all documents
        _docApprovalStatus = Map.fromEntries(
          widget.requestedDocs.map((doc) => MapEntry(doc, null)),
        );
      });
    } catch (e) {
      // If box doesn't exist, open it
      final box = await Hive.openBox<LocalDocument>('documents_$uuid');
      final localDocNames = box.values.map((e) => e.name).toSet();
      final status = <String, bool>{};
      for (final requestedName in widget.requestedDocs) {
        status[requestedName] = localDocNames.contains(requestedName);
      }
      setState(() {
        _docStatus = status;
        _allFilesFound = status.values.every((found) => found == true);
        // Initialize approval status as null for all documents
        _docApprovalStatus = Map.fromEntries(
          widget.requestedDocs.map((doc) => MapEntry(doc, null)),
        );
      });
    }
  }

  // ✨ NEW: Approve document
  void _approveDocument(String fileName) {
    setState(() {
      _docApprovalStatus[fileName] = 'approved';
    });
  }

  // ✨ NEW: Reject document
  void _rejectDocument(String fileName) {
    setState(() {
      _docApprovalStatus[fileName] = 'rejected';
    });
  }

  // ✨ NEW: Get document icon based on name
  IconData _getDocumentIcon(String documentName) {
    final nameUpper = documentName.toUpperCase();
    if (nameUpper.contains('AADHAR') || nameUpper.contains('AADHAAR')) {
      return Icons.person;
    } else if (nameUpper.contains('PAN')) {
      return Icons.credit_card;
    } else if (nameUpper.contains('LICENSE') || nameUpper.contains('LICENCE')) {
      return Icons.drive_eta;
    } else if (nameUpper.contains('PASSPORT')) {
      return Icons.book;
    }
    return Icons.description;
  }

  // ✨ NEW: Get document icon color
  Color _getDocumentIconColor(String documentName) {
    final nameUpper = documentName.toUpperCase();
    if (nameUpper.contains('AADHAR') || nameUpper.contains('AADHAAR')) {
      return const Color(0xFF2196F3);
    } else if (nameUpper.contains('PAN')) {
      return const Color(0xFF2196F3);
    } else if (nameUpper.contains('LICENSE') || nameUpper.contains('LICENCE')) {
      return const Color(0xFF2196F3);
    } else if (nameUpper.contains('PASSPORT')) {
      return const Color(0xFF2196F3);
    }
    return const Color(0xFF2196F3);
  }

  // This method now ONLY starts the connection process.
  void _initiateConnection() {
    ref.read(webrtcProvider).acceptIncoming();
    setState(() {
      _isConnecting = true;
    });
  }

  // ✨ UPDATED: This method now sends only the approved files with expiration time
  void _sendFilesAndClose() {
    final approvedDocs = _docApprovalStatus.entries
        .where((entry) => entry.value == 'approved' && _docStatus[entry.key] == true)
        .map((entry) => entry.key)
        .toList();

    if (approvedDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please approve at least one file to send')),
      );
      return;
    }

    final webrtcController = ref.read(webrtcProvider);
    final uuid = webrtcController.selfUuid;
    
    if (uuid == null) return;
    
    final box = Hive.box<LocalDocument>('documents_$uuid');
    
    // ✨ FIX: Only get user-owned documents (not received/shared files)
    // For each approved document name, get only ONE document (the first match)
    // This prevents sending duplicate documents when multiple entries exist with the same name
    final originalDocs = <LocalDocument>[];
    final foundDocNames = <String>{};
    
    for (final doc in box.values) {
      // Only include user-owned documents (isSharedFile should be false or null)
      // We don't want to send back files that were received from others
      if (doc.isSharedFile == true) continue;
      
      // Only include approved documents
      if (!approvedDocs.contains(doc.name)) continue;
      
      // Only take the first document for each name (to avoid duplicates)
      // If there are multiple "PAN CARD" entries, we only send one
      if (!foundDocNames.contains(doc.name)) {
        originalDocs.add(doc);
        foundDocNames.add(doc.name);
      }
    }
    
    // ✨ NEW: Create new documents with expiration time and request type
    final docsToSend = originalDocs.map((originalDoc) {
      final expirationTime = DateTime.now().add(Duration(days: widget.expirationDays));
      return LocalDocument(
        name: originalDoc.name,
        fileType: originalDoc.fileType,
        data: originalDoc.data,
        expirationTime: expirationTime, // ✨ NEW: Set expiration time
        isSharedFile: false, // ✨ NEW: These are being shared, not received
        requestType: widget.requestTypes[originalDoc.name] ?? 'view', // ✨ NEW: Get request type from map, default to 'view'
      );
    }).toList();
    
    // ✨ FIX: Clear incoming request state immediately to prevent duplicate modal
    // This prevents the listener from showing the modal again after we close it
    webrtcController.clearIncomingRequest();
    
    if (docsToSend.isNotEmpty) {
      ref.read(webrtcProvider).sendDocuments(docsToSend);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sending ${docsToSend.length} file(s) with ${widget.expirationDays} days expiration...')),
      );
    }
    
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // ✨ We now WATCH the provider. The build method will re-run when its state changes.
    final webrtc = ref.watch(webrtcProvider);
    final isChannelOpen = webrtc.isDataChannelOpen;

    // ✨ STAGE 1: Before connection - Show summary with Connect/Reject buttons
    if (!isChannelOpen) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: EdgeInsets.only(top: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            // User Profile Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Row(
                children: [
                  // Profile Picture
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: const Color(0xFF666666),
                      size: 30.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // User Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.fromName} | ${widget.fromUuid.length >= 8 ? widget.fromUuid.substring(0, 8) : widget.fromUuid}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Institute name',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content area
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      // Request summary
                      Icon(
                        Icons.description_outlined,
                        size: 64.sp,
                        color: const Color(0xFF5170FF),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        '${widget.fromName} requesting for ${widget.requestedDocs.length} Document${widget.requestedDocs.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.note.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            widget.note,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF666666),
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      
                      // Documents list
                      SizedBox(height: 24.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Requested Documents:',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF333333),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            ...widget.requestedDocs.map((docName) {
                              final requestType = widget.requestTypes[docName] ?? 'view';
                              final requestTypeLabel = requestType == 'download' ? 'Download' : 'View Only';
                              final iconColor = _getDocumentIconColor(docName);
                              final isAvailable = _docStatus[docName] ?? false;
                              
                              return Container(
                                margin: EdgeInsets.only(bottom: 8.h),
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: const Color(0xFFE0E0E0),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Document icon
                                    Container(
                                      width: 40.w,
                                      height: 40.w,
                                      decoration: BoxDecoration(
                                        color: iconColor,
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Icon(
                                        _getDocumentIcon(docName),
                                        color: Colors.white,
                                        size: 20.sp,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    // Document name and type
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            docName,
                                            style: TextStyle(
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF333333),
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Row(
                                            children: [
                                              Icon(
                                                requestType == 'download' 
                                                    ? Icons.download 
                                                    : Icons.visibility,
                                                size: 14.sp,
                                                color: requestType == 'download' 
                                                    ? const Color(0xFF4CAF50) 
                                                    : const Color(0xFF2196F3),
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                requestTypeLabel,
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: requestType == 'download' 
                                                      ? const Color(0xFF4CAF50) 
                                                      : const Color(0xFF2196F3),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Availability indicator
                                    Icon(
                                      isAvailable 
                                          ? Icons.check_circle 
                                          : Icons.error_outline,
                                      color: isAvailable 
                                          ? Colors.green 
                                          : Colors.orange,
                                      size: 20.sp,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      
                      // Loading indicator while connecting
                      if (_isConnecting) ...[
                        SizedBox(height: 32.h),
                        const CircularProgressIndicator(),
                        SizedBox(height: 16.h),
                        Text(
                          'Establishing secure connection...',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      
                      // Action buttons
                      if (!_isConnecting) ...[
                        SizedBox(height: 32.h),
                      // Connect and Continue button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _allFilesFound ? _initiateConnection : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5170FF),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'Connect and Continue',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      // Reject button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(webrtcProvider).rejectIncoming();
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE57373),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                    ],  // closes Column children array
                  ),  // closes Column
                ),  // closes Padding
              ),  // closes SingleChildScrollView
            ),  // closes Expanded
          ],
        ),
        ),
      );
    }

    // ✨ STAGE 2: After connection - Show document list with APPROVE/REJECT buttons
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(top: 8.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          
          // User Profile Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Row(
              children: [
                // Profile Picture
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: const Color(0xFF666666),
                    size: 30.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                // User Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.fromName} | ${widget.fromUuid.length >= 8 ? widget.fromUuid.substring(0, 8) : widget.fromUuid}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Institute name',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Text(
              'REQUESTED BELOW DOCUMENTS',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Document requests list
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  ..._docStatus.entries.map((entry) {
                    final docName = entry.key;
                    final isAvailable = entry.value;
                    final approvalStatus = _docApprovalStatus[docName];
                    final requestType = widget.requestTypes[docName] ?? 'view';
                    final requestTypeLabel = requestType == 'download' ? 'Download' : 'View Only';
                    final iconColor = _getDocumentIconColor(docName);
                    
                    // Determine background color based on approval status
                    Color? cardBackgroundColor;
                    if (approvalStatus == 'approved') {
                      cardBackgroundColor = Colors.green.withOpacity(0.15);
                    } else if (approvalStatus == 'rejected') {
                      cardBackgroundColor = Colors.red.withOpacity(0.15);
                    }
                    
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: cardBackgroundColor ?? const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Document icon and name row
                          Row(
                            children: [
                              // Document icon
                              Container(
                                width: 50.w,
                                height: 50.w,
                                decoration: BoxDecoration(
                                  color: iconColor,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  _getDocumentIcon(docName),
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              // Document name
                              Expanded(
                                child: Text(
                                  docName,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isAvailable 
                                        ? const Color(0xFF333333) 
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          // Request details
                          Text(
                            'Request Type: $requestTypeLabel',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF333333),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            isAvailable 
                                ? 'Status: Available locally' 
                                : 'Status: Not found',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isAvailable 
                                  ? Colors.green[700] 
                                  : Colors.red[700],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Action buttons - Only show if available
                          if (isAvailable)
                            Row(
                              children: [
                                // Approve button
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _approveDocument(docName),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'APPROVE',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                // Reject button
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _rejectDocument(docName),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE57373),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'REJECT',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Center(
                                child: Text(
                                  'File not available',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 16.h),
                  // Send Approved Files button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final approvedCount = _docApprovalStatus.values
                              .where((status) => status == 'approved')
                              .length;
                          if (approvedCount > 0) {
                            _sendFilesAndClose();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please approve at least one file to send'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5170FF),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          'Send Approved Files',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Reject All & Close button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          ref.read(webrtcProvider).rejectIncoming();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Reject All & Close',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
        ),
      );
  }
}