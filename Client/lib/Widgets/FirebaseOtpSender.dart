import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animated_snack_bar/animated_snack_bar.dart';

typedef OnCodeSent = void Function(String verificationId, int? resendToken);

class FirebasePhoneAuthHelper {
  static void verifyPhoneNumber({
    required String phoneNumber,
    required BuildContext context,
    required OnCodeSent onCodeSent,
    int? forceResendingToken,
  }) {
    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: forceResendingToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Optional: handle auto-retrieval
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        AnimatedSnackBar.material(
          'Verification failed: ${e.message}',
          type: AnimatedSnackBarType.error,
        ).show(context);
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print('Auto retrieval timeout for $phoneNumber');
      },
    );
  }
}
