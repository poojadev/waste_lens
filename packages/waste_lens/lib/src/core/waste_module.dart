import 'diagnostics_bus.dart';

/// A single diagnostic subsystem (memory, leaks, rebuilds, …) with a uniform
/// lifecycle, so [WasteLensRuntime] can start and stop them all the same way.
///
/// Implementations must be safe to [stop] even if [start] partially failed, and
/// should publish exclusively through the [DiagnosticsBus] handed to them.
abstract interface class WasteModule {
  /// A short stable identifier, used in logs and reports.
  String get id;

  /// Begins observing and emitting events on [bus]. Called once, in
  /// debug/profile only.
  void start(DiagnosticsBus bus);

  /// Tears down timers, hooks, and subscriptions. Must be idempotent.
  Future<void> stop();
}
