import 'dart:io';

import 'package:path_provider/path_provider.dart';

String getFileNameFromPath(String path) {
  return path.split(RegExp(r'[/\\]')).last;
}

Future<void> clearTempFiles() async {
  final dir = await getTemporaryDirectory();
  final tempDir = Directory('${dir.path}/dufs_uploads');
  if (await tempDir.exists()) {
    await tempDir.delete(recursive: true);
  }
}
