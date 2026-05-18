import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

class KeyManager {
  static final KeyManager instance = KeyManager._();
  KeyManager._();

  static const _keyName = 'artha_db_encryption_key_v1';

  // AndroidOptions tells it to use hardware-backed encrypted storage
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm:
          StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );

  // Returns existing key or creates a new one
  Future<String> getOrCreateKey() async {
    try {
      final existing = await _storage.read(key: _keyName);
      if (existing != null && existing.isNotEmpty) return existing;
    } catch (_) {}

    // First launch — generate key and store it
    final key = _generate();
    await _storage.write(key: _keyName, value: key);
    return key;
  }

  // Just check if key exists (used to detect first launch)
  Future<bool> hasKey() async {
    try {
      final k = await _storage.read(key: _keyName);
      return k != null && k.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // 32-character random string using secure random number generator
  String _generate() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final rng = Random.secure(); // cryptographically secure
    return List.generate(
        32, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}