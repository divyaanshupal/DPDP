import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DocumentLinkingScreen extends StatelessWidget {
  const DocumentLinkingScreen({super.key});

  // Document map - Each entry represents a document card
  // Properties:
  // - name: Document name displayed on the card
  // - isLinked: Whether the document is linked (affects styling)
  // - actionText: Text displayed on the action button
  // - actionType: Type of action ('linked', 'link', 'add_link')
  static final List<Map<String, dynamic>> documentMap = [
    // Each map entry creates one document card
    {'name': 'AADHAR CARD', 'isLinked': true, 'actionText': 'Linked', 'actionType': 'linked'},
    {'name': 'PAN CARD', 'isLinked': false, 'actionText': 'Link', 'actionType': 'link'},
    {'name': 'VOTER CARD', 'isLinked': false, 'actionText': 'Link', 'actionType': 'link'},
    {'name': 'BIRTH CERTIFICATE', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': 'DRIVING LICENSE', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': 'PHOTO', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': 'PASSPORT', 'isLinked': true, 'actionText': 'Linked', 'actionType': 'linked'},
    {'name': 'CASTE CERTIFICATE', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': '10TH CERTIFICATE', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': '12TH CERTIFICATE', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': 'UG CERTIFICATE', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': 'PG CERTIFICATE', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
    {'name': 'RATION CARD', 'isLinked': false, 'actionText': 'Link', 'actionType': 'add_link'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Privacy Protection Banner
            _buildPrivacyBanner(),
            
            // Main content area
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Link Your Documents Section
                    _buildLinkDocumentsSection(),
                    SizedBox(height: 20.h),
                    
                    // Document Cards Grid
                    _buildDocumentCardsGrid(),
                    
                    SizedBox(height: 20.h),
                    
                    // View All link
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          // Handle view all action
                        },
                        child: Text(
                          'View All >',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF5170FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 20.h),
                    
                    // Security Banner
                    _buildSecurityBanner(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF5170FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.security,
              color: Colors.green,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Privacy is Protected',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'All documents remain securely on your Device - not stored on any Central Server',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
            children: [
              GestureDetector(
                onTap: () {
                  // Handle link other document action
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

  Widget _buildDocumentCardsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: 0.75, // Reduced aspect ratio to give more height
      ),
      itemCount: documentMap.length,
      itemBuilder: (context, index) {
        final document = documentMap[index];
        return _buildDocumentCard(document);
      },
    );
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
    // You can implement different actions based on the action type
    switch (actionType) {
      case 'link':
        // Handle linking a new document
        print('Linking document: $documentName');
        break;
      case 'add_link':
        // Handle adding another link
        print('Adding link for document: $documentName');
        break;
      case 'linked':
        // Handle already linked document (maybe show details)
        print('Viewing linked document: $documentName');
        break;
      default:
        print('Unknown action for document: $documentName');
    }
  }

  Widget _buildSecurityBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFF5170FF),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.security,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SECURITY FIRST',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5170FF),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your documents never leave your device without explicit permission. Each share is temporary, encrypted, and recorded on blockchain for complete transparency.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}