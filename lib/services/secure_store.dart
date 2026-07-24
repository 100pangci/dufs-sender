import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _prefix = 'dufs_password_';
  final FlutterSecureStorage _storage;

  SecureStore() : _storage = const FlutterSecureStorage();

  Future<void> savePassword(String serverId, String password) async {
    await _storage.write(key: '$_prefix$serverId', value: password);
  }

  Future<String?> loadPassword(String serverId) async {
    return await _storage.read(key: '$_prefix$serverId');
  }

  Future<void> deletePassword(String serverId) async {
    await _storage.delete(key: '$_prefix$serverId');
  }

  Future<void> clearAll() async {
    final all = await _storage.readAll();
    for (final key in all.keys) {
      if (key.startsWith(_prefix)) {
        await _storage.delete(key: key);
      }
    }
  }

  Future<bool> hasPassword(String serverId) async {
    final password = await loadPassword(serverId);
    return password != null && password.isNotEmpty;
  }
}
