import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

String generateUserId() {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const digits = '0123456789';
  final rand = Random.secure();

  // Generate 3 random uppercase letters
  final letterPart =
      List.generate(3, (_) => letters[rand.nextInt(letters.length)]).join();  

  // Generate 4 random digits
  final numberPart =
      List.generate(4, (_) => digits[rand.nextInt(digits.length)]).join();

  return letterPart + numberPart; // Final ID: 3 letters + 4 numbers
}

Future<String> generateUUID() async {
  String id;
  bool exists;

  do {
    id = generateUserId();
    final result =
        await FirebaseFirestore.instance
            .collection('users')
            .where('userId', isEqualTo: id)
            .limit(1)
            .get();

    exists = result.docs.isNotEmpty;
  } while (exists);

  return id;
}
