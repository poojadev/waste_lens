import 'package:meta/meta.dart';

/// Base type for every signal `waste_lens` publishes on the [DiagnosticsBus].
///
/// Sealed so consumers can exhaustively `switch` over the known event kinds and
/// the compiler flags any newly added event they forgot to handle.
@immutable
sealed class DiagnosticEvent {
  const DiagnosticEvent({required this.at});

  /// When the event was produced.
  final DateTime at;
}

/// A periodic snapshot of resident set size (RSS) from `ProcessInfo`.
///
/// Available in every build mode — RSS is the only memory signal that survives
/// into release.
final class MemorySample extends DiagnosticEvent {
  const MemorySample({
    required super.at,
    required this.rssBytes,
    this.maxRssBytes,
  });

  /// Current resident set size, in bytes.
  final int rssBytes;

  /// Peak resident set size, in bytes, when the platform reports it.
  final int? maxRssBytes;
}

/// A reading of Flutter's [ImageCache] state (debug/profile only).
final class ImageCacheStat extends DiagnosticEvent {
  const ImageCacheStat({
    required super.at,
    required this.sizeBytes,
    required this.maxSizeBytes,
    required this.liveCount,
    required this.pendingCount,
  });

  /// Bytes currently held by decoded images in the cache.
  final int sizeBytes;

  /// Configured byte ceiling for the cache.
  final int maxSizeBytes;

  /// Number of live (decoded, in-use) images.
  final int liveCount;

  /// Number of images still decoding.
  final int pendingCount;

  /// Fraction of the byte budget currently used, in `[0, 1]`.
  double get pressure =>
      maxSizeBytes <= 0 ? 0 : (sizeBytes / maxSizeBytes).clamp(0.0, 1.0);
}

/// A class-level allocation reading from the VM service (debug/profile only).
final class AllocationSample extends DiagnosticEvent {
  const AllocationSample({
    required super.at,
    required this.className,
    required this.instances,
    required this.bytes,
  });

  /// The Dart class whose instances were counted.
  final String className;

  /// Number of live instances.
  final int instances;

  /// Bytes retained by those instances.
  final int bytes;
}

/// A leak surfaced by `leak_tracker` and mapped onto the bus.
final class LeakReported extends DiagnosticEvent {
  const LeakReported({
    required super.at,
    required this.type,
    required this.kind,
    required this.count,
    this.retainingPath,
  });

  /// The leaked object's runtime type.
  final String type;

  /// The leak category, e.g. `not-disposed` or `not-gced`.
  final String kind;

  /// How many objects of [type] leaked in this report.
  final int count;

  /// A retaining path, when `leak_tracker` could resolve one.
  final String? retainingPath;
}

/// A network call flagged as redundant by `waste_lens_dio`.
final class RedundantCall extends DiagnosticEvent {
  const RedundantCall({
    required super.at,
    required this.endpoint,
    required this.signature,
    required this.sinceLast,
    required this.wastedBytes,
    this.coalesced = false,
  });

  /// The request path, e.g. `GET https://api/users`.
  final String endpoint;

  /// Canonical request signature used to detect the duplicate.
  final String signature;

  /// Time since the previous identical call completed.
  final Duration sinceLast;

  /// Approximate response size that was re-fetched needlessly.
  final int wastedBytes;

  /// `true` when the duplicate was coalesced into an in-flight request rather
  /// than hitting the network again.
  final bool coalesced;
}

/// A widget rebuild, either over the churn threshold or proven dead.
final class RebuildEvent extends DiagnosticEvent {
  const RebuildEvent({
    required super.at,
    required this.widget,
    required this.count,
    required this.dead,
    this.location,
    this.fixHint,
  });

  /// The rebuilt widget's runtime type (or a probe label).
  final String widget;

  /// Source location `file:line` of the widget's creation, when resolvable.
  final String? location;

  /// Rebuild count within the tracking window.
  final int count;

  /// `true` when the rebuild produced provably identical output (Tier B).
  final bool dead;

  /// A suggested fix, e.g. "wrap in const" or "narrow with select(...)".
  final String? fixHint;
}

/// What dominated the cost of a janky frame.
enum JankKind {
  /// The UI (Dart build/layout) phase overran — usually caused by wasted
  /// rebuilds. Look at the rebuild tracker.
  build,

  /// The GPU raster phase overran — usually overdraw, large images, shaders,
  /// or missing `RepaintBoundary`s.
  raster,
}

/// A single frame that missed its budget (a dropped/janky frame), with the UI
/// vs GPU split so the cost can be attributed.
///
/// Published on the bus for every janky frame. The rolling jank *rate* lives on
/// [WasteAggregates] (which also counts smooth frames); this event is the
/// per-incident signal for stream subscribers.
final class JankEvent extends DiagnosticEvent {
  const JankEvent({
    required super.at,
    required this.totalMs,
    required this.buildMs,
    required this.rasterMs,
    required this.budgetMs,
    required this.kind,
  });

  /// Total frame time (`FrameTiming.totalSpan`), in milliseconds.
  final double totalMs;

  /// Time in the UI/build phase (`FrameTiming.buildDuration`), in milliseconds.
  final double buildMs;

  /// Time in the GPU raster phase (`FrameTiming.rasterDuration`), in
  /// milliseconds.
  final double rasterMs;

  /// The per-frame budget that was exceeded, in milliseconds.
  final double budgetMs;

  /// Which phase dominated the overrun.
  final JankKind kind;
}
