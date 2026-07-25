import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/upload_item.dart';
import '../services/content_uri_helper.dart';
import 'package:uuid/uuid.dart';

String getFileNameFromPath(String path) {
  return path.split(RegExp(r'[/\\]')).last;
}

Future<List<UploadItem>> scanDirectory(String dirPath) async {
  if (dirPath.startsWith('content://')) {
    final result = await _scanContentUriDirectory(dirPath);
    if (result.isNotEmpty) return result;
  }

  try {
    final result = await _scanLocalDirectory(dirPath);
    if (result.isNotEmpty) return result;
  } catch (_) {}

  return [];
}

Future<List<UploadItem>> _scanLocalDirectory(String dirPath) async {
  final dir = Directory(dirPath);
  if (!await dir.exists()) return [];

  final items = <UploadItem>[];
  const uuid = Uuid();
  final entities = await dir.list(recursive: true).toList();

  for (final entity in entities) {
    if (entity is! File) continue;
    final relativePath =
        _relativePath(dirPath, entity.path);
    final stat = await entity.stat();
    items.add(UploadItem(
      id: uuid.v4(),
      displayName: getFileNameFromPath(entity.path),
      localPath: entity.path,
      size: stat.size,
      mimeType: 'application/octet-stream',
      relativePath: relativePath,
    ));
  }

  return items;
}

Future<List<UploadItem>> _scanContentUriDirectory(String uri) async {
  final files = await listContentUriDirectory(uri);
  if (files == null || files.isEmpty) return [];

  final items = <UploadItem>[];
  const uuid = Uuid();

  for (final file in files) {
    final name = file['name'] as String? ?? 'unknown';
    final fileUri = file['uri'] as String? ?? '';
    final size = file['size'] as int?;
    final relativePath = file['relativePath'] as String? ?? name;
    if (fileUri.isEmpty) continue;

    items.add(UploadItem(
      id: uuid.v4(),
      displayName: name,
      contentUri: fileUri,
      size: size,
      mimeType: 'application/octet-stream',
      relativePath: relativePath,
    ));
  }

  return items;
}

String _relativePath(String basePath, String fullPath) {
  if (basePath.endsWith('/') || basePath.endsWith('\\')) {
    basePath = basePath.substring(0, basePath.length - 1);
  }
  if (fullPath.length <= basePath.length + 1) {
    return getFileNameFromPath(fullPath);
  }
  return fullPath.substring(basePath.length + 1);
}

Future<void> clearTempFiles() async {
  final dir = await getTemporaryDirectory();
  final tempDir = Directory('${dir.path}/dufs_uploads');
  if (await tempDir.exists()) {
    await tempDir.delete(recursive: true);
  }
}
