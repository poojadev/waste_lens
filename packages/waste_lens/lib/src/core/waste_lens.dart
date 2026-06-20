import 'package:flutter/widgets.dart';

import '../leaks/leak_watcher.dart';
import '../memory/memory_module.dart';
import '../rebuilds/rebuild_churn_tracker.dart';
import 'diagnostic_event.dart' show AllocationSample;
import '../overlay/waste_overlay.dart';
import 'gate.dart';
import 'waste_lens_config.dart';
import 'waste_lens_runtime.dart';
import 'waste_module.dart';

/// Builds the active module list for [config].
///
/// Every module is individually gated by its config flag, so an unconfigured
/// app starts none. In release this function is never reached — [WasteLens]
/// returns its child before constructing a runtime.
List<WasteModule> buildModules(WasteLensConfig config) {
  return <WasteModule>[
    if (config.memory)
      MemoryModule(
        interval: config.sampleInterval,
        deepProfiling: config.deepMemoryProfiling,
      ),
    if (config.leaks) LeakWatcher(checkPeriod: config.leakCheckPeriod),
    if (config.rebuilds)
      RebuildChurnTracker(
        threshold: config.churnThreshold,
        window: config.churnWindow,
      ),
    // The dio interceptor is added by the consumer to their Dio client.
  ];
}

/// Wrap your app once with this widget to enable `waste_lens`.
///
/// ```dart
/// void main() => runApp(
///       WasteLens(
///         config: WasteLensConfig(memory: true, leaks: true, rebuilds: true),
///         child: const MyApp(),
///       ),
///     );
/// ```
///
/// In release builds ([Gate.enabled] is `false`) this returns [child]
/// untouched: no runtime, no timers, no listeners, an identical widget tree.
class WasteLens extends StatefulWidget {
  const WasteLens({
    super.key,
    required this.child,
    this.config = const WasteLensConfig(),
  });

  /// The application subtree to observe.
  final Widget child;

  /// Which modules run and how they sample. See [WasteLensConfig].
  final WasteLensConfig config;

  /// The nearest enclosing runtime, or `null` outside a [WasteLens] (or in
  /// release). Never throws — callers degrade gracefully.
  static WasteLensRuntime? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<WasteLensScope>()
        ?.runtime;
  }

  /// The active runtime without a [BuildContext], or `null` in release / before
  /// any [WasteLens] has started. Assumes a single root [WasteLens].
  static WasteLensRuntime? get current => WasteLensRuntime.current;

  /// A JSON-serialisable aggregate report from every module, or an empty map in
  /// release. Suitable for CI artifacts and bug reports.
  static Map<String, Object?> exportReport() =>
      current?.exportReport() ?? const <String, Object?>{};

  /// The top [limit] allocating classes from the VM service, or an empty list
  /// when deep profiling is off / unavailable (always empty in release).
  static Future<List<AllocationSample>> snapshot({int limit = 15}) async {
    final memory = current?.moduleOf<MemoryModule>();
    return memory?.topAllocators(limit: limit) ?? const [];
  }

  @override
  State<WasteLens> createState() => _WasteLensState();
}

class _WasteLensState extends State<WasteLens> {
  WasteLensRuntime? _runtime;

  @override
  void initState() {
    super.initState();
    if (Gate.enabled) {
      final runtime = WasteLensRuntime(
        config: widget.config,
        modules: buildModules(widget.config),
      )..start();
      _runtime = runtime;
    }
  }

  @override
  void dispose() {
    // Fire-and-forget teardown; the runtime makes this idempotent.
    _runtime?.dispose();
    _runtime = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runtime = _runtime;
    if (runtime == null) {
      // Release (or modules off): zero-overhead pass-through.
      return widget.child;
    }
    return WasteLensScope(
      runtime: runtime,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            widget.child,
            if (runtime.config.overlay) WasteOverlay(runtime: runtime),
          ],
        ),
      ),
    );
  }
}

/// Exposes the running [WasteLensRuntime] to descendants (e.g. `DeadRebuildProbe`).
class WasteLensScope extends InheritedWidget {
  const WasteLensScope({
    super.key,
    required this.runtime,
    required super.child,
  });

  /// The active runtime for this subtree.
  final WasteLensRuntime runtime;

  @override
  bool updateShouldNotify(WasteLensScope oldWidget) =>
      runtime != oldWidget.runtime;
}
