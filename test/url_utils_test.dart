import 'package:flutter_test/flutter_test.dart';
import 'package:dufs_sender/utils/url_utils.dart';

void main() {
  group('normalizeBaseUrl', () {
    test('adds http:// prefix if missing', () {
      expect(normalizeBaseUrl('192.168.1.10:5000'), 'http://192.168.1.10:5000');
    });

    test('removes trailing slash', () {
      expect(normalizeBaseUrl('http://192.168.1.10:5000/'), 'http://192.168.1.10:5000');
    });

    test('removes multiple trailing slashes', () {
      expect(normalizeBaseUrl('http://192.168.1.10:5000///'), 'http://192.168.1.10:5000');
    });

    test('preserves https', () {
      expect(normalizeBaseUrl('https://192.168.1.10:5000/'), 'https://192.168.1.10:5000');
    });

    test('trims whitespace', () {
      expect(normalizeBaseUrl('  http://server:5000/  '), 'http://server:5000');
    });
  });

  group('normalizeRemoteDir', () {
    test('adds leading slash', () {
      expect(normalizeRemoteDir('inbox'), '/inbox');
    });

    test('removes trailing slash', () {
      expect(normalizeRemoteDir('/inbox/'), '/inbox');
    });

    test('handles nested path', () {
      expect(normalizeRemoteDir('/upload/inbox/'), '/upload/inbox');
    });

    test('returns empty string for empty input', () {
      expect(normalizeRemoteDir(''), '');
    });

    test('throws on path traversal', () {
      expect(() => normalizeRemoteDir('inbox/..'), throwsArgumentError);
      expect(() => normalizeRemoteDir('../inbox'), throwsArgumentError);
      expect(() => normalizeRemoteDir('/../'), throwsArgumentError);
    });

    test('trims whitespace', () {
      expect(normalizeRemoteDir('  /inbox/  '), '/inbox');
    });
  });

  group('sanitizeFileName', () {
    test('keeps simple filename', () {
      expect(sanitizeFileName('test.zip'), 'test.zip');
    });

    test('strips directory prefix', () {
      expect(sanitizeFileName('dir/test.zip'), 'test.zip');
    });

    test('strips windows directory prefix', () {
      expect(sanitizeFileName('dir\\test.zip'), 'test.zip');
    });

    test('handles nested path', () {
      expect(sanitizeFileName('/a/b/c/file.txt'), 'file.txt');
    });
  });

  group('buildUploadUrl', () {
    test('basic url with dir', () {
      final url = buildUploadUrl('http://192.168.1.10:5000', 'inbox', 'test.zip');
      expect(url, 'http://192.168.1.10:5000/inbox/test.zip');
    });

    test('handles trailing slash on base', () {
      final url = buildUploadUrl('http://192.168.1.10:5000/', 'inbox', 'test.zip');
      expect(url, 'http://192.168.1.10:5000/inbox/test.zip');
    });

    test('handles trailing slash on dir', () {
      final url = buildUploadUrl('http://192.168.1.10:5000', 'inbox/', 'test.zip');
      expect(url, 'http://192.168.1.10:5000/inbox/test.zip');
    });

    test('handles empty dir', () {
      final url = buildUploadUrl('http://192.168.1.10:5000', '', 'test.zip');
      expect(url, 'http://192.168.1.10:5000/test.zip');
    });

    test('URL encodes Chinese filename', () {
      final url = buildUploadUrl('http://192.168.1.10:5000', 'inbox', '测试 文件.zip');
      expect(url, contains('%E6%B5%8B%E8%AF%95'));
      expect(url, contains('%20'));
      expect(url, contains('%E6%96%87%E4%BB%B6'));
    });

    test('URL encodes special characters', () {
      final url = buildUploadUrl('http://server:5000', 'dir', 'my file (1).txt');
      expect(url, contains('%20'));
      expect(url, contains('%281%29'));
    });

    test('strips path from filename', () {
      final url = buildUploadUrl('http://server:5000', 'dir', 'path/to/file.txt');
      expect(url, 'http://server:5000/dir/file.txt');
    });

    test('prevents directory traversal via dir', () {
      expect(
        () => buildUploadUrl('http://server:5000', '../etc', 'file.txt'),
        throwsArgumentError,
      );
    });
  });
}
