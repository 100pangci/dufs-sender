import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/dufs_server.dart';
import '../models/upload_item.dart';
import '../services/content_uri_helper.dart';
import '../services/dufs_client.dart';
import '../services/secure_store.dart';

class UploadController extends ChangeNotifier {
  final DufsClient _client;
  final SecureStore _secureStore;
  List<UploadItem> _items = [];
  bool _uploading = false;
  int _successCount = 0;
  int _failCount = 0;
  DufsServer? _selectedServer;
  Completer<void>? _uploadCompleter;

  UploadController(this._client, this._secureStore);

  List<UploadItem> get items => List.unmodifiable(_items);
  bool get uploading => _uploading;
  int get successCount => _successCount;
  int get failCount => _failCount;
  DufsServer? get selectedServer => _selectedServer;

  set selectedServer(DufsServer? server) {
    _selectedServer = server;
    notifyListeners();
  }

  void addItems(List<UploadItem> newItems) {
    _items.addAll(newItems);
    notifyListeners();
  }

  void addItem(UploadItem item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    _successCount = 0;
    _failCount = 0;
    _uploading = false;
    notifyListeners();
  }

  void cancelUpload() {
    _uploadCompleter?.complete();
    _uploadCompleter = null;
    _uploading = false;
    notifyListeners();
  }

  Future<String> _resolveFilePath(UploadItem item) async {
    if (item.localPath != null && File(item.localPath!).existsSync()) {
      return item.localPath!;
    }
    if (item.contentUri != null) {
      final tempPath = await copyContentUriToTemp(item.contentUri!);
      if (tempPath != null && File(tempPath).existsSync()) {
        return tempPath;
      }
    }
    throw Exception('Cannot resolve file path');
  }

  Future<void> startUpload(DufsServer server) async {
    if (_items.isEmpty || _uploading) return;

    _selectedServer = server;
    _uploading = true;
    _successCount = 0;
    _failCount = 0;
    notifyListeners();

    final password = await _secureStore.loadPassword(server.id) ?? '';
    final completer = Completer<void>();
    _uploadCompleter = completer;

    for (int i = 0; i < _items.length; i++) {
      if (completer.isCompleted) break;

      final item = _items[i];
      item.status = UploadStatus.uploading;
      item.progress = 0;
      item.errorMessage = null;
      notifyListeners();

      String? tempPath;
      try {
        tempPath = await _resolveFilePath(item);
      } catch (e) {
        item.status = UploadStatus.failed;
        item.errorMessage = 'Cannot read file: $e';
        _failCount++;
        notifyListeners();
        if (tempPath != null) {
          try { await File(tempPath).delete(); } catch (_) {}
        }
        continue;
      }

      final uploadItem = item.copyWith(localPath: tempPath);

      final result = await _client.uploadFile(
        server,
        uploadItem,
        password: password,
        onProgress: (sent, total) {
          if (total > 0) {
            item.progress = sent / total;
            notifyListeners();
          }
        },
      );

      if (completer.isCompleted) {
        item.status = UploadStatus.cancelled;
      } else if (result.success) {
        item.status = UploadStatus.success;
        item.progress = 1.0;
        _successCount++;
      } else {
        item.status = UploadStatus.failed;
        item.errorMessage = result.message;
        _failCount++;
      }
      notifyListeners();

      if (tempPath != null) {
        try { await File(tempPath).delete(); } catch (_) {}
      }
    }

    _uploading = false;
    notifyListeners();
  }

  Future<void> retryFailed(DufsServer server) async {
    final failedItems =
        _items.where((i) => i.status == UploadStatus.failed).toList();
    if (failedItems.isEmpty) return;

    _uploading = true;
    _successCount = 0;
    _failCount = 0;
    notifyListeners();

    final password = await _secureStore.loadPassword(server.id) ?? '';

    for (final item in failedItems) {
      item.status = UploadStatus.uploading;
      item.progress = 0;
      item.errorMessage = null;
      notifyListeners();

      String? tempPath;
      try {
        tempPath = await _resolveFilePath(item);
      } catch (e) {
        item.status = UploadStatus.failed;
        item.errorMessage = 'Cannot read file: $e';
        _failCount++;
        notifyListeners();
        if (tempPath != null) {
          try { await File(tempPath).delete(); } catch (_) {}
        }
        continue;
      }

      final uploadItem = item.copyWith(localPath: tempPath);

      final result = await _client.uploadFile(
        server,
        uploadItem,
        password: password,
        onProgress: (sent, total) {
          if (total > 0) {
            item.progress = sent / total;
            notifyListeners();
          }
        },
      );

      if (result.success) {
        item.status = UploadStatus.success;
        item.progress = 1.0;
        _successCount++;
      } else {
        item.status = UploadStatus.failed;
        item.errorMessage = result.message;
        _failCount++;
      }
      notifyListeners();

      if (tempPath != null) {
        try { await File(tempPath).delete(); } catch (_) {}
      }
    }

    _uploading = false;
    notifyListeners();
  }
}
