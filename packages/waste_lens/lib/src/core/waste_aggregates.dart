import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'diagnostic_event.dart';
import 'ring_buffer.dart';

/// Rolling, overlay-facing summary of everything seen on the [DiagnosticsBus].
///
/// A [ChangeNotifier] so the overlay can rebuild only its own subtree when
/// numbers move, without every widget subscribing to the raw event stream.
class WasteAggregates extends ChangeNotifier {
  WasteAggregates({int sparklineCapacity = 60})
      : rssSeries = RingBuffer<int>(sparklineCapacity);

  /// Rolling RSS readings (bytes) for the memory sparkline.
  final RingBuffer<int> rssSeries;

  int _deadRebuilds = 0;
  int _churnEvents = 0;
  int _redundantCalls = 0;
  int _coalescedCalls = 0;
  int _wastedBytes = 0;
  int _leakCount = 0;
  int _latestRssBytes = 0;
  int _latestMaxRssBytes = 0;
  ImageCacheStat? _imageCache;
  int _jankFrames = 0;
  int _framesObserved = 0;
  int _buildBoundJank = 0;
  int _rasterBoundJank = 0;
  double _worstFrameMs = 0;

  /// Total dead rebuilds proven by a [DeadRebuildProbe] (Tier B).
  int get deadRebuilds => _deadRebuilds;

  /// Number of churn warnings emitted by the Tier A tracker.
  int get churnEvents => _churnEvents;

  /// Total redundant network calls observed.
  int get redundantCalls => _redundantCalls;

  /// Redundant calls that were coalesced instead of re-hitting the network.
  int get coalescedCalls => _coalescedCalls;

  /// Bytes re-fetched needlessly across all redundant calls.
  int get wastedBytes => _wastedBytes;

  /// Distinct leaks reported by the leak module.
  int get leakCount => _leakCount;

  /// Most recent RSS reading, in bytes.
  int get latestRssBytes => _latestRssBytes;

  /// Peak RSS reading, in bytes.
  int get latestMaxRssBytes => _latestMaxRssBytes;

  /// Most recent image-cache reading, when available.
  ImageCacheStat? get imageCache => _imageCache;

  /// Frames that missed their budget (dropped frames).
  int get jankFrames => _jankFrames;

  /// Total frames observed by the jank tracker.
  int get framesObserved => _framesObserved;

  /// Janky frames dominated by the UI/build phase (usually wasted rebuilds).
  int get buildBoundJank => _buildBoundJank;

  /// Janky frames dominated by the GPU raster phase.
  int get rasterBoundJank => _rasterBoundJank;

  /// The slowest frame seen, in milliseconds.
  double get worstFrameMs => _worstFrameMs;

  /// Fraction of observed frames that were janky, in `[0, 1]`.
  double get jankRate =>
      _framesObserved == 0 ? 0 : _jankFrames / _framesObserved;

  /// Records that [frames] more frames were observed (janky or not), so the
  /// jank rate counts every frame while only janky frames ride the event bus.
  void recordFramesObserved(int frames) {
    if (frames <= 0) return;
    _framesObserved += frames;
    _notifySafely();
  }

  /// Folds [event] into the running totals and notifies listeners.
  void ingest(DiagnosticEvent event) {
    switch (event) {
      case MemorySample(:final rssBytes, :final maxRssBytes):
        _latestRssBytes = rssBytes;
        if (maxRssBytes != null && maxRssBytes > _latestMaxRssBytes) {
          _latestMaxRssBytes = maxRssBytes;
        }
        rssSeries.add(rssBytes);
      case ImageCacheStat():
        _imageCache = event;
      case AllocationSample():
        break;
      case LeakReported(:final count):
        _leakCount += count;
      case RedundantCall(:final wastedBytes, :final coalesced):
        _redundantCalls++;
        if (coalesced) _coalescedCalls++;
        _wastedBytes += wastedBytes;
      case RebuildEvent(:final dead):
        if (dead) {
          _deadRebuilds++;
        } else {
          _churnEvents++;
        }
      case JankEvent(:final totalMs, :final kind):
        _jankFrames++;
        if (totalMs > _worstFrameMs) _worstFrameMs = totalMs;
        if (kind == JankKind.build) {
          _buildBoundJank++;
        } else {
          _rasterBoundJank++;
        }
    }
    _notifySafely();
  }

  /// Resets every counter and the sparkline series.
  void reset() {
    _deadRebuilds = 0;
    _churnEvents = 0;
    _redundantCalls = 0;
    _coalescedCalls = 0;
    _wastedBytes = 0;
    _leakCount = 0;
    _latestRssBytes = 0;
    _latestMaxRssBytes = 0;
    _imageCache = null;
    _jankFrames = 0;
    _framesObserved = 0;
    _buildBoundJank = 0;
    _rasterBoundJank = 0;
    _worstFrameMs = 0;
    rssSeries.clear();
    _notifySafely();
  }

  bool _notifyScheduled = false;
  bool _disposed = false;

  /// Notifies listeners now, or right after the current frame if Flutter is
  /// in the middle of building.
  ///
  /// Events can arrive mid-build: `DeadRebuildProbe` reports from
  /// `didUpdateWidget`. Notifying then would make the overlay call
  /// `markNeedsBuild` on a widget outside the current build scope, which
  /// Flutter rejects with "setState() or markNeedsBuild() called during
  /// build". So during a frame we coalesce every notification into ONE
  /// post-frame callback. The counters above already updated synchronously,
  /// so `exportReport()` stays accurate either way.
  void _notifySafely() {
    if (_disposed) return;
    if (!_isMidFrame) {
      notifyListeners();
      return;
    }
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      if (!_disposed) notifyListeners();
    });
  }

  /// True while Flutter is building/laying out/painting a frame, or running
  /// the microtasks flushed in the middle of one.
  static bool get _isMidFrame {
    final SchedulerBinding binding;
    try {
      binding = SchedulerBinding.instance;
    } on FlutterError {
      // No binding (plain Dart tests): there is no frame, notify immediately.
      return false;
    }
    final phase = binding.schedulerPhase;
    return phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
