import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores the Supabase Auth session in the platform secure store.
///
/// Android uses the Keystore-backed implementation provided by
/// flutter_secure_storage; iOS uses Keychain. No access/refresh token is
/// intentionally written to SharedPreferences or another plaintext store.
class SecureSupabaseLocalStorage extends LocalStorage {
  SecureSupabaseLocalStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async {
    return _storage.read(key: supabasePersistSessionKey);
  }

  @override
  Future<bool> hasAccessToken() async {
    return _storage.containsKey(key: supabasePersistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _storage.write(
      key: supabasePersistSessionKey,
      value: persistSessionString,
    );
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: supabasePersistSessionKey);
  }
}
