import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kyrotics/features/auth/view/UserDetails.dart';
import 'package:pinput/pinput.dart'; // Assuming you have this from our previous step

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _pinController = TextEditingController();
  var isLoading = false;
  @override
  Widget build(BuildContext context) {
    // Pinput theme for the default state
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: GoogleFonts.poppins(fontSize: 22, color: Colors.black),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 20.0, left: 24.0, right: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Onboarding Image from local assets
                Center(
                  child: Image.asset(
                    'assets/pin.png', // Using the same asset
                    height: 150,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.lock_outline_rounded,
                        size: 80,
                        color: Color(0xFF6C63FF),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),

                // Headline Text
                Text(
                  'Enter Verification Code',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),

                // Subheading Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'We have sent the code verification to your number: ${widget.phoneNumber}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Pinput (OTP) Field
                Pinput(
                  length: 6, // The length of your OTP
                  controller: _pinController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: const Color(0xFF6C63FF)),
                    ),
                  ),
                  submittedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: Colors.green),
                    ),
                  ),
                  onCompleted: (pin) {
                    // This function is called when the user finishes entering the OTP
                    print('OTP Entered: $pin');
                    // You can add your verification logic here
                  },
                ),
                const SizedBox(height: 40),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  child:
                      isLoading
                          ? Center(
                            child: SpinKitFadingCube(
                              color: Colors.black,
                              size: 30,
                            ),
                          )
                          : ElevatedButton(
                            onPressed: () async {
                              final enteredOtp = _pinController.text.trim();

                              if (enteredOtp.length == 6) {
                                setState(() {
                                  isLoading = true;
                                });
                                try {
                                  final credential =
                                      PhoneAuthProvider.credential(
                                        verificationId: widget.verificationId,
                                        smsCode: enteredOtp,
                                      );

                                  await FirebaseAuth.instance
                                      .signInWithCredential(credential);

                                  AnimatedSnackBar.material(
                                    'Verification Successful!',
                                    type: AnimatedSnackBarType.success,
                                  ).show(context);


                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => OnboardingScreen(
                                            phoneNumber: widget.phoneNumber,
                                          ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  AnimatedSnackBar.material(
                                    'Invalid OTP. Please try again.',
                                    type: AnimatedSnackBarType.error,
                                  ).show(context);
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              } else {
                                AnimatedSnackBar.material(
                                  'Please enter the complete OTP',
                                  type: AnimatedSnackBarType.warning,
                                ).show(context);
                              }
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                              shadowColor: const Color(
                                0xFF6C63FF,
                              ).withOpacity(0.4),
                            ),
                            child: Text(
                              'Verify',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                ),
                const SizedBox(height: 20),

                // Resend Code Link
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      children: [
                        const TextSpan(text: 'Didn\'t receive a code? '),
                        TextSpan(
                          text: 'Resend',
                          style: const TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.w600,
                          ),
                          // Add recognizer for tap events here
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




