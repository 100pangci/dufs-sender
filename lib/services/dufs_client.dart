import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../models/dufs_server.dart';
import '../models/upload_item.dart';
import '../utils/url_utils.dart';

class ConnectionTestResult {
  final bool success;
  final String message;

  ConnectionTestResult(this.success, this.message);
}

class UploadResult {
  final bool success;
  final String message;

  UploadResult(this.success, this.message);
}

class DufsClient {
  final Dio _dio;

  DufsClient()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status != null,
        ));

  Options _authOptions(String username, String password) {
    final headers = <String, dynamic>{};
    if (username.isNotEmpty) {
      final credentials = '$username:$password';
      final encoded = base64Encode(utf8.encode(credentials));
      headers['Authorization'] = 'Basic $encoded';
    }
    return Options(headers: headers);
  }

  Future<ConnectionTestResult> testConnection(
    DufsServer server, {
    String password = '',
  }) async {
    try {
      final url = normalizeBaseUrl(server.baseUrl);
      final response = await _dio.head(
        url,
        options: _authOptions(server.username, password),
      );
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        return ConnectionTestResult(true, 'Connected (HTTP $statusCode)');
      }
      if (statusCode == 401) {
        if (server.username.isEmpty) {
          return ConnectionTestResult(
            false,
            'Server requires authentication. Please set username and password.',
          );
        }
        return ConnectionTestResult(
          false,
          'Authentication failed. Check username and password.',
        );
      }
      if (statusCode == 403) {
        return ConnectionTestResult(
          false,
          'Access denied (HTTP 403). Check server permissions.',
        );
      }
      return ConnectionTestResult(true, 'Server responded (HTTP $statusCode)');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return ConnectionTestResult(
          false,
          'Connection timed out. Check server address and network.',
        );
      }
      if (e.type == DioExceptionType.connectionError) {
        return ConnectionTestResult(
          false,
          'Could not connect to server: ${e.message}',
        );
      }
      return ConnectionTestResult(false, 'Connection failed: ${e.message}');
    } catch (e) {
      return ConnectionTestResult(false, 'Unexpected error: $e');
    }
  }

  Future<UploadResult> uploadFile(
    DufsServer server,
    UploadItem item, {
    String password = '',
    CancelToken? cancelToken,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final fileName = item.displayName;
      final url = buildUploadUrl(
        server.baseUrl,
        server.defaultRemoteDir,
        fileName,
        subPath: item.relativePath,
      );

      if (item.localPath == null) {
        return UploadResult(
            false,
            'No file path available. Content URIs must be resolved before upload.');
      }
      final file = File(item.localPath!);

      if (!await file.exists()) {
        return UploadResult(false, 'File not found: ${file.path}');
      }

      final fileLength = await file.length();

      final opts = _authOptions(server.username, password);
      opts.headers ??= {};
      opts.headers!['Content-Length'] = fileLength.toString();
      opts.headers!['Content-Type'] = 'application/octet-stream';

      await _dio.put(
        url,
        data: file.openRead(),
        options: opts,
        cancelToken: cancelToken,
        onSendProgress: onProgress,
      );

      return UploadResult(true, 'Upload completed successfully');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return UploadResult(false, 'Upload cancelled');
      }
      final statusCode = e.response?.statusCode ?? 0;
      switch (statusCode) {
        case 401:
          return UploadResult(false, 'Authentication failed');
        case 403:
          return UploadResult(false, 'Permission denied');
        case 404:
          return UploadResult(false, 'Path not found on server');
        case 409:
          return UploadResult(false, 'File already exists (conflict)');
        case 413:
          return UploadResult(false, 'File too large for server');
        default:
          if (statusCode >= 500) {
            return UploadResult(false, 'Server error (HTTP $statusCode)');
          }
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            return UploadResult(false, 'Connection timed out during upload');
          }
          return UploadResult(false, 'Upload failed: ${e.message}');
      }
    } catch (e) {
      return UploadResult(false, 'Unexpected error: $e');
    }
  }
}
