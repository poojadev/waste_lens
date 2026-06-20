/// Dio add-on for `waste_lens`: detect and coalesce redundant API calls.
///
/// Add a [RedundantCallInterceptor] to your Dio client. Pass it the running
/// `waste_lens` bus to surface findings in the overlay, and read [CallReport]
/// for a summary:
///
/// ```dart
/// final dio = Dio()
///   ..interceptors.add(
///     RedundantCallInterceptor(
///       bus: WasteLens.current?.bus,
///       coalesce: true, // collapse in-flight idempotent duplicates
///     ),
///   );
/// ```
library;

export 'src/call_report.dart';
export 'src/redundant_call_interceptor.dart';
export 'src/request_signature.dart' show requestSignature;
