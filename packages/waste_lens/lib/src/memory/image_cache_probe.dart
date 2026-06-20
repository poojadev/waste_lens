import 'package:flutter/painting.dart';

import '../core/diagnostic_event.dart';
import '../core/diagnostics_bus.dart';

/// Reads Flutter's [ImageCache] and emits an [ImageCacheStat].
///
/// Surfaces decoded-image byte pressure — a common, easily-missed source of
/// memory growth on image-heavy screens. Debug/profile only (gated upstream).
class ImageCacheProbe {
  const ImageCacheProbe();

  /// Snapshots the painting binding's image cache and emits a reading.
  ///
  /// No-op if the binding isn't initialised yet; never throws.
  void sample(DiagnosticsBus bus) {
    final binding = PaintingBinding.instance;
    final cache = binding.imageCache;
    bus.emit(
      ImageCacheStat(
        at: DateTime.now(),
        sizeBytes: cache.currentSizeBytes,
        maxSizeBytes: cache.maximumSizeBytes,
        liveCount: cache.liveImageCount,
        pendingCount: cache.pendingImageCount,
      ),
    );
  }
}
