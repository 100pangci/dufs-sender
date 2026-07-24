import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/dufs_server.dart';
import '../services/server_store.dart';

class ServerController extends ChangeNotifier {
  final ServerStore _store;
  List<DufsServer> _servers = [];
  bool _loaded = false;

  ServerController(this._store);

  List<DufsServer> get servers => _servers;
  bool get loaded => _loaded;

  DufsServer? get defaultServer {
    try {
      return _servers.firstWhere((s) => s.isDefault);
    } catch (_) {
      if (_servers.isNotEmpty) return _servers.first;
      return null;
    }
  }

  Future<void> load() async {
    _servers = await _store.loadServers();
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(DufsServer server, {String? password}) async {
    await _store.addServer(server, password: password);
    _servers.add(server);
    notifyListeners();
  }

  Future<void> update(DufsServer server, {String? password}) async {
    await _store.updateServer(server, password: password);
    final index = _servers.indexWhere((s) => s.id == server.id);
    if (index != -1) {
      _servers[index] = server;
    }
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _store.deleteServer(id);
    _servers.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> setDefault(String id) async {
    for (final server in _servers) {
      server.isDefault = server.id == id;
    }
    await _store.saveServers(_servers);
    notifyListeners();
  }

  Future<String?> loadPassword(String serverId) async {
    return await _store.loadPassword(serverId);
  }

  DufsServer getById(String id) {
    return _servers.firstWhere((s) => s.id == id);
  }
}
