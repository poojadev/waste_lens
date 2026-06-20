import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// Produces a canonical, order-independent signature for a request so two
/// semantically identical calls hash to the same string.
///
/// The signature is stable across:
/// - query-parameter order (`?a=1&b=2` == `?b=2&a=1`);
/// - repeated query values in any order (`?id=1&id=2` == `?id=2&id=1`);
///
/// and sensitive to:
/// - method, scheme, host, and path;
/// - request body content (hashed with SHA-1).
///
/// Format: `METHOD:scheme://host/path?sortedQuery#bodyHash`.
String requestSignature(RequestOptions options) {
  final uri = options.uri;

  final entries = uri.queryParametersAll.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final query = entries.map((e) {
    final values = [...e.value]..sort();
    return '${e.key}=${values.join(',')}';
  }).join('&');

  final method = options.method.toUpperCase();
  final origin = '${uri.scheme}://${uri.host}'
      '${uri.hasPort ? ':${uri.port}' : ''}${uri.path}';
  return '$method:$origin?$query#${_bodyHash(options.data)}';
}

/// Hashes the request body. Returns an empty string for body-less requests.
///
/// Tolerates non-JSON payloads (FormData, raw strings, bytes) by falling back
/// to a string representation rather than throwing.
String _bodyHash(Object? data) {
  if (data == null) return '';
  String canonical;
  try {
    canonical = switch (data) {
      String s => s,
      List<int> bytes => 'bytes:${bytes.length}:${base64Encode(bytes)}',
      FormData form => _formDataCanonical(form),
      _ => jsonEncode(data),
    };
  } on Object {
    // Last resort: identity-stable but content-insensitive.
    canonical = data.toString();
  }
  return sha1.convert(utf8.encode(canonical)).toString();
}

String _formDataCanonical(FormData form) {
  final fields = form.fields.map((e) => '${e.key}=${e.value}').toList()..sort();
  final files = form.files.map((e) => '${e.key}:${e.value.filename}').toList()
    ..sort();
  return 'form{${fields.join('&')}|${files.join('&')}}';
}
