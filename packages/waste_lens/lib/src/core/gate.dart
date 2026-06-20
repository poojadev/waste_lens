import 'package:flutter/foundation.dart';

/// Compile-time-ish guard that decides whether `waste_lens` does any work.
///
/// `waste_lens` is a debug/profile tool. Deep profiling (allocation profiles,
/// heap snapshots, retaining paths) relies on the Dart VM Service, which is
/// **not available in release builds**. So every heavy feature is gated behind
/// [Gate.enabled] and becomes a zero-overhead no-op in release.
///
/// Because both [kDebugMode] and [kProfileMode] are `const`, the Dart compiler
/// can tree-shake gated branches out of release binaries entirely.
abstract final class Gate {
  /// `true` in debug and profile builds, `false` in release.
  static const bool enabled = kDebugMode || kProfileMode;
}
