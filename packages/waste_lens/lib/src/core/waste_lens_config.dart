import 'package:flutter/foundation.dart';

/// Declarative configuration for which `waste_lens` modules run and how
/// aggressively they sample and flag.
///
/// Every value is `const`-friendly so a config can live in `const` widget
/// constructors. Thresholds have pragmatic defaults tuned for interactive
/// debugging, not CI.
@immutable
class WasteLensConfig {
  const WasteLensConfig({
    this.memory = true,
    this.leaks = true,
    this.rebuilds = true,
    this.jank = true,
    this.overlay = true,
    this.deepMemoryProfiling = true,
    this.sampleInterval = const Duration(seconds: 1),
    this.leakCheckPeriod = const Duration(seconds: 1),
    this.churnThreshold = 30,
    this.churnWindow = const Duration(seconds: 2),
    this.redundancyWindow = const Duration(seconds: 2),
    this.jankBudget = const Duration(milliseconds: 16),
    this.sparklineCapacity = 60,
  })  : assert(churnThreshold > 0, 'churnThreshold must be positive'),
        assert(sparklineCapacity > 0, 'sparklineCapacity must be positive');

  /// A configuration with every module disabled — handy for opting in piecemeal.
  const WasteLensConfig.none()
      : memory = false,
        leaks = false,
        rebuilds = false,
        jank = false,
        overlay = false,
        deepMemoryProfiling = false,
        sampleInterval = const Duration(seconds: 1),
        leakCheckPeriod = const Duration(seconds: 1),
        churnThreshold = 30,
        churnWindow = const Duration(seconds: 2),
        redundancyWindow = const Duration(seconds: 2),
        jankBudget = const Duration(milliseconds: 16),
        sparklineCapacity = 60;

  /// Sample RSS and image-cache stats.
  final bool memory;

  /// Run `leak_tracker`-backed leak detection.
  final bool leaks;

  /// Track widget rebuild churn (Tier A).
  final bool rebuilds;

  /// Run the Jank Radar — flag dropped frames and split build- vs raster-bound.
  final bool jank;

  /// Mount the draggable diagnostics overlay.
  final bool overlay;

  /// Connect to the VM service for allocation profiles. Best-effort; failures
  /// are swallowed. Ignored entirely when [memory] is `false`.
  final bool deepMemoryProfiling;

  /// How often the memory sampler polls.
  final Duration sampleInterval;

  /// How often `leak_tracker` checks for leaks.
  final Duration leakCheckPeriod;

  /// Rebuilds of a single widget within [churnWindow] above this count trigger
  /// a churn warning.
  final int churnThreshold;

  /// Sliding window over which [churnThreshold] is evaluated.
  final Duration churnWindow;

  /// Two identical requests completing within this window mark the second as
  /// redundant.
  final Duration redundancyWindow;

  /// Per-frame budget for the Jank Radar; frames slower than this are flagged.
  /// Default ~16 ms (60 fps); use 8 ms for 120 fps displays.
  final Duration jankBudget;

  /// Number of points retained in the overlay sparkline.
  final int sparklineCapacity;

  /// Returns a copy with the given fields replaced.
  WasteLensConfig copyWith({
    bool? memory,
    bool? leaks,
    bool? rebuilds,
    bool? jank,
    bool? overlay,
    bool? deepMemoryProfiling,
    Duration? sampleInterval,
    Duration? leakCheckPeriod,
    int? churnThreshold,
    Duration? churnWindow,
    Duration? redundancyWindow,
    Duration? jankBudget,
    int? sparklineCapacity,
  }) {
    return WasteLensConfig(
      memory: memory ?? this.memory,
      leaks: leaks ?? this.leaks,
      rebuilds: rebuilds ?? this.rebuilds,
      jank: jank ?? this.jank,
      overlay: overlay ?? this.overlay,
      deepMemoryProfiling: deepMemoryProfiling ?? this.deepMemoryProfiling,
      sampleInterval: sampleInterval ?? this.sampleInterval,
      leakCheckPeriod: leakCheckPeriod ?? this.leakCheckPeriod,
      churnThreshold: churnThreshold ?? this.churnThreshold,
      churnWindow: churnWindow ?? this.churnWindow,
      redundancyWindow: redundancyWindow ?? this.redundancyWindow,
      jankBudget: jankBudget ?? this.jankBudget,
      sparklineCapacity: sparklineCapacity ?? this.sparklineCapacity,
    );
  }
}
