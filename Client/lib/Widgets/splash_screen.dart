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
  late AnimationController _featuresController;
  late AnimationController _loadingController;
  late AnimationController _textController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _featuresOpacity;
  late Animation<double> _loadingOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _featuresSlide;

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

    // Features animation
    _featuresController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _featuresOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _featuresController, curve: Curves.easeIn),
    );
    _featuresSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _featuresController, curve: Curves.easeOut),
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
    // Start logo animation
    _logoController.forward();
    
    // Wait for logo to complete, then start features
    await Future.delayed(const Duration(milliseconds: 800));
    _featuresController.forward();
    
    // Wait for features to complete, then start loading
    await Future.delayed(const Duration(milliseconds: 600));
    _loadingController.forward();
    
    // Make loading animation repeat continuously
    _loadingController.repeat();
    
    // Wait for loading to complete, then start text
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _featuresController.dispose();
    _loadingController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF5170FF),
              const Color(0xFF5170FF).withOpacity(0.8),
              const Color(0xFF6C63FF),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background floating elements
            _buildFloatingElements(),
            
            // Main content
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    // Header with app name
                    _buildHeader(),
                    SizedBox(height: 40.h),
                    
                    // Logo section
                    Expanded(
                      flex: 3,
                      child: _buildLogoSection(),
                    ),
                    
                    // Features section
                    Expanded(
                      flex: 2,
                      child: _buildFeaturesSection(),
                    ),
                    
                    // Loading section
                    Expanded(
                      flex: 1,
                      child: _buildLoadingSection(),
                    ),
                    
                    // Tagline section
                    Expanded(
                      flex: 1,
                      child: _buildTaglineSection(),
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.security,
          color: Colors.white,
          size: 28.sp,
        ),
        SizedBox(width: 12.w),
        Text(
          'KYROTICS',
          style: GoogleFonts.inter(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Opacity(
            opacity: _logoOpacity.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow effect
                Container(
                  width: 140.w,
                  height: 140.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1.w,
                    ),
                  ),
                ),
                // Main logo container
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background pattern
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Main shield icon
                      Icon(
                        Icons.shield_outlined,
                        size: 60.sp,
                        color: Colors.white,
                      ),
                      // Small lock icon overlay
                      Positioned(
                        bottom: 20.h,
                        right: 20.w,
                        child: Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: Icon(
                            Icons.lock,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturesSection() {
    return AnimatedBuilder(
      animation: _featuresController,
      builder: (context, child) {
        return SlideTransition(
          position: _featuresSlide,
          child: Opacity(
            opacity: _featuresOpacity.value,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeatureItem(
                    Icons.lock_outline,
                    'Privacy First',
                    'Your data stays on your device',
                  ),
                  SizedBox(height: 8.h),
                  _buildFeatureItem(
                    Icons.security_outlined,
                    'End-to-End Encryption',
                    'Military-grade security',
                  ),
                  SizedBox(height: 8.h),
                  _buildFeatureItem(
                    Icons.account_tree_outlined,
                    'Blockchain Verified',
                    'Immutable sharing records',
                  ),
                  SizedBox(height: 8.h),
                  _buildFeatureItem(
                    Icons.verified_user_outlined,
                    'DPDP Compliant',
                    'Full regulatory compliance',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection() {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        return Opacity(
          opacity: _loadingOpacity.value,
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
                  
                  // Create pulsing effect that repeats
                  final scale = 0.6 + (0.4 * (1.0 - (animationValue * 2 - 1).abs()));
                  final opacity = 0.4 + (0.6 * (1.0 - (animationValue * 2 - 1).abs()));
                  
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(opacity),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(opacity * 0.3),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildTaglineSection() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Opacity(
          opacity: _textOpacity.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Secure • Private • Verified',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Your documents, your control',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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
