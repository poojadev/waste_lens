import 'dart:io' show ProcessInfo;

import 'package:flutter/foundation.dart';

import '../core/diagnostic_event.dart';
import '../core/diagnostics_bus.dart';

/// Polls resident set size (RSS) on a fixed interval and emits [MemorySample].
///
/// RSS via `dart:io`'s [ProcessInfo] is the one memory signal that survives
/// into release, but this whole module is still gated by [Gate] upstream. Some
/// platforms report `0` for RSS; readings are passed through verbatim and any
/// failure is swallowed (logged once) so sampling never crashes the host app.
class MemorySampler {
  MemorySampler();

  bool _warned = false;

  /// Reads the current RSS (and peak, when non-zero) and emits a sample.
  ///
  /// Safe to call from a periodic timer; never throws.
  void sample(DiagnosticsBus bus) {
    try {
      final rss = ProcessInfo.currentRss;
      final maxRss = ProcessInfo.maxRss;
      bus.emit(
        MemorySample(
          at: DateTime.now(),
          rssBytes: rss,
          maxRssBytes: maxRss > 0 ? maxRss : null,
        ),
      );
    } on Object catch (error) {
      if (!_warned) {
        _warned = true;
        debugPrint('waste_lens: RSS sampling unavailable ($error). '
            'Memory graph disabled for this session.');
      }
    }
  }
}
