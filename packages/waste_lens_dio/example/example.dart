import 'package:dio/dio.dart';
import 'package:waste_lens/waste_lens.dart';
import 'package:waste_lens_dio/waste_lens_dio.dart';

/// Add the interceptor to your Dio client. Pass the running `waste_lens` bus to
/// surface findings in the overlay, and read [RedundantCallInterceptor.report]
/// for a summary.
Future<void> main() async {
  final interceptor = RedundantCallInterceptor(
    bus: WasteLens.current?.bus,
    coalesce: true, // collapse in-flight idempotent duplicates into one call
    redundancyWindow: const Duration(seconds: 2),
  );

  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
    ..interceptors.add(interceptor);

  // Fire the same request a few times; duplicates are coalesced/flagged.
  await Future.wait([
    for (var i = 0; i < 5; i++) dio.get<dynamic>('/users'),
  ]);

  final report = interceptor.report;
  // ignore: avoid_print
  print('${report.redundantCalls} redundant (${report.wastedPercent}% wasted)');
}
