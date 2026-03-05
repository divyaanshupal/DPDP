import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kyrotics/features/encrption/rsa_key_service.dart';
import 'package:kyrotics/features/home/presentation/newHomeScreen.dart';
import 'package:kyrotics/features/auth/application/user_provider.dart';
import 'package:kyrotics/models/usermodel.dart';
import 'package:kyrotics/services/registerUserFunction.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const OnboardingScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isLoginMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Welcome Image
                  Center(
                    child: Image.asset(
                      'assets/welcome.png',
                      height: 200,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person_outline_rounded,
                          size: 80,
                          color: Color(0xFF6C63FF),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    isLoginMode ? 'Welcome back!' : 'Let\'s get your profile set up.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Username Text Field (only for signup)
                  if (!isLoginMode) ...[
                    TextFormField(
                      controller: _usernameController,
                      decoration: _buildInputDecoration(
                        'Username',
                        Icons.person_outline,
                      ),
                      validator: (value) {
                        if (!isLoginMode && (value == null || value.isEmpty)) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Email Text Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration(
                      'Email Address',
                      Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Text Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _buildInputDecoration(
                      'Password',
                      Icons.lock_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (!isLoginMode && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: isLoading
                        ? const SizedBox(
                            height: 50,
                            child: Center(
                              child: SpinKitFadingCube(
                                color: Colors.black,
                                size: 30,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _handleFormSubmission,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                              shadowColor: const Color(0xFF6C63FF).withOpacity(0.4),
                            ),
                            child: Text(
                              isLoginMode ? 'Sign In' : 'Sign Up',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Toggle Login/Signup Button
                  TextButton(
                    onPressed: _toggleAuthMode,
                    child: Text(
                      isLoginMode ? 'Don\'t have an account? Sign Up' : 'Already have an account? Sign In',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build consistent InputDecoration for text fields
  InputDecoration _buildInputDecoration(String label, IconData prefixIcon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.black54),
      prefixIcon: Icon(prefixIcon, color: Colors.black45),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  /// Toggles between login and signup modes
  void _toggleAuthMode() {
    setState(() {
      isLoginMode = !isLoginMode;
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _usernameController.clear();
    });
  }

  /// Handles form submission for both login and signup
  Future<void> _handleFormSubmission() async {
    // Validate the form before proceeding
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      if (isLoginMode) {
        await _handleFirebaseLogin();
      } else {
        await _handleFirebaseSignup();
      }
    }
  }

  /// Handles Firebase user signup process
  Future<void> _handleFirebaseSignup() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _usernameController.text.trim();
      
      // Set signup in progress flag to prevent AuthWrapper from fetching user by email
      ref.read(userProvider.notifier).setSignupInProgress(true);
      
      // Create Firebase user
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      
      // Register with backend
      final result = await RegisterUser.registerUser(
        name: name,
        email: email,
        phone: widget.phoneNumber,
      );
      
      if (result['success']) {
        // Show success message
        AnimatedSnackBar.material(
          'Account created successfully!',
          type: AnimatedSnackBarType.success,
        ).show(context);
        
        // Create user model with the data we have
        final newUser = UserModel(
          uuid: result['uuid'],
          name: name,
          email: email,
          phone: widget.phoneNumber,
          gender: '', // Will be updated when full user data is fetched
          documents: [], // Empty documents array initially
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Set the user in the provider
        ref.read(userProvider.notifier).updateUser(newUser);
        
        // Navigate to main screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentDashboard(uuid: result['uuid']),
            ),
          );
        }
      } else {
        // Clear signup flag on backend error
        ref.read(userProvider.notifier).setSignupInProgress(false);
        _showErrorMessage('Error: ${result['error']}');
      }
    } on FirebaseAuthException catch (e) {
      // Clear signup flag on Firebase auth error
      ref.read(userProvider.notifier).setSignupInProgress(false);
      _showErrorMessage(_getFirebaseErrorMessage(e));
    } catch (e) {
      // Clear signup flag on any other error
      ref.read(userProvider.notifier).setSignupInProgress(false);
      _showErrorMessage('Unexpected error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// Handles Firebase user login process
  Future<void> _handleFirebaseLogin() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Sign in with Firebase
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Get MongoDB UUID by searching for user with this email
      final result = await RegisterUser.getUserByEmail(email: email);
      
      if (result['success']) {
        // Show welcome message
        AnimatedSnackBar.material(
          'Welcome back!',
          type: AnimatedSnackBarType.success,
        ).show(context);

        // Fetch complete user data using the provider
        await ref.read(userProvider.notifier).fetchUserByUuid(result['uuid']);
        try {
          final rsaKeyService = RSAKeyService();
          await rsaKeyService.getOrGenerateKeyPair(result['uuid']);
          print('🔐 [UserDetails] RSA keys ready for user: ${result['uuid']}');
        } catch (e) {
          print('❌ [UserDetails] Error generating RSA keys: $e');
        }

        // Navigate to main screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentDashboard(uuid: result['uuid']),
            ),
          );
        }
      } else {
        _showErrorMessage('User not found in database. Please sign up first.');
      }
    } on FirebaseAuthException catch (e) {
      _showErrorMessage(_getFirebaseErrorMessage(e));
    } catch (e) {
      _showErrorMessage('Unexpected error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// Shows error message to user
  void _showErrorMessage(String message) {
    if (mounted) {
      AnimatedSnackBar.material(
        message,
        type: AnimatedSnackBarType.error,
      ).show(context);
    }
  }

  /// Gets user-friendly error message for Firebase auth exceptions
  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
