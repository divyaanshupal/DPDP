import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kyrotics/features/auth/application/user_provider.dart';
import 'package:kyrotics/features/auth/application/user_state.dart';
import 'package:kyrotics/features/encrption/rsa_key_service.dart';
import 'package:kyrotics/services/webrtcController.dart';
import 'package:kyrotics/services/background_cleanup_service.dart';
import 'package:kyrotics/features/documents/presentation/DocumentAdding.dart';
import 'package:kyrotics/features/messaging/presentaion/approved.dart';
import 'package:kyrotics/features/messaging/presentaion/incoming_request_dialogue.dart';
import 'package:kyrotics/features/sendingRequest/presentation.dart';
import 'package:kyrotics/features/transactions/presentation/my_shared_files.dart';
import 'package:kyrotics/features/transactions/presentation/rejected_requests.dart';
import 'package:kyrotics/Widgets/cool_toast.dart';

class DocumentDashboard extends ConsumerStatefulWidget {
  final String uuid;
  const DocumentDashboard({super.key, required this.uuid});

  @override
  ConsumerState<DocumentDashboard> createState() => _DocumentDashboardState();
}

class _DocumentDashboardState extends ConsumerState<DocumentDashboard> {
  bool _isDialogShowing = false; // Flag to prevent duplicate dialogs

  @override
  void initState() {
    super.initState();
    // Initialize WebRTC connection and background cleanup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(webrtcProvider).connect(widget.uuid);
      ref.read(backgroundCleanupServiceProvider).setCurrentUser(widget.uuid);
      
      // Only try to fetch user data if we don't have any user data at all
      final userState = ref.read(userProvider);
      if (userState.user == null && !userState.isLoading && !userState.isAuthenticated) {
        // Only fetch if we're not already loading, have no user data, and not authenticated
        ref.read(userProvider.notifier).fetchUserByUuid(widget.uuid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final user = userState.user;
    
    // Debug: Log the current state
    print('🔍 [DocumentDashboard] State: isLoading=${userState.isLoading}, isAuthenticated=${userState.isAuthenticated}, user=${user?.name}, error=${userState.error}');

    // Listen for incoming WebRTC requests and show consent dialog
    ref.listen<WebRTCController>(webrtcProvider, (previous, next) {
      final hasIncomingCall = next.incomingFromUuid != null;
      
      // Debug logging
      print("🔍 [DocumentDashboard] Incoming call check: $hasIncomingCall");
      print("🔍 [DocumentDashboard] incomingFromUuid: ${next.incomingFromUuid}");
      print("🔍 [DocumentDashboard] incomingRequestedDocs: ${next.incomingRequestedDocs}");
      print("🔍 [DocumentDashboard] _isDialogShowing: $_isDialogShowing");

      // Only show the dialog if there IS an incoming call AND a dialog is NOT already showing.
      if (hasIncomingCall && !_isDialogShowing) {
        print("🔍 [DocumentDashboard] Showing incoming call dialog");
        setState(() {
          _isDialogShowing = true; // Set the flag right before showing
        });

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => IncomingRequestDialog(
            fromUuid: next.incomingFromUuid!,
            fromName: next.incomingFromName ?? next.incomingFromUuid!, // Pass sender's name
            note: next.incomingNote ?? '',
            // Now this is safe, because our 'if' condition guarantees it's not null.
            requestedDocs: next.incomingRequestedDocs!,
            requestTypes: next.incomingRequestTypes ?? {}, // ✨ NEW: Pass request types, default to empty map
            expirationDays: next.incomingExpirationDays ?? 7, // Pass expiration days
          ),
        ).whenComplete(() {
          // Reset the flag when the dialog is dismissed.
          setState(() {
            _isDialogShowing = false;
          });
        });
      }
    });
    
    // ✨ NEW: Separate listener for request status and document receipts (doesn't interfere with incoming calls)
    ref.listen<WebRTCController>(webrtcProvider, (previous, next) {
      print("[snackbar] 🔔 Listener triggered - previous: ${previous != null ? 'exists' : 'null'}, next: exists");
      
      if (previous == null) {
        print("[snackbar] ⏭️ Skipping on first build (previous is null)");
        return; // Skip on first build
      }
      
      try {
        print("[snackbar] 🔍 Starting status and document tracking check");
        
        // ✨ NEW: Check for pending status changes first (more reliable than comparing states)
        final pendingStatusChanges = next.getPendingStatusChanges();
        print("[snackbar] 🎯 Found ${pendingStatusChanges.length} pending status changes");
        
        for (final pendingStatusChange in pendingStatusChanges) {
          final targetUuid = pendingStatusChange.key;
          final status = pendingStatusChange.value;
          // ✨ NEW: Get name for this UUID
          final userName = next.getNameForUuid(targetUuid) ?? targetUuid;
          print("[snackbar] 🎯 Processing pending status change: $targetUuid -> $status (name: $userName)");
          
          if (status == 'accepted') {
            print("[snackbar] ✅✅ Showing ACCEPTED toast for $userName");
            CoolToast.success(
              context,
              'Request accepted by $userName',
            );
            print("[snackbar] ✅✅ ACCEPTED toast shown for $userName");
          } else if (status == 'rejected') {
            print("[snackbar] ❌❌ Showing REJECTED toast for $userName");
            CoolToast.error(
              context,
              'Request rejected by $userName',
            );
            print("[snackbar] ❌❌ REJECTED toast shown for $userName");
          }
        }
        
        // ✨ NEW: Check for pending document info first (more reliable than comparing states)
        final pendingDocumentInfos = next.getPendingDocumentInfos();
        print("[snackbar] 🎯 Found ${pendingDocumentInfos.length} pending document infos");
        
        for (final pendingDocumentInfo in pendingDocumentInfos) {
          final targetUuid = pendingDocumentInfo.key;
          final docInfo = pendingDocumentInfo.value;
          print("[snackbar] 🎯 Processing pending document info: $targetUuid -> ${docInfo.docName} (${docInfo.count}/${docInfo.total})");
          print("[snackbar] 📄✅ Showing document receipt toast");
          print("[snackbar] 📄✅ Message: ${docInfo.docName} received (${docInfo.count}/${docInfo.total}) ✓");
          
          CoolToast.info(
            context,
            '${docInfo.docName} received (${docInfo.count}/${docInfo.total}) ✓',
          );
          print("[snackbar] 📄✅ Document receipt toast shown for ${docInfo.docName}");
          
          // Clear the latest received document info after showing snackbar
          next.clearLatestReceivedDocument(targetUuid);
          print("[snackbar] 📄✅ Cleared latest received document for $targetUuid");
        }
      } catch (e, stackTrace) {
        // Log error but don't block functionality
        print("[snackbar] ❌ ERROR in status/document tracking: $e");
        print("[snackbar] ❌ Stack trace: $stackTrace");
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: 
        // COMMENTED OUT - Now handled by splash screen
        // userState.isLoading && user == null
        //     ? const Center(child: CircularProgressIndicator())
        //     : 
        userState.error != null && user == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Error: ${userState.error}'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(userProvider.notifier).fetchUserByUuid(widget.uuid);
                      },
                      child: Text('Retry'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section with dynamic user data and logout button
                    _buildHeaderSection(user),
                    SizedBox(height: 24.h),

                    // Blue Banner
                    _buildBlueBanner(),
                    SizedBox(height: 24.h),

                    // Share with Evidence Section
                    _buildShareWithEvidenceSection(),
                    SizedBox(height: 24.h),

                    // Documents Section
                    _buildDocumentsSection(),
                    SizedBox(height: 24.h),

                    // Security First Banner
                    _buildSecurityBanner(),
                    SizedBox(height: 24.h),

                    // Recent Activities Section
                    _buildRecentActivitiesSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        final currentUser = ref.read(userProvider).user;
        final userUuid = currentUser?.uuid;
        // Clear user data from provider
        ref.read(userProvider.notifier).clearUser();

        if (userUuid != null) {
      try {
        final rsaKeyService = RSAKeyService();
        await rsaKeyService.deleteKeyPair(userUuid);
        print('🔐 [Logout] RSA keys deleted for user: $userUuid');
      } catch (e) {
        print('❌ [Logout] Error deleting RSA keys: $e');
      }
    }
        
        // Stop background cleanup service
        ref.read(backgroundCleanupServiceProvider).stopCleanupService();
        
        // Sign out from Firebase
        await FirebaseAuth.instance.signOut();
        
        // Navigate to auth screen
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error during logout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildHeaderSection(user) {
    return Row(
      children: [
        // Profile Picture
        Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.yellow[200],
            border: Border.all(color: Colors.grey[300]!, width: 2.w),
          ),
          child: Icon(Icons.person, color: Colors.orange, size: 30.sp),
        ),
        SizedBox(width: 12.w),
        // Name and ID
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello ${user?.name ?? 'User'}!',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5170FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'ID: ${user?.uuid ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF5170FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Logout Button
        IconButton(
          onPressed: _handleLogout,
          icon: Icon(
            Icons.logout,
            color: Colors.grey[600],
            size: 24.sp,
          ),
          tooltip: 'Logout',
        ),
      ],
    );
  }

  Widget _buildBlueBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF5170FF),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Documents, Your Control',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16.h),
          _buildFeatureItem(Icons.folder, 'Your Data- Never on the Cloud'),
          SizedBox(height: 8.h),
          _buildFeatureItem(
            Icons.account_tree,
            'Blockchain-Verified Sharing Records',
          ),
          SizedBox(height: 8.h),
          _buildFeatureItem(Icons.lock, 'End-to-End Encryption'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareWithEvidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SHARE WITH EVIDENCE',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12.h),
        // Single card containing all three badges
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.purple[300]!, width: 1.w),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                spreadRadius: 0,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEvidenceBadge(Icons.people, 'P2P', 'Sharing'),
              _buildEvidenceBadge(Icons.verified_user, 'DPDP', 'Compliance'),
              _buildEvidenceBadge(Icons.link, 'BLOCKCHAIN', 'Proof'),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DocumentsScreen(),
                    ),
                  );
                },
                child: _buildActionButton(Icons.add, 'Link Document'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DocumentsScreen(),
                    ),
                  );
                },
                child: _buildActionButton(
                  Icons.description,
                  'My Linked Documents',
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestFileTab(selfUuid: widget.uuid),
                    ),
                  );
                },
                child: _buildActionButton(Icons.input, 'Request for Document'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEvidenceBadge(IconData icon, String mainText, String subText) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24.sp, color: Colors.grey[600]),
        SizedBox(height: 8.h),
        Text(
          mainText,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          subText,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }


  Widget _buildActionButton(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF5170FF), size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documents',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16.h),
        // First row with 2 buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MySharedFilesScreen(),
                    ),
                  );
                },
                child: _buildDocumentStatusButton(Icons.share, 'Shared'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApprovedScreen(),
                    ),
                  );
                },
                child: _buildDocumentStatusButton(Icons.download, 'Received'),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        // Second row with 2 buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // TODO: Navigate to pending requests screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pending Requests - Coming Soon!')),
                  );
                },
                child: _buildDocumentStatusButton(
                  Icons.access_time,
                  'Pending Requests',
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RejectedRequestsScreen(),
                    ),
                  );
                },
                child: _buildDocumentStatusButton(
                  Icons.cancel,
                  'Rejected Requests',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentStatusButton(IconData icon, String text) {
    return Container(
      height: 100.h, // Fixed height for consistent card sizes
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF5170FF), size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Allow text to wrap to 2 lines
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF5170FF).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFF5170FF),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.security,
              color: Colors.white,
              size: 24.sp,
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
                    color: Colors.black,
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

  Widget _buildRecentActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'See All >',
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF5170FF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildActivityCard(
                'AADHAR',
                'Axis Bank',
                '3 Days ago',
                'Approved',
                true,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildActivityCard(
                'PAN CARD',
                'Axis Bank',
                '3 Days ago',
                'Rejected',
                false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    String documentType,
    String organization,
    String time,
    String status,
    bool isApproved,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: const Color(0xFF5170FF), size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  documentType,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.business, color: Colors.grey[600], size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                organization,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.grey[600], size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                time,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isApproved ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12.sp,
                color: isApproved ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
