import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kyrotics/features/auth/view/OtpVerification.dart';
import 'package:kyrotics/Screens/T&C.dart';
import 'package:kyrotics/Widgets/FirebaseOtpSender.dart';
import 'package:kyrotics/Widgets/PhoneNumberRegix.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required String phoneNumber});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+91'; // Default country code

  // A list of country codes for the dropdown
  final List<String> _countryCodes = ['+1', '+44', '+91', '+81', '+86'];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // A light grey background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 20.0, left: 24.0, right: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Logo or Name Placeholder
                Center(
                  child: Image.asset(
                    'assets/checklist.png',
                    height: 150,
                    fit: BoxFit.contain, // optional for scaling
                  ),
                ),
                const SizedBox(height: 40),

                // Headline Text
                Text(
                  'Enter your phone number',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),

                // Subheading Text
                Text(
                  'We will send you a verification code. Carrier rates may apply.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 40),

                // Phone Number Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Country Code Picker
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCountryCode,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black54,
                            ),
                            items:
                                _countryCodes.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedCountryCode = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                      // Phone Number Text Field
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'Phone Number',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.black38,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child:
                      isLoading
                          ? const SpinKitFadingCube(
                            color: Colors.black,
                            size: 30,
                          )
                          : ElevatedButton(
                            onPressed: () {
                              // Add your phone number submission logic here
                              final phone = _phoneController.text.trim();
                              if (_selectedCountryCode == '+91') {
                                if (isValidIndianPhoneNumber(phone)) {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  final phoneNumber =
                                      _selectedCountryCode + phone;
                                  FirebasePhoneAuthHelper.verifyPhoneNumber(
                                    phoneNumber: phoneNumber,
                                    context: context,
                                    onCodeSent: (verficationId, resendToken) {
                                      if (!mounted) return;
                                      setState(() {
                                        isLoading = false;
                                      });
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => OtpScreen(
                                                phoneNumber: phoneNumber,
                                                verificationId: verficationId,
                                                resendToken: resendToken,
                                              ),
                                        ),
                                      );
                                    },
                                  );
                                  print('valid number proceed');
                                } else {
                                  AnimatedSnackBar.material(
                                    'Invalid Phone Number',
                                    type: AnimatedSnackBarType.error,
                                  ).show(context);
                                  print('else entered');
                                }
                              } else {
                                final phoneNumber =
                                    _selectedCountryCode + phone;
                                print('Phone number entered: $phoneNumber');
                                //navigate to otp screen
                              }
                              // You would typically navigate to an OTP screen here
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF6C63FF,
                              ), // A nice purple color
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
                              'Continue',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                ),
                const SizedBox(height: 20),

                // Terms of Service and Privacy Policy
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                        children: [
                          const TextSpan(
                            text: 'By continuing, you agree to our ',
                          ),
                          TextSpan(
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TermsScreen(),
                                      ),
                                    );
                                  },
                            text: 'Terms of Service',
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              decoration: TextDecoration.underline,
                            ),
                            // Add recognizer for tap events
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            recognizer:
                                TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TermsScreen(),
                                      ),
                                    );
                                  },
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              decoration: TextDecoration.underline,
                            ),
                            // Add recognizer for tap events
                          ),
                        ],
                      ),
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
