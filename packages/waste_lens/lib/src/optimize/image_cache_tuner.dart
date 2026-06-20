import 'package:flutter/painting.dart';

/// Right-sizes Flutter's [ImageCache] in one call.
///
/// The default cache holds up to 1000 images / 100 MB, which is generous on
/// image-heavy screens. Tune it down to cap decoded-image memory.
///
/// Remember the other half of the fix: this caps *cached* bytes, but each
/// decoded image still costs `width × height × 4` bytes in memory. For
/// thumbnails, also pass `cacheWidth`/`cacheHeight` to `Image.network`/`asset`
/// so images decode at display size rather than full resolution — that is what
/// the `image_needs_cache_dimensions` lint nudges you toward.
///
/// Returns the tuned [ImageCache] for convenience.
ImageCache imageCacheTuner({int? maxBytes, int? maxEntries}) {
  final cache = PaintingBinding.instance.imageCache;
  if (maxBytes != null) {
    assert(maxBytes >= 0, 'maxBytes must be non-negative');
    cache.maximumSizeBytes = maxBytes;
  }
  if (maxEntries != null) {
    assert(maxEntries >= 0, 'maxEntries must be non-negative');
    cache.maximumSize = maxEntries;
  }
  return cache;
}
