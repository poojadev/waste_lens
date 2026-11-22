import 'dart:async';

import 'diagnostics_bus.dart';
import 'waste_lens_config.dart';
import 'waste_module.dart';

/// Owns the live state of a running `waste_lens` session: the [DiagnosticsBus],
/// the active [WasteModule]s, and the [WasteLensConfig] that produced them.
///
/// Constructed only in debug/profile by the [WasteLens] widget. In release the
/// widget never builds a runtime at all.
class WasteLensRuntime {
  WasteLensRuntime({
    required this.config,
    required List<WasteModule> modules,
    DiagnosticsBus? bus,
  })  : _modules = modules,
        bus =
            bus ?? DiagnosticsBus(sparklineCapacity: config.sparklineCapacity);

  /// The configuration this runtime was built from.
  final WasteLensConfig config;

  /// The shared event hub.
  final DiagnosticsBus bus;

  final List<WasteModule> _modules;
  bool _started = false;
  bool _disposed = false;

  /// The most recently started runtime, or `null`.
  ///
  /// Backs the static [WasteLens.current]/[WasteLens.exportReport] helpers so
  /// callers without a [BuildContext] can reach the active session. Assumes the
  /// common single-root-`WasteLens` setup.
  static WasteLensRuntime? current;

  /// The modules this runtime manages, in start order.
  List<WasteModule> get modules => List.unmodifiable(_modules);

  /// The first managed module of type [T], or `null` if none is active.
  T? moduleOf<T extends WasteModule>() {
    for (final module in _modules) {
      if (module is T) return module;
    }
    return null;
  }

  /// Starts every module once. Subsequent calls are ignored.
  void start() {
    if (_started || _disposed) return;
    _started = true;
    current = this;
    for (final module in _modules) {
      module.start(bus);
    }
  }

  /// Stops every module (in reverse order) and disposes the bus. Idempotent.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (identical(current, this)) current = null;
    for (final module in _modules.reversed) {
      await module.stop();
    }
    await bus.dispose();
  }

  /// A point-in-time JSON-serialisable summary of all module aggregates,
  /// suitable for a CI artifact or a bug report.
  Map<String, Object?> exportReport() {
    final a = bus.aggregates;
    return <String, Object?>{
      'generatedAt': DateTime.now().toIso8601String(),
      'modules': _modules.map((m) => m.id).toList(growable: false),
      'memory': <String, Object?>{
        'rssBytes': a.latestRssBytes,
        'maxRssBytes': a.latestMaxRssBytes,
        'imageCacheBytes': a.imageCache?.sizeBytes,
        'imageCacheLiveCount': a.imageCache?.liveCount,
      },
      'leaks': <String, Object?>{
        'count': a.leakCount,
      },
      'redundantCalls': <String, Object?>{
        'count': a.redundantCalls,
        'coalesced': a.coalescedCalls,
        'wastedBytes': a.wastedBytes,
      },
      'rebuilds': <String, Object?>{
        'dead': a.deadRebuilds,
        'churnEvents': a.churnEvents,
      },
      'jank': <String, Object?>{
        'jankFrames': a.jankFrames,
        'framesObserved': a.framesObserved,
        'jankRate': a.jankRate,
        'buildBound': a.buildBoundJank,
        'rasterBound': a.rasterBoundJank,
        'worstFrameMs': a.worstFrameMs,
      },
    };
  }
}
