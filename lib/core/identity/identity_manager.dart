import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smezza/core/hlc/hlc_manager.dart';

class IdentityService {
  final FlutterSecureStorage _secureStorage;
  final _algorithm = Ed25519();

  static const _storageSlot = 'user_private_key';
  static const _kBackupDone = 'backup_confirmed';

  SimpleKeyPair? _cachedKeyPair;
  String? _cachedPublicKeyBase64;
  Hlc? _lastHlc;

  // Accettiamo lo storage nel costruttore: questo ci permette di
  // passare uno storage "finto" (mock) durante i test!
  IdentityService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> init() async {
    final storedPrivateKey = await _secureStorage.read(key: _storageSlot);

    if (storedPrivateKey != null) {
      final normalized = base64Url.normalize(storedPrivateKey);
      final privateKeyBytes = base64Url.decode(normalized);

      if (privateKeyBytes.length != 32) {
        // storage corrotto o residuo: non riusare mai, rigenera pulito
        await _secureStorage.delete(key: _storageSlot);
        await _generateFreshKeyPair();
        return;
      }

      _cachedKeyPair = await _algorithm.newKeyPairFromSeed(privateKeyBytes);
      _rawSeedCache = normalized;
    } else {
      await _generateFreshKeyPair();
      return; // _generateFreshKeyPair già setta pubkey, evitiamo doppio lavoro
    }

    final pubKey = await _cachedKeyPair!.extractPublicKey();
    _cachedPublicKeyBase64 = base64Url.encode(pubKey.bytes).replaceAll('=', '');
  }

  // NUOVO: unico punto che genera chiave nuova, sempre con secure random
  // (newKeyPair() della lib cryptography usa già CSPRNG internamente, ok così)
  Future<void> _generateFreshKeyPair() async {
    _cachedKeyPair = await _algorithm.newKeyPair();
    final privateKeyBytes = await _cachedKeyPair!.extractPrivateKeyBytes();
    final seed = base64Url.encode(privateKeyBytes).replaceAll('=', '');

    await _secureStorage.write(key: _storageSlot, value: seed);
    _rawSeedCache = seed;

    final pubKey = await _cachedKeyPair!.extractPublicKey();
    _cachedPublicKeyBase64 = base64Url.encode(pubKey.bytes).replaceAll('=', '');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBackupDone, false); // chiave nuova = backup non fatto
  }

  // NUOVO: da chiamare SEMPRE al register, ignora qualunque chiave residua
  // in storage (caso device condiviso / utente precedente non ha fatto logout pulito)
  Future<void> forceNewIdentity() async {
    await _secureStorage.delete(key: _storageSlot);
    _cachedKeyPair = null;
    _cachedPublicKeyBase64 = null;
    _rawSeedCache = null;
    await _generateFreshKeyPair();
  }

  // NUOVO: wipe totale, da chiamare al logout
  Future<void> wipeIdentity() async {
    await _secureStorage.delete(key: _storageSlot);
    _cachedKeyPair = null;
    _cachedPublicKeyBase64 = null;
    _rawSeedCache = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBackupDone);
  }

  String get uuid {
    if (_cachedPublicKeyBase64 == null) {
      throw Exception("IdentityService not initialized");
    }
    return _cachedPublicKeyBase64!;
  }

  Hlc nextHlc() {
    final hlc = Hlc.now(uuid, lastKnown: _lastHlc);
    _lastHlc = hlc;
    return hlc;
  }

  Future<String> sign(String message) async {
    if (_cachedKeyPair == null) {
      throw Exception("IdentityService not initialized");
    }

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

  String exportKey() {
    if (_rawSeedCache == null) throw Exception("Not initialized");
    return _rawSeedCache!;
  }

  Future<String> exportKeyAsync() async {
    final stored = await _secureStorage.read(key: _storageSlot);
    if (stored == null) throw Exception("Chiave non trovata in storage");
    return stored;
  }

  // serve cache del seed originale, aggiungi campo:
  String? _rawSeedCache;

  // in init(), quando leggi storedPrivateKey, salva:
  // _rawSeedCache = normalized;
  // e nel branch else, dopo write, salva:
  // _rawSeedCache = base64Url.encode(privateKeyBytes).replaceAll('=', '');

  Future<void> importKey(String pastedSeed) async {
    final clean = _normalize(pastedSeed);
    final bytes = base64Url.decode(clean);
    if (bytes.length != 32) {
      throw Exception('Chiave non valida (lunghezza errata)');
    }
    await _secureStorage.write(key: _storageSlot, value: clean);
    await init(); // ricarica tutto da storage
  }

  static String _normalize(String s) {
    final trimmed = s.trim().replaceAll(RegExp(r'\s+'), '');
    return base64Url.normalize(trimmed.replaceAll('=', ''));
  }

  Future<bool> isBackupConfirmed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBackupDone) ?? false;
  }

  Future<void> confirmBackup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBackupDone, true);
  }

  Future<void> resetBackupFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBackupDone, false);
  }
}
