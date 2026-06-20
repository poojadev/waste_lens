import 'dart:async';

import 'diagnostic_event.dart';
import 'gate.dart';
import 'waste_aggregates.dart';

/// The single event hub every `waste_lens` module publishes to.
///
/// Modules call [emit]; the overlay and report consumers subscribe to [stream]
/// or read the rolling [aggregates]. When [Gate.enabled] is `false` (release),
/// [emit] short-circuits: nothing is buffered, nothing is notified.
class DiagnosticsBus {
  DiagnosticsBus({int sparklineCapacity = 60})
      : aggregates = WasteAggregates(sparklineCapacity: sparklineCapacity);

  final StreamController<DiagnosticEvent> _controller =
      StreamController<DiagnosticEvent>.broadcast(sync: false);

  /// Rolling counters and series for the overlay/report.
  final WasteAggregates aggregates;

  /// Broadcast stream of every emitted [DiagnosticEvent].
  Stream<DiagnosticEvent> get stream => _controller.stream;

  bool _closed = false;

  /// Publishes [event] to subscribers and folds it into [aggregates].
  ///
  /// A no-op in release builds and after [dispose].
  void emit(DiagnosticEvent event) {
    if (!Gate.enabled || _closed) return;
    aggregates.ingest(event);
    _controller.add(event);
  }

  /// Closes the stream and releases the aggregates. Idempotent.
  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    aggregates.dispose();
    await _controller.close();
  }
}
