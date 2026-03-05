import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kyrotics/features/auth/view/UserSignUp.dart';
import 'package:kyrotics/features/encrption/rsa_key_service.dart';

// import 'package:kyrotics/Screens/slidingUpPannel.dart';

import 'package:kyrotics/features/home/presentation/newHomeScreen.dart';
// import 'package:kyrotics/features/transactions/presentation/rejected_requests.dart';
import 'package:kyrotics/firebase_options.dart';
import 'package:kyrotics/features/auth/view/UserDetails.dart';
import 'package:kyrotics/features/documents/model/local_document_model.dart';
import 'package:kyrotics/features/messaging/model/messageBOX.dart';
import 'package:kyrotics/features/messaging/model/file_sharing_session.dart';
import 'package:kyrotics/services/background_cleanup_service.dart';
import 'package:kyrotics/features/auth/application/user_provider.dart';
import 'package:kyrotics/features/auth/application/user_state.dart';
import 'package:kyrotics/widgets/splash_screen_manager.dart';

// --- TEMP models/adapters placeholders ---
// class DocumentModel extends HiveObject {}
// class DocumentModelAdapter extends TypeAdapter<DocumentModel> {
//   @override
//   final typeId = 1;
//   @override
//   DocumentModel read(BinaryReader reader) => DocumentModel();
//   @override
//   void write(BinaryWriter writer, DocumentModel obj) {}
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  await FirebaseAppCheck.instance.activate(
  //androidProvider: AndroidProvider.playIntegrity,
  androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.deviceCheck,
  // webProvider if you also target web: ReCaptchaV3Provider('your-site-key'),
);

  await Hive.initFlutter();

  // Register all adapters
  //Hive.registerAdapter(DocumentModelAdapter());
  Hive.registerAdapter(MessageAdapter());
  Hive.registerAdapter(LocalDocumentAdapter());
  Hive.registerAdapter(
    FileSharingSessionAdapter(),
  ); // ✨ NEW: Register file sharing session adapter
  Hive.registerAdapter(
    SharingStatusAdapter(),
  ); // ✨ NEW: Register sharing status adapter

  // Open all necessary boxes
  //await Hive.openBox<DocumentModel>('documentPaths');

  //await Hive.deleteBoxFromDisk('bits');
  //await Hive.deleteBoxFromDisk('documents');

  await Hive.openBox<Message>('bits');
  // Note: documents boxes will be opened dynamically per user
  // await Hive.openBox<LocalDocument>('documents'); // ❌ Remove this

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Start background cleanup service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backgroundCleanupServiceProvider).startCleanupService();
    });
  }

  @override
  void dispose() {
    // Stop background cleanup service
    ref.read(backgroundCleanupServiceProvider).stopCleanupService();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Default iPhone size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Secure File Sharing',
          theme: ThemeData(),
          home: SplashScreenManager(
            minimumSplashDuration: const Duration(seconds: 3),
            // child: const DocumentRequestScreen(),
            child: const AuthWrapper(),
          ),
          // home: const DocumentLinkingScreen(),
        );
      },
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  // bool _isLoading = true; // COMMENTED OUT - Now handled by splash screen

  @override
  void initState() {
    super.initState();
    _checkAuthState();

    // COMMENTED OUT - Now handled by splash screen
    // Add a timeout to prevent infinite loading
    // Future.delayed(Duration(seconds: 15), () {
    //   if (mounted && _isLoading) {
    //     print('⏰ [AuthWrapper] Loading timeout reached, stopping loading state');
    //     setState(() {
    //       _isLoading = false;
    //     });
    //   }
    // });
  }

  Future<void> _checkAuthState() async {
    print('🔍 [AuthWrapper] Starting auth state check...');

    // Listen to Firebase auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      print('🔍 [AuthWrapper] Firebase auth state changed: ${user?.email}');

      if (mounted) {
        if (user != null) {
          print('🔍 [AuthWrapper] Firebase user found: ${user.email}');

          // STEP 1: Try to load from Hive FIRST (instant)
          print('🔍 [AuthWrapper] Loading from Hive...');
          await ref.read(userProvider.notifier).loadStoredUser();
          final currentUserState = ref.read(userProvider);

          print(
            '🔍 [AuthWrapper] Hive result: user=${currentUserState.user?.name}, isAuthenticated=${currentUserState.isAuthenticated}',
          );

          if (currentUserState.user != null &&
              currentUserState.isAuthenticated) {
            // STEP 2: We have user data from Hive, navigate immediately
            print(
              '🔍 [AuthWrapper] User data from Hive, navigating to DocumentDashboard',
            );
            // COMMENTED OUT - Now handled by splash screen
            // setState(() {
            //   _isLoading = false;
            // });

            try {
              final rsaKeyService = RSAKeyService();
              await rsaKeyService.getOrGenerateKeyPair(currentUserState.user!.uuid);
              print('🔐 [AuthWrapper] RSA keys ready for user: ${currentUserState.user!.uuid}');
            } catch (e) {
              print('❌ [AuthWrapper] Error generating RSA keys: $e');
            }

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          DocumentDashboard(uuid: currentUserState.user!.uuid),
                ),
              );
            }

            // STEP 3: Refresh from server in background (optional)
            ref.read(userProvider.notifier).refreshUser();
            return;
          }

          // STEP 4: No Hive data, check if signup in progress
          if (currentUserState.signupInProgress) {
            print(
              '🔍 [AuthWrapper] Signup in progress, waiting for user data to be set',
            );
            return;
          }

          // STEP 5: No local data, fetch from network
          print(
            '🔍 [AuthWrapper] No Hive data, fetching by email: ${user.email}',
          );
          try {
            await ref.read(userProvider.notifier).fetchUserByEmail(user.email!);

            final userState = ref.read(userProvider);
            print(
              '🔍 [AuthWrapper] Network fetch result: isAuthenticated=${userState.isAuthenticated}, user=${userState.user?.name}, error=${userState.error}',
            );

            if (userState.isAuthenticated && userState.user != null) {
              // COMMENTED OUT - Now handled by splash screen
              // setState(() {
              //   _isLoading = false;
              // });
              try {
                final rsaKeyService = RSAKeyService();
                await rsaKeyService.getOrGenerateKeyPair(userState.user!.uuid);
                print('🔐 [AuthWrapper] RSA keys ready for user: ${userState.user!.uuid}');
              } catch (e) {
                print('❌ [AuthWrapper] Error generating RSA keys: $e');
              }
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            DocumentDashboard(uuid: userState.user!.uuid),
                  ),
                );
              }
            } else {
              // User not found in MongoDB, redirect to complete registration
              print(
                '❌ [AuthWrapper] User not found in MongoDB, redirecting to complete registration',
              );
              // COMMENTED OUT - Now handled by splash screen
              // setState(() {
              //   _isLoading = false;
              // });

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            OnboardingScreen(phoneNumber: '+919876543210'),
                  ),
                );
              }
            }
          } catch (e) {
            // Network error - show user-friendly message
            print('❌ [AuthWrapper] Error fetching user data: $e');
            // COMMENTED OUT - Now handled by splash screen
            // setState(() {
            //   _isLoading = false;
            // });

            // Show error dialog instead of redirecting
            if (mounted) {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text('Connection Error'),
                      content: Text(
                        'Unable to connect to server. Please check your internet connection.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _checkAuthState(); // Retry
                          },
                          child: Text('Retry'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Redirect to onboarding as fallback
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => OnboardingScreen(
                                      phoneNumber: '+919876543210',
                                    ),
                              ),
                            );
                          },
                          child: Text('Continue Offline'),
                        ),
                      ],
                    ),
              );
            }
          }
        } else {
          // User is not signed in - splash screen will handle showing auth screen
          print(
            '🔍 [AuthWrapper] No Firebase user, splash screen will handle auth flow',
          );
          // COMMENTED OUT - Now handled by splash screen
          // setState(() {
          //   _isLoading = false;
          // });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to user state changes to handle signup completion
    ref.listen<UserState>(userProvider, (previous, next) async {
      if (mounted) {
        // If we were loading and now have user data, navigate
        if (next.user != null &&
            next.isAuthenticated &&
            !next.signupInProgress) {
          print(
            '🔍 [AuthWrapper] User data set after signup, navigating to DocumentDashboard',
          );
          // COMMENTED OUT - Now handled by splash screen
          // setState(() {
          //   _isLoading = false;
          // });
          try {
            final rsaKeyService = RSAKeyService();
            await rsaKeyService.getOrGenerateKeyPair(next.user!.uuid);
            print('🔐 [AuthWrapper] RSA keys ready for user: ${next.user!.uuid}');
          } catch (e) {
            print('❌ [AuthWrapper] Error generating RSA keys: $e');
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentDashboard(uuid: next.user!.uuid),
            ),
          );
        }
      }
    });

    // COMMENTED OUT - Now handled by splash screen
    // if (_isLoading) {
    //   return Scaffold(
    //     body: Center(
    //       child: Column(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: [
    //           const CircularProgressIndicator(),
    //           const SizedBox(height: 20),
    //           Text(
    //             'Connecting to server...',
    //             style: TextStyle(
    //               fontSize: 16,
    //               color: Colors.grey[600],
    //             ),
    //           ),
    //           const SizedBox(height: 10),
    //           Text(
    //             'This may take a few moments',
    //             style: TextStyle(
    //               fontSize: 14,
    //               color: Colors.grey[500],
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   );
    // }

    // Check if user is currently signed in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is signed in, but we need to get MongoDB UUID
      // This will be handled by the auth state listener
      // NOTE: This CircularProgressIndicator is kept as a fallback during auth state transitions
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      // User is not signed in, show auth screen
       return const OnboardingScreen(phoneNumber: '+919876543210');
      //return const SignUpScreen(phoneNumber: '+919876543210');
    }
  }
}



//testing githubbnbb