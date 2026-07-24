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
  if (dir.contains('..')) {
    throw ArgumentError('Remote directory must not contain ".."');
  }
  if (!dir.startsWith('/')) {
    dir = '/$dir';
  }
  while (dir.endsWith('/') && dir.length > 1) {
    dir = dir.substring(0, dir.length - 1);
  }
  return dir;
}

String sanitizeFileName(String name) {
  final basename = name.split(RegExp(r'[/\\]')).last;
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
