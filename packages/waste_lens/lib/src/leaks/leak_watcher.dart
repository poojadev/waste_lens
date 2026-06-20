import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../core/diagnostic_event.dart';
import '../core/diagnostics_bus.dart';
import '../core/waste_module.dart';

/// Leak detection module — a thin, bus-aware wrapper over the official
/// `leak_tracker` engine (the same one `flutter_test` uses).
///
/// On [start] it begins leak tracking and subscribes to Flutter's
/// [FlutterMemoryAllocations] so framework disposables are tracked
/// automatically. When `leak_tracker` reports leaks it collects the detailed
/// reports, de-duplicates by object identity, and emits one [LeakReported] per
/// newly-seen leak (with a retaining path when available).
///
/// `leak_tracker` is itself assert-driven, so it only does work in debug; this
/// module is additionally gated by the runtime, which never starts it in
/// release.
class LeakWatcher implements WasteModule {
  LeakWatcher({this.checkPeriod = const Duration(seconds: 1)});

  /// How often `leak_tracker` scans for leaks.
  final Duration checkPeriod;

  DiagnosticsBus? _bus;
  final Set<int> _reportedCodes = <int>{};
  bool _collecting = false;
  bool _listening = false;

  @override
  String get id => 'leaks';

  @override
  void start(DiagnosticsBus bus) {
    _bus = bus;
    LeakTracking.start(
      config: LeakTrackingConfig(
        stdoutLeaks: false,
        checkPeriod: checkPeriod,
        onLeaks: _onLeaks,
        maxRequestsForRetainingPath: 10,
      ),
      resetIfAlreadyStarted: true,
    );
    FlutterMemoryAllocations.instance.addListener(_onFlutterEvent);
    _listening = true;
  }

  void _onFlutterEvent(ObjectEvent event) {
    LeakTracking.dispatchObjectEvent(event.toMap());
  }

  // `onLeaks` hands us only totals; pull the detailed reports out-of-band.
  void _onLeaks(LeakSummary summary) {
    if (summary.isEmpty || _collecting) return;
    unawaited(_collectAndEmit());
  }

  /// Collects and emits any pending leaks immediately, bypassing the periodic
  /// timer. Exposed for deterministic testing.
  @visibleForTesting
  Future<void> collectNow() => _collectAndEmit();

  Future<void> _collectAndEmit() async {
    _collecting = true;
    try {
      final leaks = await LeakTracking.collectLeaks();
      final bus = _bus;
      if (bus == null) return;
      for (final entry in leaks.byType.entries) {
        final kind = _kindLabel(entry.key);
        for (final report in entry.value) {
          if (!_reportedCodes.add(report.code)) continue; // already emitted
          bus.emit(
            LeakReported(
              at: DateTime.now(),
              type: report.type,
              kind: kind,
              count: 1,
              retainingPath: report.retainingPath,
            ),
          );
        }
      }
    } on Object catch (error) {
      debugPrint('waste_lens: leak collection failed ($error).');
    } finally {
      _collecting = false;
    }
  }

  static String _kindLabel(LeakType type) => switch (type) {
        LeakType.notDisposed => 'not-disposed',
        LeakType.notGCed => 'not-gced',
        LeakType.gcedLate => 'gced-late',
      };

  @override
  Future<void> stop() async {
    if (_listening) {
      FlutterMemoryAllocations.instance.removeListener(_onFlutterEvent);
      _listening = false;
    }
    if (LeakTracking.isStarted) {
      LeakTracking.stop();
    }
    _reportedCodes.clear();
    _bus = null;
  }
}
