import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum ToastType {
  success, // Green for accepted
  error,   // Red for rejected
  info,    // Blue for document received
}

class CoolToast {
  static void show({
    required BuildContext context,
    required String message,
    required ToastType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Get overlay entry
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Get colors based on type
    final colors = _getColors(type);

    overlayEntry = OverlayEntry(
      builder: (context) => _CoolToastWidget(
        message: message,
        colors: colors,
        type: type,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    // Insert overlay
    overlay.insert(overlayEntry);

    // Auto dismiss after duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  static ({Color primary, Color secondary, Color icon, IconData iconData}) _getColors(ToastType type) {
    switch (type) {
      case ToastType.success:
        return (
          primary: const Color(0xFF10B981), // Emerald green
          secondary: const Color(0xFF059669),
          icon: Colors.white,
          iconData: Icons.check_circle_rounded,
        );
      case ToastType.error:
        return (
          primary: const Color(0xFFEF4444), // Red
          secondary: const Color(0xFFDC2626),
          icon: Colors.white,
          iconData: Icons.cancel_rounded,
        );
      case ToastType.info:
        return (
          primary: const Color(0xFF5170FF), // App's primary blue
          secondary: const Color(0xFF6C63FF), // App's secondary purple
          icon: Colors.white,
          iconData: Icons.file_download_rounded,
        );
    }
  }

  // Helper methods for easy calling
  static void success(BuildContext context, String message) {
    show(context: context, message: message, type: ToastType.success);
  }

  static void error(BuildContext context, String message) {
    show(context: context, message: message, type: ToastType.error);
  }

  static void info(BuildContext context, String message) {
    show(context: context, message: message, type: ToastType.info);
  }
}

class _CoolToastWidget extends StatefulWidget {
  final String message;
  final ({Color primary, Color secondary, Color icon, IconData iconData}) colors;
  final ToastType type;
  final VoidCallback onDismiss;

  const _CoolToastWidget({
    required this.message,
    required this.colors,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_CoolToastWidget> createState() => _CoolToastWidgetState();
}

class _CoolToastWidgetState extends State<_CoolToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Slide from top
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Fade in
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Bounce effect
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16.h,
      left: 16.w,
      right: 16.w,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _bounceAnimation,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.colors.primary,
                        widget.colors.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: widget.colors.primary.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon with pulse animation
                      _PulsingIcon(
                        icon: widget.colors.iconData,
                        color: widget.colors.icon,
                      ),
                      SizedBox(width: 16.w),
                      
                      // Message
                      Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            height: 1.3,
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 12.w),
                      
                      // Dismiss button
                      GestureDetector(
                        onTap: _dismiss,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
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
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _PulsingIcon({
    required this.icon,
    required this.color,
  });

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.icon,
          color: widget.color,
          size: 24.sp,
        ),
      ),
    );
  }
}

