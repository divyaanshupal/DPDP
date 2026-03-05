import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart' hide Key;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyrotics/features/encrption/rsa_key_service.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'dart:math';

final hybridEncryptionServiceProvider = Provider<HybridEncryptionService>((ref) => 
  HybridEncryptionService(ref.read(rsaKeyServiceProvider)));

class HybridEncryptionService {
  final RSAKeyService _rsaKeyService;

  HybridEncryptionService(this._rsaKeyService);

  /// Generate AES key and IV
  ({Key aesKey, IV iv}) generateAESKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final ivBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return (
      aesKey: Key(Uint8List.fromList(keyBytes)),
      iv: IV(Uint8List.fromList(ivBytes)),
    );
  }

  /// Encrypt data with AES
  Uint8List encryptWithAES(Uint8List data, Key aesKey, IV iv) {
    final encrypter = Encrypter(AES(aesKey, mode: AESMode.cbc));
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    return encrypted.bytes;
  }

  /// Decrypt data with AES
  Uint8List decryptWithAES(Uint8List encryptedData, Key aesKey, IV iv) {
    final encrypter = Encrypter(AES(aesKey, mode: AESMode.cbc));
    final encrypted = Encrypted(encryptedData);
    //return encrypter.decryptBytes(encrypted, iv: iv);
    return Uint8List.fromList(encrypter.decryptBytes(encrypted, iv: iv));
  }

  /// Encrypt AES key with RSA public key
  /// Returns Base64-encoded encrypted key
  String encryptAESKeyWithRSA(Key aesKey, IV iv, RSAPublicKey publicKey) {
    // Combine AES key and IV into a single payload
    final keyData = {
      'key': base64Encode(aesKey.bytes),
      'iv': base64Encode(iv.bytes),
    };
    final keyJson = jsonEncode(keyData);
    final keyBytes = utf8.encode(keyJson);
    
    // RSA encryption (OAEP padding for security)
    final encrypter = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    
    // RSA can only encrypt data up to key size - 42 bytes (for OAEP)
    // For 2048-bit RSA, max is 214 bytes. Our key data should fit.
    final encrypted = encrypter.process(keyBytes);
    
    return base64Encode(encrypted);
  }

  /// Decrypt AES key with RSA private key
  /// Returns the AES key and IV
  ({Key aesKey, IV iv}) decryptAESKeyWithRSA(String encryptedKeyBase64, RSAPrivateKey privateKey) {
    final encryptedBytes = base64Decode(encryptedKeyBase64);
    
    // RSA decryption
    final decrypter = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    
    final decryptedBytes = decrypter.process(encryptedBytes);
    final keyJson = utf8.decode(decryptedBytes);
    final keyData = jsonDecode(keyJson) as Map<String, dynamic>;
    
    return (
      aesKey: Key(base64Decode(keyData['key'] as String)),
      iv: IV(base64Decode(keyData['iv'] as String)),
    );
  }

  /// Encrypt file data (AES) and encrypt the AES key (RSA)
  /// Returns: (encryptedFileData, encryptedAESKeyBase64)
  Future<({Uint8List encryptedData, String encryptedKeyBase64})> encryptFile(
    Uint8List fileData,
    String receiverPublicKeyPem,
  ) async {
    // 1. Generate AES key and IV
    final aes = generateAESKey();
    
    // 2. Encrypt file with AES
    final encryptedData = encryptWithAES(fileData, aes.aesKey, aes.iv);
    
    // 3. Get receiver's public key
    debugPrint("🔍 [SENDER] Public key BEFORE normalization:\n$receiverPublicKeyPem");

    receiverPublicKeyPem = normalizePem(receiverPublicKeyPem);

    debugPrint("🔍 [SENDER] Public key AFTER normalization:\n$receiverPublicKeyPem");
    debugPrint("🔍 [SENDER] Normalized PEM length: ${receiverPublicKeyPem.length}");

    //receiverPublicKeyPem=normalizePem(receiverPublicKeyPem);
    final receiverPublicKey = _rsaKeyService.publicKeyFromPem(receiverPublicKeyPem);

    // final receiverPublicKeyPem = await _rsaKeyService.getPublicKeyPem(receiverUuid);
    // if (receiverPublicKeyPem == null) {
    //   throw Exception('Receiver public key not found. Key exchange required first.');
    // }
    // final receiverPublicKey = _rsaKeyService.publicKeyFromPem(receiverPublicKeyPem);
    
    // 4. Encrypt AES key with receiver's RSA public key
    final encryptedKeyBase64 = encryptAESKeyWithRSA(aes.aesKey, aes.iv, receiverPublicKey);
    
    return (
      encryptedData: encryptedData,
      encryptedKeyBase64: encryptedKeyBase64,
    );
  }

  /// Decrypt file: First decrypt AES key with RSA, then decrypt file with AES
  Future<Uint8List> decryptFile(
    Uint8List encryptedData,
    String encryptedKeyBase64,
    String receiverUuid, // The UUID of the user decrypting (self)
  ) async {
    // 1. Get own private key
    final privateKeyPem = await _rsaKeyService.getPrivateKeyPem(receiverUuid);
    if (privateKeyPem == null) {
      throw Exception('Private key not found for user: $receiverUuid');
    }
    final privateKey = _rsaKeyService.privateKeyFromPem(privateKeyPem);
    
    // 2. Decrypt AES key with RSA private key
    final aes = decryptAESKeyWithRSA(encryptedKeyBase64, privateKey);
    
    // 3. Decrypt file with AES
    final decryptedData = decryptWithAES(encryptedData, aes.aesKey, aes.iv);
    
    return decryptedData;
  }
}

String normalizePem(String pem) {
  return pem
      .replaceAll("\\n", "\n") // convert escaped newline to real newline
      .replaceAll("\r", "")    // remove CR
      .trim();
}
