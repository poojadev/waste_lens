import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/diagnostic_event.dart';
import '../core/diagnostics_bus.dart';
import '../core/waste_module.dart';

/// Tier A — zero-config rebuild **churn** tracking.
///
/// Hooks Flutter's debug-only [debugOnRebuildDirtyWidget], counting how often
/// each widget type rebuilds inside a sliding [window]. When a type exceeds
/// [threshold] within the window it emits a `RebuildEvent(dead: false)` —
/// "Widget X rebuilt N times in the window". This proves *frequency*, not
/// deadness; pair it with a [DeadRebuildProbe] to prove a rebuild was wasted.
///
/// The previously-installed hook (if any) is preserved and still called, so
/// this composes with other debug tooling.
class RebuildChurnTracker implements WasteModule {
  RebuildChurnTracker({
    required this.threshold,
    required this.window,
  });

  /// Rebuild count within [window] that triggers a churn warning.
  final int threshold;

  /// Sliding evaluation window.
  final Duration window;

  DiagnosticsBus? _bus;
  RebuildDirtyWidgetCallback? _previousHook;
  Timer? _flushTimer;
  bool _installed = false;

  final Map<String, int> _counts = <String, int>{};
  final Map<String, String> _locations = <String, String>{};

  @override
  String get id => 'rebuilds.churn';

  @override
  void start(DiagnosticsBus bus) {
    _bus = bus;
    _previousHook = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = _onRebuild;
    _installed = true;
    _flushTimer = Timer.periodic(window, (_) => _flush());
  }

  void _onRebuild(Element element, bool builtOnce) {
    _previousHook?.call(element, builtOnce);
    final type = element.widget.runtimeType.toString();
    _counts.update(type, (v) => v + 1, ifAbsent: () => 1);
    // Capture a creator chain once per type for a "where" hint. With widget
    // creation tracking on (the default for `flutter run`), this includes the
    // source location.
    _locations.putIfAbsent(type, () => element.debugGetCreatorChain(2));
  }

  /// Forces an immediate window flush, bypassing the timer. For tests.
  @visibleForTesting
  void debugFlush() => _flush();

  void _flush() {
    final bus = _bus;
    if (bus == null || _counts.isEmpty) return;
    final now = DateTime.now();
    for (final entry in _counts.entries) {
      if (entry.value >= threshold) {
        bus.emit(
          RebuildEvent(
            at: now,
            widget: entry.key,
            count: entry.value,
            dead: false,
            location: _locations[entry.key],
            fixHint: 'Rebuilt ${entry.value}x in ${window.inMilliseconds}ms — '
                'consider const, RepaintBoundary, or a narrower select().',
          ),
        );
      }
    }
    _counts.clear();
    _locations.clear();
  }

  @override
  Future<void> stop() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_installed) {
      // Only restore if no one else replaced our hook in the meantime.
      if (identical(debugOnRebuildDirtyWidget, _onRebuild)) {
        debugOnRebuildDirtyWidget = _previousHook;
      }
      _installed = false;
    }
    _counts.clear();
    _locations.clear();
    _bus = null;
  }
}
