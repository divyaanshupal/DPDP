import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// A custom SnackBar function that can be called from anywhere in your app
void showCustomSnackBar(BuildContext context, String message, Duration duration) {
  // First, remove any existing SnackBars to avoid them stacking
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  
  // Then, show the new SnackBar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      duration: duration,
      backgroundColor: const Color(0xFF333333), // A dark, modern color
      behavior: SnackBarBehavior.floating, // Makes the SnackBar float
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      elevation: 6.0,
    ),
  );
}
