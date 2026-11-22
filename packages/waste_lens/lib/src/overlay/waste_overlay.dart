import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/gate.dart';
import '../core/waste_aggregates.dart';
import '../core/waste_lens_runtime.dart';
import 'overlay_panel.dart';
import 'overlay_theme.dart';

/// The draggable diagnostics bubble and its expandable panel.
///
/// Debug/profile only — guarded by [Gate.enabled] so it can never ship a frame
/// in release even if it were somehow mounted. Self-themed: it does not read
/// the host app's [Theme] or [Directionality].
class WasteOverlay extends StatefulWidget {
  const WasteOverlay({super.key, required this.runtime});

  final WasteLensRuntime runtime;

  @override
  State<WasteOverlay> createState() => _WasteOverlayState();
}

class _WasteOverlayState extends State<WasteOverlay> {
  static const double _bubbleW = 72;
  static const double _bubbleH = 44;
  static const double _margin = 12;

  Offset? _position; // top-left of the bubble; null until first positioned
  bool _expanded = false;

  WasteAggregates get _agg => widget.runtime.bus.aggregates;

  @override
  Widget build(BuildContext context) {
    if (!Gate.enabled) return const SizedBox.shrink();

    final media = MediaQuery.maybeOf(context);
    final size = media?.size ?? const Size(400, 800);
    final insets = media?.padding ?? EdgeInsets.zero;

    // Default to the bottom-right corner, then keep the stored position inside
    // the safe area on every build (so rotation/resize can't strand it).
    final bounds = _bubbleBounds(size, insets);
    final pos = _clampToRect(
      _position ?? Offset(bounds.right, bounds.bottom),
      bounds,
    );
    _position = pos; // persist the clamped value so dragging never "sticks"

    if (_expanded) {
      final panelOrigin = _panelOrigin(pos, size, insets);
      return Positioned(
        left: panelOrigin.dx,
        top: panelOrigin.dy,
        child: OverlayPanel(
          runtime: widget.runtime,
          onClose: () => setState(() => _expanded = false),
        ),
      );
    }

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = _clampToRect(pos + details.delta, bounds);
          });
        },
        child: _bubble(),
      ),
    );
  }

  /// The allowed rectangle for the bubble's top-left corner.
  Rect _bubbleBounds(Size size, EdgeInsets insets) {
    final left = insets.left + _margin;
    final top = insets.top + _margin;
    final right =
        math.max(left, size.width - insets.right - _bubbleW - _margin);
    final bottom =
        math.max(top, size.height - insets.bottom - _bubbleH - _margin);
    return Rect.fromLTRB(left, top, right, bottom);
  }

  static Offset _clampToRect(Offset o, Rect r) =>
      Offset(o.dx.clamp(r.left, r.right), o.dy.clamp(r.top, r.bottom));

  /// Places the expanded panel next to the bubble but fully on-screen: it opens
  /// upward when the bubble is in the lower half and is clamped to the viewport.
  Offset _panelOrigin(Offset bubble, Size size, EdgeInsets insets) {
    final minX = insets.left + _margin;
    final maxX = math.max(
      minX,
      size.width - insets.right - OverlayPanel.width - _margin,
    );
    final minY = insets.top + _margin;
    final maxY = math.max(
      minY,
      size.height - insets.bottom - OverlayPanel.maxHeight - _margin,
    );

    // Horizontally centre the panel on the bubble, then clamp.
    final left =
        (bubble.dx + _bubbleW / 2 - OverlayPanel.width / 2).clamp(minX, maxX);

    // Open upward from a lower-half bubble, downward otherwise.
    final openUp = bubble.dy > size.height / 2;
    final rawTop = openUp
        ? bubble.dy - OverlayPanel.maxHeight - _margin
        : bubble.dy + _bubbleH + _margin;
    final top = rawTop.clamp(minY, maxY);

    return Offset(left, top);
  }

  Widget _bubble() {
    return Semantics(
      button: true,
      label: 'Open waste_lens diagnostics',
      child: GestureDetector(
        onTap: () => setState(() => _expanded = true),
        child: AnimatedBuilder(
          animation: _agg,
          builder: (context, _) => _BubbleBody(aggregates: _agg),
        ),
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({required this.aggregates});

  final WasteAggregates aggregates;

  @override
  Widget build(BuildContext context) {
    final waste = aggregates.deadRebuilds +
        aggregates.redundantCalls +
        aggregates.leakCount;
    final hot = waste > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: OverlayTokens.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: hot ? OverlayTokens.charge : OverlayTokens.hairline,
          width: hot ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hot ? OverlayTokens.charge : OverlayTokens.cleared,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hot ? '$waste' : 'lens',
            style: OverlayTokens.value,
          ),
        ],
      ),
    );
  }
}
