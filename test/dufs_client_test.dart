import 'package:flutter_test/flutter_test.dart';
import 'package:dufs_sender/services/dufs_client.dart';
import 'package:dufs_sender/models/dufs_server.dart';
import 'package:dufs_sender/models/upload_item.dart';

void main() {
  group('DufsClient', () {
    late DufsClient client;

    setUp(() {
      client = DufsClient();
    });

    test('testConnection fails on invalid URL', () async {
      final server = DufsServer(
        id: 'test',
        name: 'Test',
        baseUrl: 'http://192.168.1.999:5000',
      );
      final result = await client.testConnection(server);
      expect(result.success, false);
      expect(result.message, isNotEmpty);
    });

    test('uploadFile fails on non-existent file', () async {
      final server = DufsServer(
        id: 'test',
        name: 'Test',
        baseUrl: 'http://192.168.1.10:5000',
      );
      final item = UploadItem(
        id: 'test',
        displayName: 'nonexistent.txt',
        localPath: '/nonexistent/path.txt',
      );
      final result = await client.uploadFile(server, item);
      expect(result.success, false);
    });
  });
}
