import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class IdentityService {
  final FlutterSecureStorage _secureStorage;
  final _algorithm = Ed25519();

  static const _storageSlot = 'user_private_key';

  SimpleKeyPair? _cachedKeyPair;
  String? _cachedPublicKeyBase64;

  // Accettiamo lo storage nel costruttore: questo ci permette di
  // passare uno storage "finto" (mock) durante i test!
  IdentityService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> init() async {
    final storedPrivateKey = await _secureStorage.read(key: _storageSlot);

    if (storedPrivateKey != null) {
      // Usiamo base64Url.normalize nativo invece del nostro helper helper
      final normalized = base64Url.normalize(storedPrivateKey); //
      final privateKeyBytes = base64Url.decode(normalized);
      _cachedKeyPair = await _algorithm.newKeyPairFromSeed(privateKeyBytes);
    } else {
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

  String get uuid {
    if (_cachedPublicKeyBase64 == null) {
      throw Exception("IdentityService not initialized");
    }
    return _cachedPublicKeyBase64!;
  }

  Future<String> sign(String message) async {
    if (_cachedKeyPair == null)
      throw Exception("IdentityService not initialized");

    final messageBytes = utf8.encode(message);
    final signature = await _algorithm.sign(
      messageBytes,
      keyPair: _cachedKeyPair!,
    );

    return base64Url.encode(signature.bytes).replaceAll('=', '');
  }

  Future<bool> verify({
    required String message,
    required String signatureBase64,
    required String publicKeyBase64,
  }) async {
    try {
      final messageBytes = utf8.encode(message);
      // Anche qui usiamo normalize nativo
      final signatureBytes = base64Url.decode(
        base64Url.normalize(signatureBase64),
      ); //
      final pubKeyBytes = base64Url.decode(
        base64Url.normalize(publicKeyBase64),
      ); //

      final signature = Signature(
        signatureBytes,
        publicKey: SimplePublicKey(pubKeyBytes, type: KeyPairType.ed25519),
      );

      return await _algorithm.verify(messageBytes, signature: signature);
    } catch (_) {
      return false;
    }
  }
}
