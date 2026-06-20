import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import '../core/diagnostic_event.dart';
import '../core/diagnostics_bus.dart';
import '../core/gate.dart';
import '../core/waste_lens.dart';

/// Tier B — **proves** a rebuild was dead (wasted).
///
/// Wrap a subtree and supply a [fingerprint] of the inputs that *should*
/// determine its output. Each time the parent rebuilds this probe, the new
/// fingerprint is compared (deeply) to the previous one. If they're equal the
/// rebuild produced identical output and is reported as
/// `RebuildEvent(dead: true)` — the rebuild was wasted and a `const`,
/// `RepaintBoundary`, memoization, or narrower `select()` would prevent it.
///
/// ```dart
/// DeadRebuildProbe(
///   label: 'PriceTag',
///   fingerprint: () => [price, currency], // inputs that matter
///   child: PriceTag(price: price, currency: currency),
/// );
/// ```
///
/// In release ([Gate.enabled] is `false`) this is a transparent pass-through:
/// it returns [child] with no comparison and no state.
class DeadRebuildProbe extends StatefulWidget {
  const DeadRebuildProbe({
    super.key,
    required this.label,
    required this.fingerprint,
    required this.child,
    this.fixHint,
    this.highlightWhenDead = true,
  });

  /// A human label for the probed subtree (shown in reports/overlay).
  final String label;

  /// Returns the inputs that legitimately determine [child]'s output. Equal
  /// fingerprints across rebuilds mean the rebuild was dead.
  final List<Object?> Function() fingerprint;

  /// The subtree being probed.
  final Widget child;

  /// Optional tailored fix suggestion; a sensible default is used otherwise.
  final String? fixHint;

  /// Briefly outline the subtree in evidence-amber when a dead rebuild is
  /// caught — "caught red-handed". Respects reduced-motion.
  final bool highlightWhenDead;

  @override
  State<DeadRebuildProbe> createState() => _DeadRebuildProbeState();
}

class _DeadRebuildProbeState extends State<DeadRebuildProbe> {
  static const Color _charge = Color(0xFFE0A52E);
  static const Duration _flashDuration = Duration(milliseconds: 400);
  static const _equality = DeepCollectionEquality();

  List<Object?>? _last;
  DiagnosticsBus? _bus;
  Timer? _flashTimer;
  bool _flashing = false;

  @override
  void initState() {
    super.initState();
    if (Gate.enabled) {
      // First build establishes a baseline; it is never "dead".
      _last = widget.fingerprint();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Gate.enabled) {
      _bus = WasteLens.maybeOf(context)?.bus;
    }
  }

  @override
  void didUpdateWidget(DeadRebuildProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Evaluated here, not in build(), so the probe's own highlight setState
    // can never be mistaken for a parent-driven rebuild (no false positives).
    if (Gate.enabled) _evaluate();
  }

  void _evaluate() {
    final current = widget.fingerprint();
    final previous = _last;
    if (previous != null && _equality.equals(previous, current)) {
      _reportDead();
    }
    _last = current;
  }

  void _reportDead() {
    _bus?.emit(
      RebuildEvent(
        at: DateTime.now(),
        widget: widget.label,
        count: 1,
        dead: true,
        fixHint: widget.fixHint ??
            'Inputs unchanged — wrap ${widget.label} in const, add a '
                'RepaintBoundary, or narrow the rebuild with select().',
      ),
    );
    if (widget.highlightWhenDead) _flash();
  }

  void _flash() {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducedMotion) return;
    _flashTimer?.cancel();
    setState(() => _flashing = true);
    _flashTimer = Timer(_flashDuration, () {
      if (mounted) setState(() => _flashing = false);
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Gate.enabled) return widget.child;
    if (!_flashing) return widget.child;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: _charge, width: 1.5),
      ),
      child: widget.child,
    );
  }
}
