import 'package:flutter/scheduler.dart';
import 'package:meta/meta.dart';

import '../core/diagnostic_event.dart';
import '../core/diagnostics_bus.dart';
import '../core/waste_module.dart';

/// Jank Radar — catches dropped frames and attributes each to the phase that
/// overran: **build-bound** (Dart UI work, usually wasted rebuilds) or
/// **raster-bound** (GPU overdraw, large images, shaders).
///
/// It subscribes to [SchedulerBinding.addTimingsCallback], which delivers real
/// [FrameTiming]s after each frame is presented — zero sampling overhead and no
/// effect on the frames it measures. Only frames that exceed [budget] are
/// emitted (so a smooth app produces no traffic); the cumulative frame count
/// rides along on each [JankEvent] so the overlay can show a jank rate.
///
/// Build-bound jank is the user-visible cost of the waste the rest of the
/// package hunts: a frame that rebuilt 50 dead widgets and then missed its
/// deadline shows up here as `build` jank.
class JankTracker implements WasteModule {
  JankTracker({this.budget = const Duration(milliseconds: 16)})
      : assert(budget > Duration.zero, 'budget must be positive');

  /// The per-frame budget. The default (~16 ms) targets 60 fps; lower it to
  /// 8 ms for 120 fps displays.
  final Duration budget;

  DiagnosticsBus? _bus;
  TimingsCallback? _callback;

  @override
  String get id => 'jank';

  @override
  void start(DiagnosticsBus bus) {
    _bus = bus;
    final callback = _onTimings;
    _callback = callback;
    SchedulerBinding.instance.addTimingsCallback(callback);
  }

  void _onTimings(List<FrameTiming> timings) {
    final bus = _bus;
    if (bus == null || timings.isEmpty) return;
    final budgetMs = budget.inMicroseconds / 1000.0;

    for (final timing in timings) {
      final totalMs = _ms(timing.totalSpan);
      if (totalMs <= budgetMs) continue; // smooth frame, no event

      final buildMs = _ms(timing.buildDuration);
      final rasterMs = _ms(timing.rasterDuration);
      bus.emit(
        JankEvent(
          at: DateTime.now(),
          totalMs: totalMs,
          buildMs: buildMs,
          rasterMs: rasterMs,
          budgetMs: budgetMs,
          kind: buildMs >= rasterMs ? JankKind.build : JankKind.raster,
        ),
      );
    }

    // Count every frame (smooth included) so the jank rate stays honest,
    // without flooding the event bus with per-frame traffic.
    bus.aggregates.recordFramesObserved(timings.length);
  }

  /// Feeds timings directly, bypassing the binding. For deterministic testing.
  @visibleForTesting
  void debugReportTimings(List<FrameTiming> timings) => _onTimings(timings);

  static double _ms(Duration d) => d.inMicroseconds / 1000.0;

  @override
  Future<void> stop() async {
    final callback = _callback;
    if (callback != null) {
      SchedulerBinding.instance.removeTimingsCallback(callback);
      _callback = null;
    }
    _bus = null;
  }
}
