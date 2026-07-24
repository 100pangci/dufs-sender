import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/dufs_server.dart';
import '../models/upload_item.dart';
import '../services/content_uri_helper.dart';
import '../services/dufs_client.dart';
import '../services/secure_store.dart';

class UploadController extends ChangeNotifier {
  final DufsClient _client;
  final SecureStore _secureStore;
  final List<UploadItem> _items = [];
  bool _uploading = false;
  int _totalSuccess = 0;
  int _totalFail = 0;
  DufsServer? _selectedServer;
  CancelToken? _cancelToken;

  UploadController(this._client, this._secureStore);

  List<UploadItem> get items => List.unmodifiable(_items);
  bool get uploading => _uploading;
  int get successCount => _totalSuccess;
  int get failCount => _totalFail;
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
    _totalSuccess = 0;
    _totalFail = 0;
    _uploading = false;
    _cancelToken?.cancel();
    _cancelToken = null;
    notifyListeners();
  }

  void cancelUpload() {
    _cancelToken?.cancel('Cancelled by user');
    _cancelToken = null;
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
    _totalSuccess = 0;
    _totalFail = 0;
    _cancelToken = CancelToken();
    notifyListeners();

    final password = await _secureStore.loadPassword(server.id) ?? '';

    for (int i = 0; i < _items.length; i++) {
      if (_cancelToken!.isCancelled) break;

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
        _totalFail++;
        notifyListeners();
        continue;
      }

      final uploadItem = item.copyWith(localPath: tempPath);

      final result = await _client.uploadFile(
        server,
        uploadItem,
        password: password,
        cancelToken: _cancelToken,
        onProgress: (sent, total) {
          if (total > 0) {
            item.progress = sent / total;
            notifyListeners();
          }
        },
      );

      if (_cancelToken!.isCancelled) {
        item.status = UploadStatus.cancelled;
      } else if (result.success) {
        item.status = UploadStatus.success;
        item.progress = 1.0;
        _totalSuccess++;
      } else {
        item.status = UploadStatus.failed;
        item.errorMessage = result.message;
        _totalFail++;
      }
      notifyListeners();

      try { await File(tempPath).delete(); } catch (_) {}
    }

    _uploading = false;
    _cancelToken = null;
    notifyListeners();
  }

  Future<void> retryFailed(DufsServer server) async {
    final failedItems =
        _items.where((i) => i.status == UploadStatus.failed).toList();
    if (failedItems.isEmpty) return;

    _uploading = true;
    _cancelToken = CancelToken();
    notifyListeners();

    final password = await _secureStore.loadPassword(server.id) ?? '';

    for (final item in failedItems) {
      if (_cancelToken!.isCancelled) break;

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
        _totalFail++;
        notifyListeners();
        continue;
      }

      final uploadItem = item.copyWith(localPath: tempPath);

      final result = await _client.uploadFile(
        server,
        uploadItem,
        password: password,
        cancelToken: _cancelToken,
        onProgress: (sent, total) {
          if (total > 0) {
            item.progress = sent / total;
            notifyListeners();
          }
        },
      );

      if (_cancelToken!.isCancelled) {
        item.status = UploadStatus.cancelled;
      } else if (result.success) {
        item.status = UploadStatus.success;
        item.progress = 1.0;
        _totalSuccess++;
      } else {
        item.status = UploadStatus.failed;
        item.errorMessage = result.message;
        _totalFail++;
      }
      notifyListeners();

      try { await File(tempPath).delete(); } catch (_) {}
    }

    _uploading = false;
    _cancelToken = null;
    notifyListeners();
  }
}
