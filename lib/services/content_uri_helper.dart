import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _channel = MethodChannel('dufs_sender/file_helper');

Future<Map<String, dynamic>?> getFileInfo(String uri) async {
  try {
    final result = await _channel.invokeMethod<Map>('getFileInfo', {
      'uri': uri,
    });
    if (result == null) return null;
    return result.cast<String, dynamic>();
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}

Future<String?> copyContentUriToTemp(String uri) async {
  try {
    final dir = await getTemporaryDirectory();
    final tempDir = Directory('${dir.path}/dufs_uploads');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }

    final result = await _channel.invokeMethod<String>('copyToTemp', {
      'uri': uri,
      'destDir': tempDir.path,
    });
    return result;
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}

Future<int?> getContentUriSize(String uri) async {
  try {
    final result = await _channel.invokeMethod<int>('getFileSize', {
      'uri': uri,
    });
    return result;
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}

Future<List<Map<String, dynamic>>?> listContentUriDirectory(String uri) async {
  try {
    final result = await _channel.invokeMethod<List>('listDirectory', {
      'uri': uri,
    });
    if (result == null) return null;
    return result.cast<Map<String, dynamic>>();
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}
