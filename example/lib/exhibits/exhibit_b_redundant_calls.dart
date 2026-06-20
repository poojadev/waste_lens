import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:waste_lens/waste_lens.dart';
import 'package:waste_lens_dio/waste_lens_dio.dart';

import '../ledger_theme.dart';
import '../widgets/dossier.dart';

/// Exhibit B — a screen that re-fetches the same endpoint five times in a tight
/// loop. The docket counts the redundant calls and wasted bytes; the coalescing
/// toggle collapses the duplicates into a single network call.
class ExhibitBRedundantCalls extends StatefulWidget {
  const ExhibitBRedundantCalls({super.key});

  @override
  State<ExhibitBRedundantCalls> createState() => _ExhibitBRedundantCallsState();
}

class _ExhibitBRedundantCallsState extends State<ExhibitBRedundantCalls> {
  final _CountingAdapter _adapter = _CountingAdapter();
  bool _coalesce = false;
  late Dio _dio = _buildDio();
  RedundantCallInterceptor get _interceptor =>
      _dio.interceptors.whereType<RedundantCallInterceptor>().first;

  Dio _buildDio() {
    return Dio(BaseOptions(baseUrl: 'https://api.evidence.test'))
      ..httpClientAdapter = _adapter
      ..interceptors.add(
        RedundantCallInterceptor(
          bus: WasteLens.maybeOf(context)?.bus,
          coalesce: _coalesce,
          redundancyWindow: const Duration(seconds: 5),
        ),
      );
  }

  Future<void> _commitOffence() async {
    await Future.wait([
      for (var i = 0; i < 5; i++) _dio.get<dynamic>('/dossier/42'),
    ]);
    if (mounted) setState(() {});
  }

  void _toggleCoalescing() {
    setState(() {
      _coalesce = !_coalesce;
      _adapter.networkCalls = 0;
      _dio = _buildDio();
    });
  }

  @override
  Widget build(BuildContext context) {
    final aggregates = WasteLens.maybeOf(context)?.bus.aggregates;
    final report = _interceptor.report;

    return DossierScaffold(
      exhibit: 'EXHIBIT B',
      charge: 'REDUNDANT CALLS',
      title: 'Five fetches for one piece of evidence',
      blurb:
          'The same GET fires five times. Observed, four are redundant. With '
          'coalescing on, the in-flight duplicates collapse into one network '
          'call — the rest await the same response.',
      children: [
        OffenceZone(
          label: 'THE WIRE',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Stat('Network calls made', '${_adapter.networkCalls}'),
              _Stat('Redundant (this interceptor)', '${report.redundantCalls}'),
              _Stat('Wasted', _formatBytes(report.wastedBytes)),
              _Stat('Coalescing', _coalesce ? 'ON' : 'OFF',
                  tone: _coalesce ? Ledger.cleared : Ledger.charge),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (aggregates != null)
          Docket(
            listenable: aggregates,
            selector: () => aggregates.redundantCalls,
            label: 'Redundant calls charged',
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: LedgerButton(
                label: 'Commit the offence',
                onPressed: _commitOffence,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LedgerButton(
                label: _coalesce ? 'Disable coalescing' : 'Enable coalescing',
                filled: false,
                tone: Ledger.cleared,
                onPressed: _toggleCoalescing,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.tone = Ledger.paper});

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Ledger.body)),
          Text(value, style: Ledger.data.copyWith(color: tone)),
        ],
      ),
    );
  }
}

/// Returns a canned dossier payload after a short delay so concurrent
/// duplicates have a window to coalesce.
class _CountingAdapter implements HttpClientAdapter {
  int networkCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    networkCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return ResponseBody.fromString(
      '{"id":42,"verdict":"pending","notes":"a reasonably sized dossier body"}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
