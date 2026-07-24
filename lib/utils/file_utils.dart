import 'dart:io';

import 'package:path_provider/path_provider.dart';

String getFileNameFromPath(String path) {
  return path.split(RegExp(r'[/\\]')).last;
}

Future<File> copyLocalFileToTemp(String path) async {
  final dir = await getTemporaryDirectory();
  final tempDir = Directory('${dir.path}/dufs_uploads');
  if (!await tempDir.exists()) {
    await tempDir.create(recursive: true);
  }
  final fileName = getFileNameFromPath(path);
  final source = File(path);
  final dest = File('${tempDir.path}/$fileName');
  if (await source.exists()) {
    return source.copy(dest.path);
  }
  throw Exception('Source file not found: $path');
}

Future<void> clearTempFiles() async {
  final dir = await getTemporaryDirectory();
  final tempDir = Directory('${dir.path}/dufs_uploads');
  if (await tempDir.exists()) {
    await tempDir.delete(recursive: true);
  }
}
