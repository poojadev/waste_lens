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
  Offset? _position; // null until first layout positions it bottom-right
  bool _expanded = false;

  WasteAggregates get _agg => widget.runtime.bus.aggregates;

  @override
  Widget build(BuildContext context) {
    if (!Gate.enabled) return const SizedBox.shrink();

    final media = MediaQuery.maybeOf(context);
    final size = media?.size ?? const Size(400, 800);
    final pos = _position ??= Offset(size.width - 76, size.height - 140);

    return Positioned(
      left: pos.dx.clamp(0.0, (size.width - 64).clamp(0.0, double.infinity)),
      top: pos.dy.clamp(0.0, (size.height - 64).clamp(0.0, double.infinity)),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() => _position = (_position ?? pos) + details.delta);
        },
        child: _expanded ? _panel() : _bubble(),
      ),
    );
  }

  Widget _panel() {
    return Align(
      alignment: Alignment.topRight,
      child: OverlayPanel(
        runtime: widget.runtime,
        onClose: () => setState(() => _expanded = false),
      ),
    );
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
