import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kyrotics/features/sendingRequest/request_tab_notifier.dart';

// Ensure you have this import
import 'package:kyrotics/services/webrtcController.dart';
import 'package:kyrotics/Widgets/cool_toast.dart';

class RequestFileTab extends ConsumerWidget {
  final String selfUuid;
  RequestFileTab({super.key, required this.selfUuid});

  // ✅ Controllers are now final properties, created only once.
  final _targetCtrl = TextEditingController();
  final _noteCtrl = TextEditingController(text: "Please review my document request.");

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(requestTabProvider);
    // This allows the keyboard to be dismissed when tapping outside the text fields
    
    // ============================================================================
    // OLD DESIGN (COMMENTED OUT) - Simple search bar with AppBar
    // ============================================================================
    /*
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Document'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- Search Bar ---
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Enter Recipient UUID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: state.isLoading
                        ? null
                        : () {
                            if (_targetCtrl.text.trim().isNotEmpty) {
                              FocusScope.of(context).unfocus(); // Dismiss keyboard on search
                              ref.read(requestTabProvider.notifier).searchUser(_targetCtrl.text.trim());
                            }
                          },
                    child: const Text('Search'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // --- Dynamic Content Area ---
              Expanded(
                child: _buildContent(context, ref, state),
              ),
            ],
          ),
        ),
      ),
    );
    */
    // ============================================================================
    // END OF OLD DESIGN
    // ============================================================================
    
    // NEW DESIGN - Full-screen Request Portal Box
    return Scaffold(
      backgroundColor: const Color(0xFF5170FF),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          bottom: false, // Allow bottom to extend beyond safe area
          top: true,
          left: true,
          right: true,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
            child: Column(
              children: [
                // Header Section - Dark Blue Background with Back Button
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: 16.h,
                    bottom: 24.h,
                    left: 20.w,
                    right: 20.w,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF5170FF),
                  ),
                  child: Column(
                    children: [
                      // Back Button and Title Row
                      Row(
                        children: [
                          // Back Button
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(width: 12.w),
                          // Main Title
                          Expanded(
                            child: Text(
                              'Document Request Portal',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      // Subtitle
                      Text(
                        'Search for users and request their documents securely',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Main Content Section - Light Gray Background with Search and Results
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey[50],
                    child: Column(
                      children: [
                        // Search Bar Section
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.w),
                          color: Colors.grey[50],
                          child: Row(
                            children: [
                              // Input Field
                              Expanded(
                                child: Container(
                                  height: 40.h,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _targetCtrl,
                                    maxLength: 8,
                                    decoration: InputDecoration(
                                      hintText: 'Enter 8 Digit ID',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14.sp,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 10.h,
                                      ),
                                      counterText: '', // Hide the character counter
                                    ),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.black,
                                    ),
                                    onSubmitted: (_) {
                                      if (_targetCtrl.text.trim().isNotEmpty && !state.isLoading) {
                                        FocusScope.of(context).unfocus();
                                        ref.read(requestTabProvider.notifier).searchUser(_targetCtrl.text.trim());
                                      }
                                    },
                                  ),
                                ),
                              ),
                              
                              SizedBox(width: 12.w),
                              
                              // Search Button
                              Container(
                                height: 40.h,
                                width: 80.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5170FF),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: state.isLoading
                                        ? null
                                        : () {
                                            if (_targetCtrl.text.trim().isNotEmpty) {
                                              FocusScope.of(context).unfocus();
                                              ref.read(requestTabProvider.notifier).searchUser(_targetCtrl.text.trim());
                                            }
                                          },
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Center(
                                      child: state.isLoading
                                          ? SizedBox(
                                              width: 16.w,
                                              height: 16.h,
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              'Search',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Search Results Area (Scrollable)
                        Expanded(
                          child: _buildContent(context, ref, state),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Footer Section - Light Gray Background (extends to bottom to cover blue)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: 16.h,
                    bottom: 16.h + MediaQuery.of(context).viewPadding.bottom,
                    left: 20.w,
                    right: 20.w,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                  ),
                  child: Column(
                    children: [
                      // Subtle separator line
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.grey[300],
                        margin: EdgeInsets.only(bottom: 12.h),
                      ),
                      // Footer text
                      Text(
                        'Secure Document Sharing System | All rights reserved',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, RequestTabState state) {
    if (state.isLoading) {
      return Container(
        color: Colors.grey[50],
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (state.error != null) {
      return Container(
        color: Colors.grey[50],
        padding: EdgeInsets.all(20.w),
        child: Center(
          child: Text(
            state.error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (state.searchedUser != null) {
      final user = state.searchedUser!;
      
      // ============================================================================
      // OLD UI DESIGN (COMMENTED OUT) - Simple card with checkbox list
      // ============================================================================
      /*
      // ✨ UI POLISH: Content appears inside the box
      return Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // User profile section
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text(user.uuid, style: const TextStyle(color: Colors.grey)),
                ),
                const Divider(height: 24),
                
                // Document selection section
                const Text("Select documents to request:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                // Document list with fixed height
                Container(
                  height: 300, // Increased height to accommodate request type selection
                  child: ListView.builder(
                    itemCount: user.documents.length,
                    itemBuilder: (context, index) {
                      final doc = user.documents[index];
                      final isSelected = state.selectedDocs.contains(doc.name);
                      final requestType = state.documentRequestTypes[doc.name] ?? 'view';
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(doc.name),
                              subtitle: Text('Type: ${doc.fileType}'),
                              value: isSelected,
                              onChanged: (_) {
                                ref.read(requestTabProvider.notifier).toggleDocumentSelection(doc.name);
                              },
                            ),
                            // Request type selection (only show if selected)
                            if (isSelected) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Request Type:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ChoiceChip(
                                            label: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.visibility, size: 16),
                                                SizedBox(width: 4),
                                                Text('View Only'),
                                              ],
                                            ),
                                            selected: requestType == 'view',
                                            onSelected: (selected) {
                                              if (selected) {
                                                ref.read(requestTabProvider.notifier).updateDocumentRequestType(doc.name, 'view');
                                              }
                                            },
                                            selectedColor: Colors.blue.shade100,
                                            labelStyle: TextStyle(
                                              color: requestType == 'view' ? Colors.blue.shade700 : Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ChoiceChip(
                                            label: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.download, size: 16),
                                                SizedBox(width: 4),
                                                Text('Download'),
                                              ],
                                            ),
                                            selected: requestType == 'download',
                                            onSelected: (selected) {
                                              if (selected) {
                                                ref.read(requestTabProvider.notifier).updateDocumentRequestType(doc.name, 'download');
                                              }
                                            },
                                            selectedColor: Colors.green.shade100,
                                            labelStyle: TextStyle(
                                              color: requestType == 'download' ? Colors.green.shade700 : Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Expiration time picker (compact version)
                _buildCompactExpirationPicker(ref, state),
                
                const SizedBox(height: 16),
                
                // Note field
                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Add an optional message',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Send button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: state.selectedDocs.isNotEmpty ? () {
                      log("sending documents : ${state.selectedDocs} with ${state.expirationDays} days expiration");
                      final requestedDocs = state.selectedDocs.toList();
                      // Build requestTypes map from selected documents
                      final requestTypes = Map<String, String>.fromEntries(
                        requestedDocs.map((doc) => MapEntry(
                          doc,
                          state.documentRequestTypes[doc] ?? 'view', // Default to 'view' if not set
                        )),
                      );
                      log("request types: $requestTypes");
                      
                      ref.read(webrtcProvider).requestConsent(
                        targetUuid: user.uuid,
                        note: _noteCtrl.text.trim(),
                        requestedDocuments: requestedDocs,
                        requestTypes: requestTypes,
                        expirationDays: state.expirationDays,
                      );
                      
                      // ✨ NEW: Store expected documents for tracking
                      log("[snackbar] 📤 Sending request and setting expected documents for ${user.uuid}");
                      log("[snackbar] 📤 Requested docs: $requestedDocs");
                      ref.read(webrtcProvider).setExpectedDocuments(
                        targetUuid: user.uuid,
                        expectedDocuments: requestedDocs,
                      );
                      log("[snackbar] 📤 Expected documents set successfully");
                      
                      CoolToast.info(
                        context,
                        'Request for ${requestedDocs.length} file(s) sent! Files will expire in ${state.expirationDays} days.',
                      );
                    } : null,
                    child: const Text('Send Request'),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      );
      */
      // ============================================================================
      // END OF OLD UI DESIGN
      // ============================================================================
      
      // NEW UI DESIGN - Matching DocumentManagementScreen style
      return Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section (matching DocumentManagementScreen style)
              Container(
                margin: EdgeInsets.only(bottom: 24.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5170FF), // Blue background (matching theme)
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF333333),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'USER ID: ${user.uuid}',
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
              
              // Document List Header (matching DocumentManagementScreen style)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: const Color(0xFF2196F3),
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'LIST of Documents Available',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Document Cards (matching DocumentManagementScreen style)
              ...user.documents.map((doc) {
                final isSelected = state.selectedDocs.contains(doc.name);
                final requestType = state.documentRequestTypes[doc.name] ?? 'view';
                
                return Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Document icon and name row
                      Row(
                        children: [
                          // Document icon
                          Container(
                            width: 45.w,
                            height: 45.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getDocumentColor(doc.fileType),
                                  _getDocumentColor(doc.fileType).withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              _getDocumentIcon(doc.fileType),
                              color: Colors.white,
                              size: 22.sp,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          // Document name
                          Expanded(
                            child: Text(
                              doc.name,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ),
                          // Selection checkbox
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) {
                              ref.read(requestTabProvider.notifier).toggleDocumentSelection(doc.name);
                            },
                            activeColor: const Color(0xFF5170FF),
                          ),
                        ],
                      ),
                      
                      // Request type selection (only show if selected)
                      if (isSelected) ...[
                        SizedBox(height: 12.h),
                        // Request type chips
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ref.read(requestTabProvider.notifier).updateDocumentRequestType(doc.name, 'view');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: requestType == 'view' 
                                      ? const Color(0xFF2196F3) 
                                      : Colors.grey[300],
                                  foregroundColor: requestType == 'view' 
                                      ? Colors.white 
                                      : Colors.grey[700],
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.visibility, size: 16.sp),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'View Only',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ref.read(requestTabProvider.notifier).updateDocumentRequestType(doc.name, 'download');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: requestType == 'download' 
                                      ? const Color(0xFF4CAF50) 
                                      : Colors.grey[300],
                                  foregroundColor: requestType == 'download' 
                                      ? Colors.white 
                                      : Colors.grey[700],
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.download, size: 16.sp),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Download',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        // Hint text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14.sp,
                              color: const Color(0xFF2196F3),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Select request type for this document',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: const Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              
              SizedBox(height: 24.h),
              
              // Expiration time picker (compact version)
              _buildCompactExpirationPicker(ref, state),
              
              SizedBox(height: 24.h),
              
              // Note field
              TextField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  labelText: 'Add an optional message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 24.h),
              
              // Send button (matching style)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.selectedDocs.isNotEmpty 
                        ? const Color(0xFF5170FF) 
                        : Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onPressed: state.selectedDocs.isNotEmpty ? () {
                    log("sending documents : ${state.selectedDocs} with ${state.expirationDays} days expiration");
                    final requestedDocs = state.selectedDocs.toList();
                    // Build requestTypes map from selected documents
                    final requestTypes = Map<String, String>.fromEntries(
                      requestedDocs.map((doc) => MapEntry(
                        doc,
                        state.documentRequestTypes[doc] ?? 'view', // Default to 'view' if not set
                      )),
                    );
                    log("request types: $requestTypes");
                    
                    ref.read(webrtcProvider).requestConsent(
                      targetUuid: user.uuid,
                      note: _noteCtrl.text.trim(),
                      requestedDocuments: requestedDocs,
                      requestTypes: requestTypes,
                      expirationDays: state.expirationDays,
                    );
                    
                    // ✨ NEW: Store expected documents for tracking
                    log("[snackbar] 📤 Sending request and setting expected documents for ${user.uuid}");
                    log("[snackbar] 📤 Requested docs: $requestedDocs");
                    ref.read(webrtcProvider).setExpectedDocuments(
                      targetUuid: user.uuid,
                      expectedDocuments: requestedDocs,
                    );
                    log("[snackbar] 📤 Expected documents set successfully");
                    
                    CoolToast.info(
                      context,
                      'Request for ${requestedDocs.length} file(s) sent! Files will expire in ${state.expirationDays} days.',
                    );
                  } : null,
                  child: Text(
                    'Send Request',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 24.h),
            ],
          ),
        ),
      );
    }
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Text(
          'Search for a user to begin.',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  // Helper method to get document icon based on file type
  IconData _getDocumentIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Helper method to get document color based on file type
  Color _getDocumentColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFE91E63); // Pinkish-red
      case 'jpg':
      case 'jpeg':
      case 'png':
        return const Color(0xFF2196F3); // Light blue
      case 'doc':
      case 'docx':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFFFF9800); // Orange
    }
  }

  // Compact expiration time picker to prevent overflow
  Widget _buildCompactExpirationPicker(WidgetRef ref, RequestTabState state) {
    final presetOptions = [
      {'days': 1, 'label': '1 Day'},
      {'days': 3, 'label': '3 Days'},
      {'days': 7, 'label': '7 Days'},
      {'days': 14, 'label': '14 Days'},
      {'days': 30, 'label': '30 Days'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'File Access Duration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'How long should the receiver have access to these files?',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        
        // Horizontal scrollable preset options
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presetOptions.map((option) {
              final days = option['days'] as int;
              final isSelected = state.expirationDays == days;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(option['label'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(requestTabProvider.notifier).updateExpirationDays(days);
                    }
                  },
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue.shade700,
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Expiration preview
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.blue.shade700,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Files will expire in ${state.expirationDays} days',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}