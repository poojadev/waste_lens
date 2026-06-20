import 'package:meta/meta.dart';

/// Per-endpoint tally of redundant traffic.
@immutable
class EndpointStat {
  const EndpointStat({
    required this.endpoint,
    required this.total,
    required this.redundant,
    required this.wastedBytes,
  });

  /// `METHOD path` for the endpoint.
  final String endpoint;

  /// Total calls observed to this endpoint.
  final int total;

  /// How many were redundant (duplicate within the window or coalesced).
  final int redundant;

  /// Bytes re-fetched needlessly across the redundant calls.
  final int wastedBytes;
}

/// A snapshot of redundant-call statistics from a [RedundantCallInterceptor].
@immutable
class CallReport {
  const CallReport({
    required this.totalCalls,
    required this.redundantCalls,
    required this.coalescedCalls,
    required this.wastedBytes,
    required this.endpoints,
  });

  /// A report with no traffic recorded.
  const CallReport.empty()
      : totalCalls = 0,
        redundantCalls = 0,
        coalescedCalls = 0,
        wastedBytes = 0,
        endpoints = const [];

  /// Total requests seen by the interceptor.
  final int totalCalls;

  /// Requests judged redundant (duplicate-in-window or coalesced).
  final int redundantCalls;

  /// Redundant requests collapsed into an in-flight call (no extra network).
  final int coalescedCalls;

  /// Estimated bytes re-fetched needlessly.
  final int wastedBytes;

  /// Per-endpoint breakdown, worst offenders first.
  final List<EndpointStat> endpoints;

  /// Fraction of calls that were redundant, in `[0, 1]`.
  double get wastedFraction =>
      totalCalls == 0 ? 0 : redundantCalls / totalCalls;

  /// Redundant share as a whole-number percentage.
  int get wastedPercent => (wastedFraction * 100).round();

  /// The [limit] worst endpoints by wasted bytes.
  List<EndpointStat> topOffenders({int limit = 5}) {
    final sorted = [...endpoints]
      ..sort((a, b) => b.wastedBytes.compareTo(a.wastedBytes));
    return sorted.take(limit).toList(growable: false);
  }

  /// A JSON-serialisable view for reports/CI artifacts.
  Map<String, Object?> toJson() => {
        'totalCalls': totalCalls,
        'redundantCalls': redundantCalls,
        'coalescedCalls': coalescedCalls,
        'wastedBytes': wastedBytes,
        'wastedPercent': wastedPercent,
        'endpoints': [
          for (final e in topOffenders(limit: endpoints.length))
            {
              'endpoint': e.endpoint,
              'total': e.total,
              'redundant': e.redundant,
              'wastedBytes': e.wastedBytes,
            },
        ],
      };
}
