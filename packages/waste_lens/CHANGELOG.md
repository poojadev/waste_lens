## 0.2.0

### New — Jank Radar

- `JankTracker`: a new module that watches real frame timings
  (`SchedulerBinding.addTimingsCallback`) and flags dropped frames, classifying
  each as **build-bound** (Dart UI work — usually wasted rebuilds) or
  **raster-bound** (GPU/overdraw). Build-bound jank is the user-visible cost of
  the waste the rest of the package hunts.
- New overlay **JANK** tab: janky-frame count, jank rate, worst frame, and the
  build-vs-raster split, pointing build-bound jank at the REBUILD tab.
- Config: `jank` (on by default) and `jankBudget` (default ~16 ms / 60 fps;
  set 8 ms for 120 fps). New aggregate getters (`jankFrames`, `jankRate`,
  `buildBoundJank`, `rasterBoundJank`, `worstFrameMs`) and a `jank` section in
  `exportReport()`.

### Fixed — overlay

- The expanded panel no longer opens off-screen. From the default bottom-right
  bubble it now anchors on-screen, opening upward/inward and clamped to the
  safe area.
- Dragging the bubble past a screen edge no longer "strands" it (positions are
  clamped on write, not just at paint), and rotation/resize can't leave it
  off-screen.

## 0.1.2

- Fix: `DeadRebuildProbe` with the overlay on threw
  "setState() or markNeedsBuild() called during build" on every dead rebuild.
  The probe reports from `didUpdateWidget` (mid-build), and `WasteAggregates`
  notified the overlay synchronously. Notifications that arrive during a frame
  are now coalesced into a single post-frame callback. Counters still update
  immediately, so `exportReport()` is unaffected.

## 0.1.1

- Export `Sparkline`, the dependency-free mini line-chart used by the overlay,
  so apps can reuse it for their own diagnostics widgets.

## 0.1.0

Initial release.

- `WasteLens` root widget with a verified zero-overhead release no-op (gated by
  `kDebugMode || kProfileMode`).
- `DiagnosticsBus` + rolling `WasteAggregates` event hub.
- **Memory** module: RSS sampler, image-cache probe, and best-effort VM-service
  allocation profiler (`WasteLens.snapshot()`).
- **Leak** module: `LeakWatcher` over the official `leak_tracker`, plus a
  `DisposeGuard` mixin for custom disposables.
- **Dead rebuilds**: Tier A `RebuildChurnTracker` (zero-config churn) and Tier B
  `DeadRebuildProbe` (proves a rebuild produced identical output).
- Draggable diagnostics **overlay** with per-module tabs and sparklines.
- Optimization helpers: `AutoDisposeMixin`, `imageCacheTuner`.
- `WasteLens.exportReport()` JSON aggregate for CI artifacts.
