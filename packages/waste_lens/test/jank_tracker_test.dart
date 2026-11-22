import 'dart:ui' show FrameTiming;

import 'package:flutter_test/flutter_test.dart';
import 'package:waste_lens/waste_lens.dart';

/// Builds a synthetic frame with the given build/raster microsecond costs.
/// `totalSpan` is `rasterFinish - vsyncStart`, i.e. build + raster here.
FrameTiming _frame({required int buildUs, required int rasterUs}) {
  return FrameTiming(
    vsyncStart: 0,
    buildStart: 0,
    buildFinish: buildUs,
    rasterStart: buildUs,
    rasterFinish: buildUs + rasterUs,
    rasterFinishWallTime: buildUs + rasterUs,
  );
}

void main() {
  // SchedulerBinding is needed because start() registers a timings callback.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('flags only over-budget frames and classifies build vs raster', () {
    final bus = DiagnosticsBus();
    addTearDown(bus.dispose);
    final tracker = JankTracker(budget: const Duration(milliseconds: 16));
    tracker.start(bus);
    addTearDown(tracker.stop);

    tracker.debugReportTimings([
      _frame(buildUs: 20000, rasterUs: 4000), // 24 ms, build-bound jank
      _frame(buildUs: 3000, rasterUs: 30000), // 33 ms, raster-bound jank
      _frame(buildUs: 2000, rasterUs: 3000), // 5 ms, smooth -> ignored
    ]);

    final a = bus.aggregates;
    expect(a.framesObserved, 3);
    expect(a.jankFrames, 2);
    expect(a.buildBoundJank, 1);
    expect(a.rasterBoundJank, 1);
    expect(a.worstFrameMs, closeTo(33.0, 0.01));
    expect(a.jankRate, closeTo(2 / 3, 0.001));
  });

  test('a smooth stream produces no jank events', () {
    final bus = DiagnosticsBus();
    addTearDown(bus.dispose);
    final tracker = JankTracker(budget: const Duration(milliseconds: 16));
    tracker.start(bus);
    addTearDown(tracker.stop);

    tracker.debugReportTimings([
      for (var i = 0; i < 10; i++) _frame(buildUs: 4000, rasterUs: 5000),
    ]);

    final a = bus.aggregates;
    expect(a.framesObserved, 10);
    expect(a.jankFrames, 0);
    expect(a.jankRate, 0);
  });

  test('a JankEvent on the bus folds into the jank counters', () {
    final bus = DiagnosticsBus();
    addTearDown(bus.dispose);
    bus
      ..aggregates.recordFramesObserved(100)
      ..emit(JankEvent(
        at: DateTime.now(),
        totalMs: 30,
        buildMs: 25,
        rasterMs: 5,
        budgetMs: 16,
        kind: JankKind.build,
      ));
    expect(bus.aggregates.buildBoundJank, 1);
    expect(bus.aggregates.worstFrameMs, 30);
    expect(bus.aggregates.framesObserved, 100);
    expect(bus.aggregates.jankRate, closeTo(0.01, 0.0001));
  });
}
