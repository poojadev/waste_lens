import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:waste_lens/waste_lens.dart';

import 'call_report.dart';
import 'request_signature.dart';

/// A Dio [Interceptor] that identifies wasted API traffic and auto-eliminates
/// only the provably-safe case.
///
/// It is a safety net plus a diagnostic, not an aggressive cache:
/// - **In-flight coalescing** (opt-in, idempotent methods only): when an
///   identical request is already on the wire, the duplicate awaits the same
///   response instead of opening a second connection.
/// - **Redundancy-window detection** (always on, observational): a second
///   identical request completing within [redundancyWindow] of the first is
///   flagged as redundant. With [serveCache] on, idempotent duplicates are
///   served from the short-lived cached response.
///
/// Findings are tallied into a [CallReport] and, when a [DiagnosticsBus] is
/// supplied, emitted as [RedundantCall] events for the `waste_lens` overlay.
class RedundantCallInterceptor extends Interceptor {
  RedundantCallInterceptor({
    this.bus,
    this.redundancyWindow = const Duration(seconds: 2),
    this.coalesce = false,
    this.serveCache = false,
    Set<String>? idempotentMethods,
  }) : idempotentMethods =
            idempotentMethods ?? const {'GET', 'HEAD', 'OPTIONS'};

  /// Optional bus to mirror findings onto the overlay/report.
  final DiagnosticsBus? bus;

  /// Two identical requests completing within this window flag the second.
  final Duration redundancyWindow;

  /// Coalesce in-flight idempotent duplicates into a single network call.
  final bool coalesce;

  /// Serve idempotent within-window duplicates from the cached response rather
  /// than re-fetching. Off by default — it trades freshness for fewer calls.
  final bool serveCache;

  /// Methods safe to coalesce / serve from cache.
  final Set<String> idempotentMethods;

  static const String _sigKey = 'waste_lens.signature';

  final Map<String, Completer<Response<dynamic>>> _inFlight = {};
  final Map<String, _RecentEntry> _recent = {};
  final Map<String, _EndpointAccum> _endpoints = {};

  int _totalCalls = 0;
  int _redundantCalls = 0;
  int _coalescedCalls = 0;
  int _wastedBytes = 0;

  /// A point-in-time snapshot of redundant-call statistics.
  CallReport get report => CallReport(
        totalCalls: _totalCalls,
        redundantCalls: _redundantCalls,
        coalescedCalls: _coalescedCalls,
        wastedBytes: _wastedBytes,
        endpoints: [
          for (final e in _endpoints.values)
            EndpointStat(
              endpoint: e.endpoint,
              total: e.total,
              redundant: e.redundant,
              wastedBytes: e.wastedBytes,
            ),
        ],
      );

  /// Clears all accumulated statistics and caches.
  void resetReport() {
    _inFlight.clear();
    _recent.clear();
    _endpoints.clear();
    _totalCalls = 0;
    _redundantCalls = 0;
    _coalescedCalls = 0;
    _wastedBytes = 0;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Never touch streamed responses — they can't be replayed or cached.
    if (options.responseType == ResponseType.stream) {
      handler.next(options);
      return;
    }

    final signature = requestSignature(options);
    options.extra[_sigKey] = signature;
    _totalCalls++;
    _endpointFor(options).total++;

    final idempotent = idempotentMethods.contains(options.method.toUpperCase());

    // (A) Coalesce an identical idempotent request already on the wire.
    if (coalesce && idempotent) {
      final pending = _inFlight[signature];
      if (pending != null) {
        pending.future.then(
          (response) {
            _flagRedundant(
              options: options,
              signature: signature,
              bytes: _responseBytes(response),
              sinceLast: Duration.zero,
              coalesced: true,
            );
            handler.resolve(_responseFor(response, options));
          },
          onError: (Object error, StackTrace stack) {
            handler.reject(_asDioException(error, options));
          },
        );
        return;
      }
      _inFlight[signature] = Completer<Response<dynamic>>();
    }

    // (B) Observe a recently-completed duplicate inside the window.
    final recent = _recent[signature];
    if (recent != null) {
      final sinceLast = DateTime.now().difference(recent.completedAt);
      if (sinceLast <= redundancyWindow) {
        final bytes = recent.bytes;
        if (serveCache && idempotent && recent.response != null) {
          _flagRedundant(
            options: options,
            signature: signature,
            bytes: bytes,
            sinceLast: sinceLast,
            coalesced: true, // served without a network call
          );
          _inFlight.remove(signature); // we won't hit the network
          handler.resolve(_responseFor(recent.response!, options));
          return;
        }
        _flagRedundant(
          options: options,
          signature: signature,
          bytes: bytes,
          sinceLast: sinceLast,
          coalesced: false,
        );
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final signature = response.requestOptions.extra[_sigKey] as String?;
    if (signature != null) {
      _recent[signature] = _RecentEntry(
        completedAt: DateTime.now(),
        bytes: _responseBytes(response),
        response: serveCache ? response : null,
      );
      _inFlight.remove(signature)?.complete(response);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final signature = err.requestOptions.extra[_sigKey] as String?;
    if (signature != null) {
      _inFlight.remove(signature)?.completeError(err);
    }
    handler.next(err);
  }

  void _flagRedundant({
    required RequestOptions options,
    required String signature,
    required int bytes,
    required Duration sinceLast,
    required bool coalesced,
  }) {
    _redundantCalls++;
    _wastedBytes += bytes;
    final accum = _endpointFor(options);
    accum.redundant++;
    accum.wastedBytes += bytes;
    if (coalesced) _coalescedCalls++;
    bus?.emit(
      RedundantCall(
        at: DateTime.now(),
        endpoint: accum.endpoint,
        signature: signature,
        sinceLast: sinceLast,
        wastedBytes: bytes,
        coalesced: coalesced,
      ),
    );
  }

  _EndpointAccum _endpointFor(RequestOptions options) {
    final key = '${options.method.toUpperCase()} ${options.uri.path}';
    return _endpoints.putIfAbsent(key, () => _EndpointAccum(key));
  }

  static Response<dynamic> _responseFor(
    Response<dynamic> source,
    RequestOptions options,
  ) {
    return Response<dynamic>(
      requestOptions: options,
      data: source.data,
      statusCode: source.statusCode,
      statusMessage: source.statusMessage,
      headers: source.headers,
      isRedirect: source.isRedirect,
      redirects: source.redirects,
      extra: source.extra,
    );
  }

  static DioException _asDioException(Object error, RequestOptions options) {
    if (error is DioException) return error;
    return DioException(requestOptions: options, error: error);
  }

  static int _responseBytes(Response<dynamic> response) {
    final header = response.headers.value(Headers.contentLengthHeader);
    final declared = header == null ? null : int.tryParse(header);
    if (declared != null && declared >= 0) return declared;

    final data = response.data;
    return switch (data) {
      null => 0,
      String s => utf8.encode(s).length,
      List<int> bytes => bytes.length,
      _ => _safeEncodedLength(data),
    };
  }

  static int _safeEncodedLength(Object data) {
    try {
      return utf8.encode(jsonEncode(data)).length;
    } on Object {
      return data.toString().length;
    }
  }
}

class _RecentEntry {
  _RecentEntry({
    required this.completedAt,
    required this.bytes,
    required this.response,
  });

  final DateTime completedAt;
  final int bytes;
  final Response<dynamic>? response;
}

class _EndpointAccum {
  _EndpointAccum(this.endpoint);

  final String endpoint;
  int total = 0;
  int redundant = 0;
  int wastedBytes = 0;
}
