import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/dufs_server.dart';
import 'secure_store.dart';

class ServerStore {
  static const _key = 'dufs_servers';

  final SecureStore _secureStore;

  ServerStore(this._secureStore);

  Future<List<DufsServer>> loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((e) => DufsServer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Failed to parse server config: $e');
      return [];
    }
  }

  Future<void> saveServers(List<DufsServer> servers) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(servers.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }

  Future<void> addServer(DufsServer server, {String? password}) async {
    final servers = await loadServers();
    if (password != null && password.isNotEmpty) {
      await _secureStore.savePassword(server.id, password);
      server.hasPassword = true;
    }
    servers.add(server);
    await saveServers(servers);
  }

  Future<void> updateServer(DufsServer server, {String? password}) async {
    final servers = await loadServers();
    final index = servers.indexWhere((s) => s.id == server.id);
    if (index == -1) return;
    if (password != null) {
      if (password.isNotEmpty) {
        await _secureStore.savePassword(server.id, password);
        server.hasPassword = true;
      } else {
        await _secureStore.deletePassword(server.id);
        server.hasPassword = false;
      }
    }
    server.updatedAt = DateTime.now();
    servers[index] = server;
    await saveServers(servers);
  }

  Future<void> deleteServer(String id) async {
    final servers = await loadServers();
    servers.removeWhere((s) => s.id == id);
    await _secureStore.deletePassword(id);
    await saveServers(servers);
  }

  Future<String?> loadPassword(String serverId) async {
    return await _secureStore.loadPassword(serverId);
  }
}
