import 'dart:async';
import 'dart:io';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../models/upload_item.dart';
import 'content_uri_helper.dart';
import 'package:uuid/uuid.dart';

class ShareIntentService {
  StreamSubscription? _sub;

  void listen(void Function(List<UploadItem> items) onSharedFiles) {
    _sub?.cancel();
    _sub =
        ReceiveSharingIntent.instance.getMediaStream().listen((sharedFiles) {
      if (sharedFiles.isNotEmpty) {
        _processSharedFiles(sharedFiles, onSharedFiles);
      }
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((sharedFiles) {
      if (sharedFiles.isNotEmpty) {
        _processSharedFiles(sharedFiles, onSharedFiles);
      }
    });
  }

  Future<void> _processSharedFiles(
    List<SharedMediaFile> sharedFiles,
    void Function(List<UploadItem> items) onSharedFiles,
  ) async {
    final items = <UploadItem>[];
    final uuid = const Uuid();

    for (final sharedFile in sharedFiles) {
      final uri = sharedFile.path;
      if (uri.isEmpty) continue;

      String displayName = uri.split('/').last.isNotEmpty
          ? uri.split('/').last
          : 'unknown';

      int? fileSize;

      if (uri.startsWith('content://')) {
        final info = await getFileInfo(uri);
        if (info != null) {
          displayName = info['name'] as String? ?? displayName;
          fileSize = info['size'] as int?;
        }
      } else {
        final file = File(uri);
        if (await file.exists()) {
          fileSize = await file.length();
        }
      }

      items.add(UploadItem(
        id: uuid.v4(),
        displayName: displayName,
        contentUri: uri.startsWith('content://') ? uri : null,
        localPath: uri.startsWith('content://') ? null : uri,
        size: fileSize,
        mimeType: _getMimeType(displayName),
      ));
    }

    if (items.isNotEmpty) {
      onSharedFiles(items);
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'pdf':
        return 'application/pdf';
      case 'zip':
        return 'application/zip';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
