import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyrotics/features/auth/application/user_provider.dart';
import 'package:kyrotics/features/auth/application/user_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'splash_screen.dart';

class SplashScreenManager extends ConsumerStatefulWidget {
  final Widget child;
  final Duration minimumSplashDuration;
  
  const SplashScreenManager({
    super.key,
    required this.child,
    this.minimumSplashDuration = const Duration(seconds: 2),
  });

  @override
  ConsumerState<SplashScreenManager> createState() => _SplashScreenManagerState();
}

class _SplashScreenManagerState extends ConsumerState<SplashScreenManager>
    with TickerProviderStateMixin {
  bool _showSplash = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  DateTime? _splashStartTime;
  int _checkCount = 0;
  static const int _maxChecks = 20; // Maximum number of checks before forcing exit

  @override
  void initState() {
    super.initState();
    _splashStartTime = DateTime.now();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start checking app readiness after minimum duration
    Future.delayed(widget.minimumSplashDuration, () {
      _checkAppReadiness();
    });
  }

  void _checkAppReadiness() {
    if (!mounted) return;
    
    _checkCount++;
    print('🔍 [SplashScreenManager] Check #$_checkCount of $_maxChecks');
    
    // Safety check - force exit if we've checked too many times
    if (_checkCount > _maxChecks) {
      print('⚠️ [SplashScreenManager] Maximum checks reached, forcing splash screen exit');
      _hideSplashScreen();
      return;
    }
    
    // Check if minimum splash duration has passed
    final elapsed = DateTime.now().difference(_splashStartTime!);
    if (elapsed < widget.minimumSplashDuration) {
      Future.delayed(widget.minimumSplashDuration - elapsed, _checkAppReadiness);
      return;
    }

    // Check Firebase auth state
    final user = FirebaseAuth.instance.currentUser;
    final userState = ref.read(userProvider);
    
    print('🔍 [SplashScreenManager] Checking app readiness...');
    print('🔍 [SplashScreenManager] Firebase user: ${user?.email}');
    print('🔍 [SplashScreenManager] User state: isLoading=${userState.isLoading}, isAuthenticated=${userState.isAuthenticated}, user=${userState.user?.name}');
    print('🔍 [SplashScreenManager] User error: ${userState.error}');
    print('🔍 [SplashScreenManager] Signup in progress: ${userState.signupInProgress}');
    
    if (user == null) {
      // No Firebase user - app is ready to show auth screen
      print('✅ [SplashScreenManager] No Firebase user, showing auth screen');
      _hideSplashScreen();
    } else if (userState.isAuthenticated && userState.user != null && !userState.isLoading) {
      // User is authenticated and loaded - app is ready
      print('✅ [SplashScreenManager] User authenticated and loaded, showing home screen');
      _hideSplashScreen();
    } else if (userState.error != null && !userState.isLoading) {
      // Error occurred and not loading - show error screen
      print('❌ [SplashScreenManager] Error occurred, showing error screen');
      _hideSplashScreen();
    } else if (!userState.isLoading && userState.user == null) {
      // Firebase user exists but no user data - this means we need to fetch user data
      // Let's trigger the user loading process and wait a bit more
      print('🔄 [SplashScreenManager] Firebase user exists but no user data, triggering user fetch...');
      
      // Trigger user loading if not already in progress
      if (!userState.isLoading) {
        print('🔄 [SplashScreenManager] Triggering fetchUserByEmail for: ${user.email}');
        ref.read(userProvider.notifier).fetchUserByEmail(user.email!);
      }
      
      // Wait a bit longer for the user data to load
      Future.delayed(const Duration(milliseconds: 1000), _checkAppReadiness);
    } else {
      // Still loading or in transition - keep splash screen
      print('⏳ [SplashScreenManager] Still loading, keeping splash screen');
      // Check again in 500ms
      Future.delayed(const Duration(milliseconds: 500), _checkAppReadiness);
    }
  }

  void _hideSplashScreen() {
    if (!mounted || !_showSplash) return;
    
    _fadeController.forward().then((_) {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to user state changes to handle dynamic loading
    ref.listen<UserState>(userProvider, (previous, next) {
      if (!mounted || !_showSplash) return;
      
      print('🔍 [SplashScreenManager] User state changed: isLoading=${next.isLoading}, isAuthenticated=${next.isAuthenticated}, user=${next.user?.name}');
      
      // If we're still showing splash and user state indicates app is ready
      if (!next.isLoading && (next.isAuthenticated || next.error != null)) {
        _checkAppReadiness();
      }
    });

    if (_showSplash) {
      return AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: 1.0 - _fadeAnimation.value,
            child: const SplashScreen(),
          );
        },
      );
    }
    
    return widget.child;
  }
}
