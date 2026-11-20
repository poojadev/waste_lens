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
