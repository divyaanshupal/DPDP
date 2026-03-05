// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:pointycastle/export.dart';
// import 'package:asn1lib/asn1lib.dart';
// import 'package:hive_flutter/hive_flutter.dart';

// final rsaKeyServiceProvider = Provider<RSAKeyService>((ref) => RSAKeyService());

// class RSAKeyService {
//   static const String _keyBoxName = 'rsa_keys';

//   /// Generate RSA key pair (2048-bit for good security)
//   AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateKeyPair() {
//     final keyGen = RSAKeyGenerator();
//     final secureRandom = FortunaRandom();
    
//     // Seed the random number generator
//     final seedSource = Random.secure();
//     final seeds = <int>[];
//     for (int i = 0; i < 32; i++) {
//       seeds.add(seedSource.nextInt(255));
//     }
//     secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

//     final keyParams = RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64);
//     final paramsWithRNG = ParametersWithRandom(keyParams, secureRandom);
    
//     keyGen.init(paramsWithRNG);
//     final keyPair = keyGen.generateKeyPair();
//     return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
//       keyPair.publicKey as RSAPublicKey,
//       keyPair.privateKey as RSAPrivateKey,
//     );
//   }

//   /// Convert RSA public key to PEM format (for storage/transmission)
//   String publicKeyToPem(RSAPublicKey publicKey) {
//     final algorithmSeq = ASN1Sequence();
//     final algorithmIdentifier = ASN1Sequence();
//     algorithmIdentifier.add(ASN1ObjectIdentifier.fromComponentString('1.2.840.113549.1.1.1'));
//     algorithmIdentifier.add(ASN1Null());
//     algorithmSeq.add(algorithmIdentifier);

//     final publicKeySeq = ASN1Sequence();
//     publicKeySeq.add(ASN1Integer(publicKey.modulus!));
//     publicKeySeq.add(ASN1Integer(publicKey.exponent!));
//     final publicKeyBitString = ASN1BitString(publicKeySeq.encodedBytes);
//     algorithmSeq.add(publicKeyBitString);

//     final topLevelSeq = ASN1Sequence();
//     topLevelSeq.add(algorithmSeq);
//     final dataBase64 = base64Encode(topLevelSeq.encodedBytes);

//     return '-----BEGIN PUBLIC KEY-----\n$dataBase64\n-----END PUBLIC KEY-----';
//   }

//   /// Convert RSA private key to PEM format
//   String privateKeyToPem(RSAPrivateKey privateKey) {
//     final version = ASN1Integer(BigInt.from(0));
//     final modulus = ASN1Integer(privateKey.n!);
//     final publicExponent = ASN1Integer(privateKey.exponent!);
//     final privateExponent = ASN1Integer(privateKey.d!);
//     final p = ASN1Integer(privateKey.p!);
//     final q = ASN1Integer(privateKey.q!);
//     final dP = privateKey.d! % (privateKey.p! - BigInt.from(1));
//     final dQ = privateKey.d! % (privateKey.q! - BigInt.from(1));
//     final qInv = privateKey.q!.modInverse(privateKey.p!);

//     final seq = ASN1Sequence();
//     seq.add(version);
//     seq.add(modulus);
//     seq.add(publicExponent);
//     seq.add(privateExponent);
//     seq.add(p);
//     seq.add(q);
//     seq.add(ASN1Integer(dP));
//     seq.add(ASN1Integer(dQ));
//     seq.add(ASN1Integer(qInv));

//     final topLevelSeq = ASN1Sequence();
//     topLevelSeq.add(seq);
//     final dataBase64 = base64Encode(topLevelSeq.encodedBytes);

//     return '-----BEGIN RSA PRIVATE KEY-----\n$dataBase64\n-----END RSA PRIVATE KEY-----';
//   }

//   /// Parse PEM string to RSA public key
//   // RSAPublicKey publicKeyFromPem(String pemString) {
//   //   final publicKeyDER = _pemToDER(pemString);
//   //   final asn1Parser = ASN1Parser(publicKeyDER);
//   //   final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
//   //   final publicKeyBitString = topLevelSeq.elements![1] as ASN1BitString;
//   //   final publicKeyAsn = ASN1Parser(publicKeyBitString.valueBytes());
//   //   final publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
//   //   final modulus = publicKeySeq.elements![0] as ASN1Integer;
//   //   final exponent = publicKeySeq.elements![1] as ASN1Integer;
    
//   //   final rsaPublicKey = RSAPublicKey(modulus.valueAsBigInteger, exponent.valueAsBigInteger);
//   //   return rsaPublicKey;
//   // }
//     /// Parse PEM string to RSA public key
//     /// Parse PEM string to RSA public key
//   RSAPublicKey publicKeyFromPem(String pemString) {
//     try {
//       // Normalize PEM first (handle escaped newlines from JSON)
//       final normalizedPem = pemString
//           .replaceAll("\\n", "\n") // convert escaped newline to real newline
//           .replaceAll("\r", "")    // remove CR
//           .trim();
      
//       final publicKeyDER = _pemToDER(normalizedPem);
      
//       if (publicKeyDER.isEmpty) {
//         throw Exception('Failed to decode PEM: empty DER data');
//       }
      
//       final asn1Parser = ASN1Parser(publicKeyDER);
//       final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
      
//       if (topLevelSeq.elements == null || topLevelSeq.elements!.isEmpty) {
//         throw Exception('Invalid ASN1 structure: topLevelSeq is empty');
//       }
      
//       // Fix: Access algorithmSeq first, then get publicKeyBitString from it
//       final algorithmSeq = topLevelSeq.elements![0] as ASN1Sequence;
      
//       if (algorithmSeq.elements == null || algorithmSeq.elements!.length < 2) {
//         throw Exception('Invalid ASN1 structure: algorithmSeq should have at least 2 elements');
//       }
      
//       final publicKeyBitString = algorithmSeq.elements![1] as ASN1BitString;
//       final keyBytes = publicKeyBitString.valueBytes();
      
//       if (keyBytes.isEmpty) {
//         throw Exception('Invalid ASN1 structure: publicKeyBitString is empty');
//       }
      
//       final publicKeyAsn = ASN1Parser(keyBytes);
//       final publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
      
//       if (publicKeySeq.elements == null || publicKeySeq.elements!.length < 2) {
//         throw Exception('Invalid ASN1 structure: publicKeySeq should have 2 elements');
//       }
      
//       final modulus = publicKeySeq.elements![0] as ASN1Integer;
//       final exponent = publicKeySeq.elements![1] as ASN1Integer;
      
//       final rsaPublicKey = RSAPublicKey(modulus.valueAsBigInteger, exponent.valueAsBigInteger);
//       return rsaPublicKey;
//     } catch (e) {
//       throw Exception('Failed to parse public key from PEM: $e');
//     }
//   }

//   /// Parse PEM string to RSA private key
//   RSAPrivateKey privateKeyFromPem(String pemString) {
//     final privateKeyDER = _pemToDER(pemString);
//     final asn1Parser = ASN1Parser(privateKeyDER);
//     final seq = asn1Parser.nextObject() as ASN1Sequence;
//     final privateKeySeq = seq.elements![0] as ASN1Sequence;
    
//     final modulus = privateKeySeq.elements![1] as ASN1Integer;
//     final publicExponent = privateKeySeq.elements![2] as ASN1Integer;
//     final privateExponent = privateKeySeq.elements![3] as ASN1Integer;
//     final p = privateKeySeq.elements![4] as ASN1Integer;
//     final q = privateKeySeq.elements![5] as ASN1Integer;
    
//     final rsaPrivateKey = RSAPrivateKey(
//       modulus.valueAsBigInteger,
//       privateExponent.valueAsBigInteger,
//       p.valueAsBigInteger,
//       q.valueAsBigInteger,
//     );
//     return rsaPrivateKey;
//   }

//   /// Helper: Convert PEM to DER format
//   Uint8List _pemToDER(String pem) {
//     final lines = pem.split('\n');
//     final base64Lines = lines.where((line) => 
//       !line.startsWith('-----') && line.trim().isNotEmpty
//     ).join();
//     return base64Decode(base64Lines);
//   }

//   /// Get or generate RSA key pair for a user
//   Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>> getOrGenerateKeyPair(String uuid) async {
//     try {
//       final box = await Hive.openBox(_keyBoxName);
//       final publicKeyPem = box.get('${uuid}_public');
//       final privateKeyPem = box.get('${uuid}_private');
      
//       if (publicKeyPem != null && privateKeyPem != null) {
//         return AsymmetricKeyPair(
//           publicKeyFromPem(publicKeyPem),
//           privateKeyFromPem(privateKeyPem),
//         );
//       }
//     } catch (e) {
//       print('Error loading keys: $e');
//     }
    
//     // Generate new key pair if not found
//     final keyPair = generateKeyPair();
//     await saveKeyPair(uuid, keyPair);
//     return keyPair;
//   }

//   /// Save RSA key pair for a user
//   Future<void> saveKeyPair(String uuid, AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> keyPair) async {
//     try {
//       final box = await Hive.openBox(_keyBoxName);
//       await box.put('${uuid}_public', publicKeyToPem(keyPair.publicKey));
//       await box.put('${uuid}_private', privateKeyToPem(keyPair.privateKey));
//     } catch (e) {
//       print('Error saving keys: $e');
//       rethrow;
//     }
//   }

//   /// Delete RSA keys for a user (for logout)
// Future<void> deleteKeyPair(String uuid) async {
//   try {
//     final box = await Hive.openBox(_keyBoxName);
//     await box.delete('${uuid}_public');
//     await box.delete('${uuid}_private');
//     print('🔐 [RSAKeyService] Deleted RSA keys for user: $uuid');
//   } catch (e) {
//     print('❌ [RSAKeyService] Error deleting keys: $e');
//     rethrow;
//   }
// }

//   /// Get public key as PEM string for a user
//   Future<String?> getPublicKeyPem(String uuid) async {
//     try {
//       final box = await Hive.openBox(_keyBoxName);
//       return box.get('${uuid}_public');
//     } catch (e) {
//       return null;
//     }
//   }

//   /// Get private key as PEM string for a user
//   Future<String?> getPrivateKeyPem(String uuid) async {
//     try {
//       final box = await Hive.openBox(_keyBoxName);
//       return box.get('${uuid}_private');
//     } catch (e) {
//       return null;
//     }
//   }
// }


import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';
import 'package:hive_flutter/hive_flutter.dart';

final rsaKeyServiceProvider = Provider<RSAKeyService>((ref) => RSAKeyService());

class RSAKeyService {
  static const String _keyBoxName = 'rsa_keys';

  /// Generate RSA key pair (2048-bit for good security)
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateKeyPair() {
    final keyGen = RSAKeyGenerator();
    final secureRandom = FortunaRandom();
    
    // Seed the random number generator
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final keyParams = RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64);
    final paramsWithRNG = ParametersWithRandom(keyParams, secureRandom);
    
    keyGen.init(paramsWithRNG);
    final keyPair = keyGen.generateKeyPair();
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      keyPair.publicKey as RSAPublicKey,
      keyPair.privateKey as RSAPrivateKey,
    );
  }

  /// Convert RSA public key to PEM format (Standard X.509 SubjectPublicKeyInfo)
  String publicKeyToPem(RSAPublicKey publicKey) {
    // 1. Create the Algorithm Identifier Sequence
    //    SEQUENCE { OID, NULL }
    final algorithmSeq = ASN1Sequence();
    algorithmSeq.add(ASN1ObjectIdentifier.fromComponentString('1.2.840.113549.1.1.1'));
    algorithmSeq.add(ASN1Null());

    // 2. Create the RSA Public Key Sequence
    //    SEQUENCE { Modulus, Exponent }
    final publicKeySeq = ASN1Sequence();
    publicKeySeq.add(ASN1Integer(publicKey.modulus!));
    publicKeySeq.add(ASN1Integer(publicKey.exponent!));
    
    // 3. Wrap the RSA Sequence in a BitString
    final publicKeyBitString = ASN1BitString(publicKeySeq.encodedBytes);

    // 4. Create the Top Level Sequence
    //    SEQUENCE { AlgorithmIdentifier, BitString }
    final topLevelSeq = ASN1Sequence();
    topLevelSeq.add(algorithmSeq);
    topLevelSeq.add(publicKeyBitString);

    final dataBase64 = base64Encode(topLevelSeq.encodedBytes);
    return '-----BEGIN PUBLIC KEY-----\n$dataBase64\n-----END PUBLIC KEY-----';
  }

  /// Convert RSA private key to PEM format
  String privateKeyToPem(RSAPrivateKey privateKey) {
    final version = ASN1Integer(BigInt.from(0));
    final modulus = ASN1Integer(privateKey.n!);
    final publicExponent = ASN1Integer(privateKey.exponent!);
    final privateExponent = ASN1Integer(privateKey.d!);
    final p = ASN1Integer(privateKey.p!);
    final q = ASN1Integer(privateKey.q!);
    final dP = privateKey.d! % (privateKey.p! - BigInt.from(1));
    final dQ = privateKey.d! % (privateKey.q! - BigInt.from(1));
    final qInv = privateKey.q!.modInverse(privateKey.p!);

    final seq = ASN1Sequence();
    seq.add(version);
    seq.add(modulus);
    seq.add(publicExponent);
    seq.add(privateExponent);
    seq.add(p);
    seq.add(q);
    seq.add(ASN1Integer(dP));
    seq.add(ASN1Integer(dQ));
    seq.add(ASN1Integer(qInv));

    final topLevelSeq = ASN1Sequence();
    topLevelSeq.add(seq);
    final dataBase64 = base64Encode(topLevelSeq.encodedBytes);

    return '-----BEGIN RSA PRIVATE KEY-----\n$dataBase64\n-----END RSA PRIVATE KEY-----';
  }

  /// Parse PEM string to RSA public key
  RSAPublicKey publicKeyFromPem(String pemString) {
    try {
      // 1. Normalize PEM (remove headers, newlines, etc)
      final normalizedPem = pemString
          .replaceAll(RegExp(r'-----.*?-----'), '') // Remove headers/footers
          .replaceAll(RegExp(r'\s+'), '');         // Remove all whitespace

      final publicKeyDER = base64Decode(normalizedPem);
      
      if (publicKeyDER.isEmpty) {
        throw Exception('Failed to decode PEM: empty DER data');
      }
      
      final asn1Parser = ASN1Parser(publicKeyDER);
      final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
      
      // Standard X.509 SubjectPublicKeyInfo is:
      // SEQUENCE {
      //   SEQUENCE { AlgorithmID... },
      //   BIT STRING { RSAPublicKey... }
      // }

      if (topLevelSeq.elements!.length < 2) {
         throw Exception('Invalid ASN1 structure: topLevelSeq should have at least 2 elements');
      }

      // We expect the second element to be the BitString containing the key
      final publicKeyBitString = topLevelSeq.elements![1] as ASN1BitString;
      
      // ✨ CRITICAL FIX: Handle the "Unused Bits" padding byte.
      // ASN1BitString encoded bytes usually start with a byte indicating 
      // the number of unused bits (usually 0x00). We must skip it to get 
      // the actual Sequence start (0x30).
      Uint8List keyBytes = publicKeyBitString.contentBytes();
      
      // If the first byte is 0 (padding count) and the second is 0x30 (Sequence),
      // we strip the first byte.
      if (keyBytes.isNotEmpty && keyBytes[0] == 0) {
        keyBytes = keyBytes.sublist(1);
      }
      
      final publicKeyAsn = ASN1Parser(keyBytes);
      final publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
      
      final modulus = publicKeySeq.elements![0] as ASN1Integer;
      final exponent = publicKeySeq.elements![1] as ASN1Integer;
      
      return RSAPublicKey(modulus.valueAsBigInteger, exponent.valueAsBigInteger);
    } catch (e) {
      debugPrint("❌ PEM Parse Error: $e");
      throw Exception('Failed to parse public key from PEM: $e');
    }
  }

  /// Parse PEM string to RSA private key
  RSAPrivateKey privateKeyFromPem(String pemString) {
    final lines = pemString.split('\n');
    final base64Lines = lines.where((line) => 
      !line.startsWith('-----') && line.trim().isNotEmpty
    ).join();
    final privateKeyDER = base64Decode(base64Lines);

    final asn1Parser = ASN1Parser(privateKeyDER);
    final seq = asn1Parser.nextObject() as ASN1Sequence;
    final privateKeySeq = seq.elements![0] as ASN1Sequence;
    
    final modulus = privateKeySeq.elements![1] as ASN1Integer;
    final publicExponent = privateKeySeq.elements![2] as ASN1Integer;
    final privateExponent = privateKeySeq.elements![3] as ASN1Integer;
    final p = privateKeySeq.elements![4] as ASN1Integer;
    final q = privateKeySeq.elements![5] as ASN1Integer;
    
    return RSAPrivateKey(
      modulus.valueAsBigInteger,
      privateExponent.valueAsBigInteger,
      p.valueAsBigInteger,
      q.valueAsBigInteger,
    );
  }

  /// Get or generate RSA key pair for a user
  Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>> getOrGenerateKeyPair(String uuid) async {
    try {
      final box = await Hive.openBox(_keyBoxName);
      final publicKeyPem = box.get('${uuid}_public');
      final privateKeyPem = box.get('${uuid}_private');
      
      if (publicKeyPem != null && privateKeyPem != null) {
        try {
          return AsymmetricKeyPair(
            publicKeyFromPem(publicKeyPem),
            privateKeyFromPem(privateKeyPem),
          );
        } catch(e) {
          debugPrint("⚠️ Stored keys were invalid, regenerating: $e");
          // Fall through to regeneration
        }
      }
    } catch (e) {
      print('Error loading keys: $e');
    }
    
    // Generate new key pair if not found or invalid
    debugPrint("🔐 Generating new KeyPair for $uuid");
    final keyPair = generateKeyPair();
    await saveKeyPair(uuid, keyPair);
    return keyPair;
  }

  /// Save RSA key pair for a user
  Future<void> saveKeyPair(String uuid, AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> keyPair) async {
    try {
      final box = await Hive.openBox(_keyBoxName);
      await box.put('${uuid}_public', publicKeyToPem(keyPair.publicKey));
      await box.put('${uuid}_private', privateKeyToPem(keyPair.privateKey));
    } catch (e) {
      print('Error saving keys: $e');
      rethrow;
    }
  }

  // ... rest of your methods (deleteKeyPair, etc)
   /// Delete RSA keys for a user (for logout)
  Future<void> deleteKeyPair(String uuid) async {
    try {
      final box = await Hive.openBox(_keyBoxName);
      await box.delete('${uuid}_public');
      await box.delete('${uuid}_private');
      print('🔐 [RSAKeyService] Deleted RSA keys for user: $uuid');
    } catch (e) {
      print('❌ [RSAKeyService] Error deleting keys: $e');
      rethrow;
    }
  }

  /// Get public key as PEM string for a user
  Future<String?> getPublicKeyPem(String uuid) async {
    try {
      final box = await Hive.openBox(_keyBoxName);
      return box.get('${uuid}_public');
    } catch (e) {
      return null;
    }
  }

  /// Get private key as PEM string for a user
  Future<String?> getPrivateKeyPem(String uuid) async {
    try {
      final box = await Hive.openBox(_keyBoxName);
      return box.get('${uuid}_private');
    } catch (e) {
      return null;
    }
  }
}