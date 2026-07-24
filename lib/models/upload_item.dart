enum UploadStatus { pending, uploading, success, failed, cancelled }

class UploadItem {
  final String id;
  String displayName;
  String? localPath;
  String? contentUri;
  int? size;
  String? mimeType;
  UploadStatus status;
  double progress;
  String? errorMessage;

  UploadItem({
    required this.id,
    required this.displayName,
    this.localPath,
    this.contentUri,
    this.size,
    this.mimeType,
    this.status = UploadStatus.pending,
    this.progress = 0,
    this.errorMessage,
  });

  String get sizeFormatted {
    if (size == null) return 'Unknown size';
    final bytes = size!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  UploadItem copyWith({
    UploadStatus? status,
    double? progress,
    String? errorMessage,
    String? localPath,
    String? contentUri,
  }) =>
      UploadItem(
        id: id,
        displayName: displayName,
        localPath: localPath ?? this.localPath,
        contentUri: contentUri ?? this.contentUri,
        size: size,
        mimeType: mimeType,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
