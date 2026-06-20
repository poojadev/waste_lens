import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';

import '../core/gate.dart';

/// Opt-in leak tracking for **custom** disposables that Flutter doesn't track
/// automatically — Riverpod controllers, Isar instances, raw `StreamSubscription`
/// holders, and the like.
///
/// Dart mixins can't hook constructors or `dispose` for you, so call
/// [trackCreation] from your constructor and [trackDisposal] from your
/// `dispose()`. If `dispose` is missed, `leak_tracker` reports the object as
/// `not-disposed` — no hand-rolled `Finalizer` required.
///
/// ```dart
/// class SearchController with DisposeGuard {
///   SearchController() {
///     trackCreation();
///   }
///   void dispose() {
///     trackDisposal();
///     _sub.cancel();
///   }
/// }
/// ```
///
/// Every method is a no-op in release ([Gate.enabled] is `false`).
mixin DisposeGuard {
  bool _creationTracked = false;
  bool _disposalTracked = false;

  /// The library label attached to leak reports. Override to group reports by
  /// your own package name.
  @protected
  String get disposeGuardLibrary => 'waste_lens';

  /// Registers this object with `leak_tracker`. Call once, from the constructor.
  @protected
  void trackCreation() {
    if (!Gate.enabled || _creationTracked) return;
    _creationTracked = true;
    LeakTracking.dispatchObjectCreated(
      library: disposeGuardLibrary,
      className: runtimeType.toString(),
      object: this,
    );
  }

  /// Marks this object disposed. Call once, from `dispose()`, before releasing
  /// inner resources. Asserts on double-disposal in debug.
  @protected
  void trackDisposal() {
    if (!Gate.enabled) return;
    assert(
      !_disposalTracked,
      '$runtimeType.trackDisposal() called more than once.',
    );
    if (_disposalTracked) return;
    _disposalTracked = true;
    LeakTracking.dispatchObjectDisposed(object: this);
  }
}
