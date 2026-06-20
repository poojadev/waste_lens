import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_lens_dio/waste_lens_dio.dart';

RequestOptions _req(
  String path, {
  String method = 'GET',
  Map<String, dynamic>? query,
  Object? data,
}) {
  return RequestOptions(
    path: path,
    method: method,
    queryParameters: query,
    data: data,
  );
}

void main() {
  group('requestSignature', () {
    test('is independent of query-parameter order', () {
      final a = requestSignature(
        _req('https://api.test/users', query: {'b': '2', 'a': '1'}),
      );
      final b = requestSignature(
        _req('https://api.test/users', query: {'a': '1', 'b': '2'}),
      );
      expect(a, b);
    });

    test('is independent of repeated-value order', () {
      final a = requestSignature(
        _req('https://api.test/items', query: {
          'id': ['1', '2'],
        }),
      );
      final b = requestSignature(
        _req('https://api.test/items', query: {
          'id': ['2', '1'],
        }),
      );
      expect(a, b);
    });

    test('distinguishes method, path, and host', () {
      final get = requestSignature(_req('https://api.test/a'));
      final post = requestSignature(_req('https://api.test/a', method: 'POST'));
      final otherPath = requestSignature(_req('https://api.test/b'));
      final otherHost = requestSignature(_req('https://other.test/a'));
      expect({get, post, otherPath, otherHost}, hasLength(4));
    });

    test('is sensitive to request body content', () {
      final one = requestSignature(
        _req('https://api.test/a', method: 'POST', data: {'q': 'cats'}),
      );
      final two = requestSignature(
        _req('https://api.test/a', method: 'POST', data: {'q': 'dogs'}),
      );
      final dup = requestSignature(
        _req('https://api.test/a', method: 'POST', data: {'q': 'cats'}),
      );
      expect(one, isNot(two));
      expect(one, dup);
    });

    test('body-less requests share a stable empty-body suffix', () {
      final sig = requestSignature(_req('https://api.test/a'));
      expect(sig.endsWith('#'), isTrue);
    });
  });
}
