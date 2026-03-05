//OLD HOME SCREEEN WE DONT USE IT NOW , HAVE MIGRATED TO NEW HOME SCREEN  @newHomeScreen.dart

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:kyrotics/features/documents/presentation/DocumentAdding.dart';
// import 'package:kyrotics/features/messaging/presentaion/approved.dart';
// import 'package:kyrotics/features/messaging/presentaion/incoming_request_dialogue.dart';
// //import 'package:kyrotics/features/messaging/presentaion/receiverSendSheet.dart';
// import 'package:kyrotics/features/sendingRequest/presentation.dart';
// import 'package:kyrotics/services/webrtcController.dart';
// import 'package:kyrotics/services/background_cleanup_service.dart';

// class HomeScreen extends ConsumerStatefulWidget {
//   final String uuid;
//   const HomeScreen({super.key, required this.uuid});
//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }

// // In home_screen.dart

// class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
//   late final TabController _tabController;
//   bool _isDialogShowing = false; // ✅ ADD A FLAG TO PREVENT DUPLICATE DIALOGS

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(webrtcProvider).connect(widget.uuid);
//       // Set the UUID for background cleanup service
//       ref.read(backgroundCleanupServiceProvider).setCurrentUser(widget.uuid);
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ✅ THIS LISTENER IS NOW MORE ROBUST
//     ref.listen<WebRTCController>(webrtcProvider, (previous, next) {
//       final hasIncomingCall = next.incomingFromUuid != null;
      
//       // Debug logging
//       print("🔍 [Home Screen] Incoming call check: $hasIncomingCall");
//       print("🔍 [Home Screen] incomingFromUuid: ${next.incomingFromUuid}");
//       print("🔍 [Home Screen] incomingRequestedDocs: ${next.incomingRequestedDocs}");
//       print("🔍 [Home Screen] _isDialogShowing: $_isDialogShowing");

//       // Only show the dialog if there IS an incoming call AND a dialog is NOT already showing.
//       if (hasIncomingCall && !_isDialogShowing) {
//         print("🔍 [Home Screen] Showing incoming call dialog");
//         setState(() {
//           _isDialogShowing = true; // Set the flag right before showing
//         });

//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (ctx) => IncomingRequestDialog(
//             fromUuid: next.incomingFromUuid!,
//             fromName: next.incomingFromName ?? next.incomingFromUuid!, // ✨ NEW: Pass sender's name
//             note: next.incomingNote ?? '',
//             // Now this is safe, because our 'if' condition guarantees it's not null.
//             requestedDocs: next.incomingRequestedDocs!,
//             expirationDays: next.incomingExpirationDays ?? 7, // ✨ NEW: Pass expiration days
//           ),
//         ).whenComplete(() {
//           // Reset the flag when the dialog is dismissed.
//           setState(() {
//             _isDialogShowing = false;
//           });
//         });
//       }
    
    
//     });

//     // ... rest of your Scaffold and UI is unchanged ...
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F6FA),
//       appBar: AppBar(
//         backgroundColor: Colors.deepPurple,
//         title: const Text('Secure File Sharing', style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout, color: Colors.white),
//             onPressed: _handleLogout,
//             tooltip: 'Logout',
//           ),
//         ],
//         bottom: TabBar(
//             controller: _tabController,
//             labelColor: Colors.white,
//             indicatorColor: Colors.amberAccent,
//             tabs: const [
//               Tab(icon: Icon(Icons.description), text: 'Documents'),
//               Tab(icon: Icon(Icons.download), text: 'Received'),
//               Tab(icon: Icon(Icons.cancel_outlined), text: 'Rejected'),
//               Tab(icon: Icon(Icons.send), text: 'Request File'),
//             ]),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           const DocumentsScreen(),
//           const ApprovedScreen(),
//           _placeholderScreen('Rejected Requests'),
//           RequestFileTab(selfUuid: widget.uuid),
//         ],
//       ),
//     );
//   }

//   // void _openDocumentSelectionDialog(BuildContext context) {
//   //   showDialog(
//   //     context: context,
//   //     barrierDismissible: false,
//   //     builder: (_) => DocumentSelectionDialog(
//   //       onSend: (selectedDocs) {
//   //         ref.read(webrtcProvider).sendDocuments(selectedDocs);
//   //         ScaffoldMessenger.of(context).showSnackBar(
//   //           SnackBar(content: Text('Sending ${selectedDocs.length} document(s)...')),
//   //         );
//   //       },
//   //     ),
//   //   );
//   // }
  
//   Widget _placeholderScreen(String title) {
//     return Center(child: Text("$title (Placeholder)", style: const TextStyle(fontSize: 18, color: Colors.grey)));
//   }

//   Future<void> _handleLogout() async {
//     // Show confirmation dialog
//     final shouldLogout = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         //comment 1 
//         //comment 2
//         title: const Text('Logout'),
//         content: const Text('Are you sure you want to logout?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Logout'),
//           ),
//         ],
//       ),
//     );

//     if (shouldLogout == true) {
//       try {
//         // Stop background cleanup service
//         ref.read(backgroundCleanupServiceProvider).stopCleanupService();
        
//         // Sign out from Firebase
//         await FirebaseAuth.instance.signOut();
        
//         // Navigate to auth screen
//         if (mounted) {
//           Navigator.pushNamedAndRemoveUntil(
//             context,
//             '/',
//             (route) => false,
//           );
//         }
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Error during logout: $e'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     }
//   }
// }