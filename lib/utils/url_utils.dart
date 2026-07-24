String normalizeBaseUrl(String url) {
  url = url.trim();
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'http://$url';
  }
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  return url;
}

String normalizeRemoteDir(String dir) {
  dir = dir.trim();
  if (dir.isEmpty) return '';

  final decoded = Uri.decodeComponent(dir);
  if (decoded.contains('..')) {
    throw ArgumentError('Remote directory must not contain ".."');
  }

  if (!dir.startsWith('/')) {
    dir = '/$dir';
  }
  while (dir.endsWith('/') && dir.length > 1) {
    dir = dir.substring(0, dir.length - 1);
  }

  final segments = dir.split('/');
  final encoded = segments.map((s) {
    if (s.isEmpty) return '';
    return Uri.encodeComponent(s);
  }).join('/');

  return encoded.isEmpty ? '' : encoded;
}

String sanitizeFileName(String name) {
  final basename = name.split(RegExp(r'[/\\]')).last;
  if (basename.isEmpty || basename == '.') {
    throw ArgumentError('Invalid file name: $name');
  }
  return basename;
}

String buildUploadUrl(String baseUrl, String remoteDir, String fileName) {
  final normalizedBase = normalizeBaseUrl(baseUrl);
  final sanitizedName = sanitizeFileName(fileName);
  final encodedName = Uri.encodeComponent(sanitizedName);

  if (remoteDir.isEmpty) {
    return '$normalizedBase/$encodedName';
  }

  final normalizedDir = normalizeRemoteDir(remoteDir);
  return '$normalizedBase$normalizedDir/$encodedName';
}
