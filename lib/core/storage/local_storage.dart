import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider that requires [SharedPreferences] to be initialized and
/// overridden in [ProviderScope] before use (see main.dart).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('SharedPreferences not initialized'),
);

final localStorageProvider = Provider<LocalStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorage(prefs);
});

/// Thin wrapper over [SharedPreferences].
class LocalStorage {
  const LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  // ── String ─────────────────────────────────────────────────────────────────
  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  // ── Bool ──────────────────────────────────────────────────────────────────
  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  // ── Int ───────────────────────────────────────────────────────────────────
  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  // ── StringList ────────────────────────────────────────────────────────────
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  // ── Remove / Clear ────────────────────────────────────────────────────────
  Future<bool> remove(String key) => _prefs.remove(key);

  Future<bool> clear() => _prefs.clear();

  // ── Existence ─────────────────────────────────────────────────────────────
  bool containsKey(String key) => _prefs.containsKey(key);
}