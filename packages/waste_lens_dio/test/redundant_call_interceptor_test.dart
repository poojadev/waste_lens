import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_lens/waste_lens.dart';
import 'package:waste_lens_dio/waste_lens_dio.dart';

/// Minimal adapter that counts network round-trips and returns a canned body
/// after an optional delay (so concurrent coalescing has a window to attach).
class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter({this.delay = Duration.zero});

  final Duration delay;
  final String body = '{"ok":true}';
  int networkCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    networkCalls++;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('coalescing collapses concurrent idempotent duplicates to one call',
      () async {
    final adapter = _CountingAdapter(delay: const Duration(milliseconds: 80));
    final interceptor = RedundantCallInterceptor(coalesce: true);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(interceptor);

    final responses = await Future.wait([
      for (var i = 0; i < 5; i++) dio.get<dynamic>('/users'),
    ]);

    expect(responses, hasLength(5));
    expect(adapter.networkCalls, 1, reason: 'four duplicates coalesced');
    final report = interceptor.report;
    expect(report.totalCalls, 5);
    expect(report.redundantCalls, 4);
    expect(report.coalescedCalls, 4);
    expect(report.wastedPercent, 80);
  });

  test('observational window flags sequential duplicates without suppressing',
      () async {
    final adapter = _CountingAdapter();
    final bus = DiagnosticsBus();
    addTearDown(bus.dispose);
    final interceptor = RedundantCallInterceptor(
      bus: bus,
      redundancyWindow: const Duration(seconds: 5),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(interceptor);

    for (var i = 0; i < 5; i++) {
      await dio.get<dynamic>('/feed');
    }

    expect(adapter.networkCalls, 5,
        reason: 'observational mode never suppresses');
    final report = interceptor.report;
    expect(report.redundantCalls, 4);
    expect(report.wastedPercent, 80);
    expect(report.topOffenders().first.endpoint, 'GET /feed');
    // Findings mirrored onto the bus for the overlay.
    expect(bus.aggregates.redundantCalls, 4);
  });

  test('non-idempotent methods are never coalesced', () async {
    final adapter = _CountingAdapter(delay: const Duration(milliseconds: 60));
    final interceptor = RedundantCallInterceptor(coalesce: true);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(interceptor);

    await Future.wait([
      for (var i = 0; i < 3; i++)
        dio.post<dynamic>('/orders', data: {'item': 'a'}),
    ]);

    expect(adapter.networkCalls, 3, reason: 'POST is not idempotent');
    expect(interceptor.report.coalescedCalls, 0);
  });

  test('streamed responses are left untouched', () async {
    final adapter = _CountingAdapter();
    final interceptor = RedundantCallInterceptor(coalesce: true);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(interceptor);

    for (var i = 0; i < 2; i++) {
      await dio.get<dynamic>(
        '/stream',
        options: Options(responseType: ResponseType.stream),
      );
    }

    expect(adapter.networkCalls, 2);
    expect(interceptor.report.redundantCalls, 0);
  });
}
