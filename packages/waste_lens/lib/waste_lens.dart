/// Catch wasted work in Flutter apps — dead rebuilds, redundant API calls,
/// memory leaks, and memory pressure — surfaced live in-app and exportable as
/// a report.
///
/// Wrap your app once with [WasteLens]. Everything is gated behind
/// [Gate.enabled]: in release builds the package is a zero-overhead no-op.
library;

export 'src/core/diagnostic_event.dart';
export 'src/core/diagnostics_bus.dart';
export 'src/core/gate.dart';
export 'src/core/ring_buffer.dart';
export 'src/core/waste_aggregates.dart';
export 'src/core/waste_lens.dart' show WasteLens, WasteLensScope;
export 'src/core/waste_lens_config.dart';
export 'src/core/waste_lens_runtime.dart';
export 'src/core/waste_module.dart';
export 'src/leaks/dispose_guard.dart';
export 'src/leaks/leak_watcher.dart' show LeakWatcher;
export 'src/memory/memory_module.dart' show MemoryModule;
export 'src/optimize/auto_dispose_mixin.dart';
export 'src/optimize/image_cache_tuner.dart';
export 'src/rebuilds/dead_rebuild_probe.dart';
export 'src/rebuilds/rebuild_churn_tracker.dart' show RebuildChurnTracker;
