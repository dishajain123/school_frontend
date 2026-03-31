import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

final secureStorageProvider = Provider<SecureStorage>(
  (_) => SecureStorage(),
);

/// Thin wrapper over [FlutterSecureStorage].
/// Only tokens and credentials go here.
class SecureStorage {
  SecureStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  // ── Access Token ──────────────────────────────────────────────────────────
  Future<String?> readToken() => _storage.read(key: StorageKeys.accessToken);

  Future<void> writeToken(String token) =>
      _storage.write(key: StorageKeys.accessToken, value: token);

  Future<void> deleteToken() =>
      _storage.delete(key: StorageKeys.accessToken);

  // ── Refresh Token ─────────────────────────────────────────────────────────
  Future<String?> readRefreshToken() =>
      _storage.read(key: StorageKeys.refreshToken);

  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: StorageKeys.refreshToken, value: token);

  Future<void> deleteRefreshToken() =>
      _storage.delete(key: StorageKeys.refreshToken);

  // ── Clear All ─────────────────────────────────────────────────────────────
  Future<void> clearAll() => _storage.deleteAll();
}