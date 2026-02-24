import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class IdentityManager {
  static const _secureStorage = FlutterSecureStorage();
  static const _storageSlot = 'user_private_key';
  static final _algorithm = Ed25519();

  static SimpleKeyPair? _cachedKeyPair;
  static String? _cachedPublicKeyBase64;

  static Future<void> init() async {
    final storedPrivateKey = await _secureStorage.read(key: _storageSlot);

    if (storedPrivateKey != null) 
    {
      final privateKeyBytes = base64Url.decode(_addPadding(storedPrivateKey));
      _cachedKeyPair = await _algorithm.newKeyPairFromSeed(privateKeyBytes);
    } 
    else 
    {
      _cachedKeyPair = await _algorithm.newKeyPair();
      final privateKeyBytes = await _cachedKeyPair!.extractPrivateKeyBytes();
      
      await _secureStorage.write(
        key: _storageSlot,
        value: base64Url.encode(privateKeyBytes).replaceAll('=', ''),
      );
    }

    final pubKey = await _cachedKeyPair!.extractPublicKey();
    _cachedPublicKeyBase64 = base64Url.encode(pubKey.bytes).replaceAll('=', '');
  }

  static String get uuid {
    if (_cachedPublicKeyBase64 == null) {
      throw Exception("IdentityManager not initialized");
    }
    return _cachedPublicKeyBase64!;
  }

  static Future<String> sign(String message) async {
    if (_cachedKeyPair == null) throw Exception("IdentityManager not initialized");

    final messageBytes = utf8.encode(message);
    final signature = await _algorithm.sign(messageBytes, keyPair: _cachedKeyPair!);
    
    return base64Url.encode(signature.bytes).replaceAll('=', '');
  }

  static Future<bool> verify({
    required String message,
    required String signatureBase64,
    required String publicKeyBase64,
  }) async {
    try {
      final messageBytes = utf8.encode(message);
      final signatureBytes = base64Url.decode(_addPadding(signatureBase64));
      final pubKeyBytes = base64Url.decode(_addPadding(publicKeyBase64));

      final signature = Signature(signatureBytes, publicKey: SimplePublicKey(pubKeyBytes, type: KeyPairType.ed25519));
      
      return await _algorithm.verify(messageBytes, signature: signature);
    } catch (e) {
      return false;
    }
  }

  static String _addPadding(String base64) {
    return base64.padRight(base64.length + (4 - base64.length % 4) % 4, '=');
  }
}