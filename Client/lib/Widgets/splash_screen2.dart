import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _loadingController;
  late AnimationController _textController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _loadingOpacity;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    // Loading animation
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeIn),
    );

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
  }

  void _startAnimationSequence() async {
    // Fade in gradient background (0-300ms)
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Logo scale-in (300-1000ms)
    _logoController.forward();
    
    // Make logo breathe continuously
    _logoController.repeat(reverse: true);
    
    // Wait for logo to complete, then start tagline
    await Future.delayed(const Duration(milliseconds: 700));
    _textController.forward();
    
    // Start subtle loading animation
    await Future.delayed(const Duration(milliseconds: 300));
    _loadingController.forward();
    
    // Make loading animation repeat continuously
    _loadingController.repeat();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loadingController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4E54C8),
              Color(0xFF8F94FB),
              Color(0xFFB794F6),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Radial gradient overlay for depth
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),

            // Background floating elements
            _buildFloatingElements(),

            // Main content - centered and minimal
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hero logo section with pulsing header
                    Expanded(
                      flex: 3,
                      child: _buildHeroLogoWithHeader(),
                    ),
                    
                    // Minimal tagline
                    Expanded(
                      flex: 1,
                      child: _buildMinimalTagline(),
                    ),
                    
                    // Subtle loading indicator
                    Expanded(
                      flex: 1,
                      child: _buildSubtleLoading(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHeroLogoWithHeader() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero logo
            Transform.scale(
              scale: _logoScale.value,
              child: Opacity(
                opacity: _logoOpacity.value,
                child: Center(
                  child: Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Main shield icon
                              Icon(
                                Icons.security,
                                color: Colors.white,
                                size: 48.sp,
                              ),
                              // Floating lock overlay
                              Positioned(
                                top: 20.h,
                                right: 20.w,
                                child: Transform.scale(
                                  scale: 0.6,
                                  child: Icon(
                                    Icons.lock_outline,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 16.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 30.h),
            
            // Pulsing KYROTICS header
            Transform.scale(
              scale: _logoScale.value,
              child: Opacity(
                opacity: _logoOpacity.value,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon(
                    //   Icons.security,
                    //   color: Colors.white,
                    //   size: 28.sp,
                    // ),
                    // SizedBox(width: 12.w),
                    Text(
                      'KYROTICS',
                      style: GoogleFonts.inter(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildMinimalTagline() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Opacity(
          opacity: _textOpacity.value,
          child: Center(
            child: Text(
              'Secure. Private. Verified.',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }


  Widget _buildSubtleLoading() {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        return Opacity(
          opacity: _loadingOpacity.value,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, child) {
                    // Create continuous animation using modulo for infinite loop
                    final baseAnimation = (_loadingController.value * 2) % 1.0;
                    final delay = index * 0.5;
                    final animationValue = (baseAnimation + delay) % 1.0;
                    
                    // Create subtle pulsing effect
                    final scale = 0.8 + (0.2 * (1.0 - (animationValue * 2 - 1).abs()));
                    final opacity = 0.3 + (0.7 * (1.0 - (animationValue * 2 - 1).abs()));
                    
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(opacity),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        );
      },
    );
  }


  Widget _buildFloatingElements() {
    return Stack(
      children: [
        // Floating security icons
        Positioned(
          top: 100.h,
          left: 30.w,
          child: _buildFloatingIcon(Icons.security, 0.0),
        ),
        Positioned(
          top: 200.h,
          right: 40.w,
          child: _buildFloatingIcon(Icons.lock, 0.5),
        ),
        Positioned(
          bottom: 150.h,
          left: 50.w,
          child: _buildFloatingIcon(Icons.verified_user, 1.0),
        ),
        Positioned(
          bottom: 250.h,
          right: 30.w,
          child: _buildFloatingIcon(Icons.account_tree, 1.5),
        ),
        // Floating dots
        Positioned(
          top: 150.h,
          right: 80.w,
          child: _buildFloatingDot(0.0),
        ),
        Positioned(
          bottom: 200.h,
          left: 80.w,
          child: _buildFloatingDot(0.8),
        ),
        Positioned(
          top: 300.h,
          left: 80.w,
          child: _buildFloatingDot(1.2),
        ),
      ],
    );
  }

  Widget _buildFloatingIcon(IconData icon, double delay) {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final animationValue = (_logoController.value - delay).clamp(0.0, 1.0);
        final opacity = (1.0 - (animationValue * 2 - 1).abs()) * 0.3;
        final scale = 0.8 + (0.2 * (1.0 - (animationValue * 2 - 1).abs()));
        
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.4),
              size: 20.sp,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingDot(double delay) {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final animationValue = (_logoController.value - delay).clamp(0.0, 1.0);
        final opacity = (1.0 - (animationValue * 2 - 1).abs()) * 0.2;
        final scale = 0.5 + (0.5 * (1.0 - (animationValue * 2 - 1).abs()));
        
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ),
        );
      },
    );
  }
}
