import 'package:flutter/foundation.dart';

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
    }
    notifyListeners();
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
    rssSeries.clear();
    notifyListeners();
  }
}
