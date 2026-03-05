import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kyrotics/features/documents/application/documents_notifier.dart';
import 'package:kyrotics/features/documents/presentation/document_state.dart';
import 'package:kyrotics/features/documents/presentation/document-viewer.dart';
import 'package:kyrotics/services/webrtcController.dart';
 
/// This screen is now a ConsumerStatefulWidget.
/// "Consumer" gives it access to Riverpod providers.
/// "Stateful" allows us to use `initState` to trigger the initial data fetch.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});
 
  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}
 
class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  // Predefined document list - Each entry represents a document card
  // Properties:
  // - name: Document name displayed on the card
  // - isLinked: Whether the document is linked (affects styling)
  // - actionText: Text displayed on the action button
  // - actionType: Type of action ('linked', 'link', 'add_link')
  static final List<Map<String, dynamic>> predefinedDocuments = [
    {'name': 'AADHAR CARD', 'isLinked': false, 'actionText': 'Link', 'actionType': 'link'},
    {'name': 'PAN CARD', 'isLinked': false, 'actionText': 'Link', 'actionType': 'link'},
    {'name': 'VOTER CARD', 'isLinked': false, 'actionText': 'Link', 'actionType': 'link'},
    {'name': 'BIRTH CERTIFICATE', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': 'DRIVING LICENSE', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': 'PHOTO', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': 'PASSPORT', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': 'CASTE CERTIFICATE', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': '10TH CERTIFICATE', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': '12TH CERTIFICATE', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': 'UG CERTIFICATE', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': 'PG CERTIFICATE', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': 'RATION CARD', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
  ];
 
  @override
  void initState() {
    super.initState();
    // We fetch data here, once, when the widget is first created.
    // We use addPostFrameCallback to ensure the widget is fully built
    // before we try to read from a provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // We read the UUID from the existing webrtcProvider
      final uuid = ref.read(webrtcProvider).selfUuid;
      if (uuid != null) {
        // We call the method on our new notifier to start the fetch/sync process.
        // We use ref.read() here because we are not watching for changes, just triggering an action.
        ref.read(documentsProvider.notifier).fetchAndSyncDocuments();
      }
    });
  }
 
  @override
  Widget build(BuildContext context) {
    // We use ref.watch() here. This tells Flutter to rebuild this widget
    // whenever the DocumentsState changes (e.g., from loading to loaded).
    final state = ref.watch(documentsProvider);
 
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Collapsible security card
           _buildCollapsibleSecurityCard(),
           
            // Document stats
          //  _buildDocumentStats(state),
           
            // Search bar
           // _buildSearchBar(),
           
            // Quick actions
           // _buildQuickActions(),
           
            // Main content area
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Link Your Documents Section
                    _buildLinkDocumentsSection(),
                    SizedBox(height: 20.h),
                   
                    // Document Cards Grid
                    _buildDocumentCardsGrid(state),
                   
                    SizedBox(height: 100.h), // Space for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildSecurityFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
 
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'My Documents',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
//search button
        IconButton(
          icon: Icon(Icons.search, color: Colors.grey[600]),
          onPressed: () => (),
        ),
 
//security button
 
        IconButton(
          icon: Icon(Icons.info_outline, color: Colors.grey[600]),
          onPressed: () => _showSecurityInfo(),
        ),
      ],
    );
  }
 
  Widget _buildCollapsibleSecurityCard() {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF5170FF),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        leading: Icon(Icons.security, color: Colors.white, size: 24.sp),
        title: Text(
          'Your Privacy is Protected',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Text(
            'All documents remain securely on your Device - not stored on any Central/Online/Cloud Server. Each share is temporary, encrypted, and recorded on blockchain for complete transparency.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildDocumentStats(DocumentsState state) {
    final linkedCount = state.documents.where((doc) => doc.status == SyncedStatus.available).length;
    final totalPredefined = predefinedDocuments.length;
   
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document Progress',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$linkedCount of $totalPredefined documents linked',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          CircularProgressIndicator(
            value: linkedCount / totalPredefined,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF5170FF)),
          ),
        ],
      ),
    );
  }
 
  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search documents...',
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
        onChanged: (value) {
          // TODO: Implement search functionality
        },
      ),
    );
  }
 
  Widget _buildQuickActions() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.add_photo_alternate,
              label: 'Add Photo',
              onTap: () => _addDocument('PHOTO'),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildActionButton(
              icon: Icons.description,
              label: 'Add PDF',
              onTap: () => _addDocument('PDF'),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildActionButton(
              icon: Icons.link,
              label: 'Link Other',
              onTap: () => _addCustomDocument(),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF5170FF), size: 20.sp),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _buildSecurityFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _showSecurityDialog(),
      backgroundColor: const Color(0xFF5170FF),
      icon: Icon(Icons.security, color: Colors.white),
      label: Text(
        'Security Info',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }
 
  void _showSecurityInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: const Color(0xFF5170FF)),
            SizedBox(width: 8.w),
            Text('Security Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Privacy is Protected',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              'All documents remain securely on your Device - not stored on any Central/Online/Cloud Server.',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              'Security Features:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            SizedBox(height: 4.h),
            Text('• End-to-end encryption', style: TextStyle(fontSize: 12.sp)),
            Text('• Blockchain recording', style: TextStyle(fontSize: 12.sp)),
            Text('• Temporary sharing only', style: TextStyle(fontSize: 12.sp)),
            Text('• No central storage', style: TextStyle(fontSize: 12.sp)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }
 
  void _showSecurityDialog() {
    _showSecurityInfo();
  }
 
  void _addDocument(String type) {
    if (type == 'PHOTO') {
      _addPredefinedDocument('PHOTO');
    } else if (type == 'PDF') {
      _addPredefinedDocument('AADHAR CARD'); // Default to AADHAR for PDF
    }
  }
 
  void _addCustomDocument() async {
    try {
      await ref.read(documentsProvider.notifier).addNewDocument(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add document: $e')),
        );
      }
    }
  }
 
 
  Widget _buildLinkDocumentsSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading text
          Text(
            'Link Your Documents',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12.h),
          // Button positioned below the heading
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () async {
                  try {
                    await ref.read(documentsProvider.notifier).addNewDocument(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add document: $e')),
                      );
                    }
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0EDFF),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: const Color(0xFFB3C7FF), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link,
                        size: 16.sp,
                        color: Colors.black,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'LINK OTHER DOCUMENT',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
 
  Widget _buildDocumentCardsGrid(DocumentsState state) {
    // Update predefined documents with actual linked status from state
    final updatedDocuments = _updateDocumentStatus(predefinedDocuments, state);
   
    // Add custom documents from state that are not in predefined list
    final customDocuments = _getCustomDocuments(state);
    final allDocuments = [...updatedDocuments, ...customDocuments];
   
    // Sort documents: linked documents first, then unlinked documents
    final sortedDocuments = _sortDocumentsByLinkedStatus(allDocuments);
   
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: 0.75, // Reduced aspect ratio to give more height
      ),
      itemCount: sortedDocuments.length,
      itemBuilder: (context, index) {
        final document = sortedDocuments[index];
        return _buildDocumentCard(document);
      },
    );
  }
 
  List<Map<String, dynamic>> _updateDocumentStatus(List<Map<String, dynamic>> predefinedDocs, DocumentsState state) {
    return predefinedDocs.map((doc) {
      final docName = doc['name'] as String;
      final isLinked = state.documents.any((syncedDoc) =>
        syncedDoc.name == docName && syncedDoc.status == SyncedStatus.available);
     
      return {
        ...doc,
        'isLinked': isLinked,
        'actionText': isLinked ? 'Linked' : 'Link',
        'actionType': isLinked ? 'linked' : doc['actionType'],
      };
    }).toList();
  }
 
  /// Get custom documents that are not in the predefined list
  List<Map<String, dynamic>> _getCustomDocuments(DocumentsState state) {
    final predefinedNames = predefinedDocuments.map((doc) => doc['name'] as String).toSet();
   
    return state.documents
        .where((syncedDoc) =>
          !predefinedNames.contains(syncedDoc.name) &&
          syncedDoc.status == SyncedStatus.available &&
          // Extra safety check: ensure it's not a shared file
          (syncedDoc.localDocument?.isSharedFile != true))
        .map((syncedDoc) => {
          'name': syncedDoc.name,
          'isLinked': true,
          'actionText': 'Linked',
          'actionType': 'linked',
        })
        .toList();
  }
 
  /// Sort documents with linked documents first, then unlinked documents
  List<Map<String, dynamic>> _sortDocumentsByLinkedStatus(List<Map<String, dynamic>> documents) {
    // Create a copy to avoid modifying the original list
    final sortedDocs = List<Map<String, dynamic>>.from(documents);
   
    // Sort: linked documents first (true), then unlinked documents (false)
    sortedDocs.sort((a, b) {
      final aLinked = a['isLinked'] as bool;
      final bLinked = b['isLinked'] as bool;
     
      // If both have same linked status, maintain original order
      if (aLinked == bLinked) return 0;
     
      // Linked documents (true) come before unlinked documents (false)
      return aLinked ? -1 : 1;
    });
   
    return sortedDocs;
  }
 
  Widget _buildDocumentCard(Map<String, dynamic> document) {
    // Extract properties from the document map
    final String documentName = document['name'] ?? 'Unknown Document';
    final bool isLinked = document['isLinked'] ?? false;
    final String actionText = document['actionText'] ?? 'Action';
    final String actionType = document['actionType'] ?? 'link';
   
    return GestureDetector(
      onTap: () {
        // Handle card tap based on action type
        _handleDocumentAction(documentName, actionType, isLinked);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isLinked ? Colors.green[300]! : Colors.grey[300]!,
            width: 1.w
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Document Icon
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: isLinked ? Colors.green[100] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  isLinked ? Icons.check_circle : Icons.description,
                  size: 16.sp,
                  color: isLinked ? Colors.green[700] : const Color(0xFF5170FF),
                ),
              ),
             
              // Document Name
              Expanded(
                child: Center(
                  child: Text(
                    documentName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
             
              // Action Button/Status
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 4.h),
                decoration: BoxDecoration(
                  color: isLinked ? Colors.green[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(6.r),
                  border: isLinked ? null : Border.all(color: Colors.transparent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionIcon(actionType, isLinked),
                    if (_shouldShowIcon(actionType)) SizedBox(width: 3.w),
                    Flexible(
                      child: Text(
                        actionText,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isLinked ? Colors.green[700] : const Color(0xFF5170FF),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  // Helper method to build action icon based on action type
  Widget _buildActionIcon(String actionType, bool isLinked) {
    if (actionType == 'link') {
      return Icon(
        Icons.link,
        size: 10.sp,
        color: const Color(0xFF5170FF),
      );
    } else if (actionType == 'add_link') {
      return Icon(
        Icons.add,
        size: 10.sp,
        color: const Color(0xFF5170FF),
      );
    } else if (actionType == 'linked') {
      return Icon(
        Icons.check,
        size: 10.sp,
        color: Colors.green[700],
      );
    }
    return const SizedBox.shrink();
  }
 
  // Helper method to determine if icon should be shown
  bool _shouldShowIcon(String actionType) {
    return actionType == 'link' || actionType == 'add_link' || actionType == 'linked';
  }
 
  // Handle document action based on type and status
  void _handleDocumentAction(String documentName, String actionType, bool isLinked) {
    if (isLinked) {
      // Document is already linked - show document viewer or allow re-upload
      _showDocumentOptions(documentName);
      return;
    }
 
    // Document is not linked - add it with predefined name
    _addPredefinedDocument(documentName);
  }
 
  /// Show options for a linked document (view or replace)
  void _showDocumentOptions(String documentName) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              documentName,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _viewDocument(documentName);
                    },
                    icon: Icon(Icons.visibility),
                    label: Text('View'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _replaceDocument(documentName);
                    },
                    icon: Icon(Icons.swap_horiz),
                    label: Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }
 
  /// View a document
  void _viewDocument(String documentName) async {
    try {
      final state = ref.read(documentsProvider);
      final syncedDoc = state.documents.firstWhere(
        (doc) => doc.name == documentName && doc.status == SyncedStatus.available,
      );
     
      if (syncedDoc.localDocument != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentViewerScreen(document: syncedDoc.localDocument!),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open document: $e')),
      );
    }
  }
 
  /// Replace a document
  void _replaceDocument(String documentName) async {
    try {
      await ref.read(documentsProvider.notifier).resyncExpiredDocument(documentName, 'pdf');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to replace document: $e')),
        );
      }
    }
  }
 
  Future<void> _addPredefinedDocument(String documentName) async {
    try {
      await ref.read(documentsProvider.notifier).addNewDocument(context, predefinedDocumentName: documentName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add $documentName: $e')),
        );
      }
    }
  }
 
}