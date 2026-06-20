import 'package:flutter/widgets.dart';

import '../core/waste_aggregates.dart';
import '../core/waste_lens_runtime.dart';
import 'overlay_theme.dart';
import 'sparkline.dart';

/// The expanded overlay surface: a tabbed dossier of per-module aggregates.
///
/// Reads live numbers from `runtime.bus.aggregates`. Renders graceful zero
/// states before any module reports.
class OverlayPanel extends StatefulWidget {
  const OverlayPanel({
    super.key,
    required this.runtime,
    required this.onClose,
  });

  final WasteLensRuntime runtime;
  final VoidCallback onClose;

  @override
  State<OverlayPanel> createState() => _OverlayPanelState();
}

enum _Tab { memory, leaks, api, rebuilds }

class _OverlayPanelState extends State<OverlayPanel> {
  _Tab _tab = _Tab.rebuilds; // lead with the flagship

  WasteAggregates get _agg => widget.runtime.bus.aggregates;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      constraints: const BoxConstraints(maxHeight: 360),
      decoration: BoxDecoration(
        color: OverlayTokens.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OverlayTokens.hairline),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          _tabBar(),
          Flexible(
            child: AnimatedBuilder(
              animation: _agg,
              builder: (context, _) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: switch (_tab) {
                  _Tab.memory => _memory(),
                  _Tab.leaks => _leaks(),
                  _Tab.api => _api(),
                  _Tab.rebuilds => _rebuilds(),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
      child: Row(
        children: [
          const Text('waste', style: OverlayTokens.value),
          const Text('_lens',
              style: TextStyle(
                color: OverlayTokens.mark,
                fontSize: 15,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              )),
          const Spacer(),
          _IconButton(
            semanticLabel: 'Close diagnostics panel',
            onTap: widget.onClose,
            child: const Text('✕', style: OverlayTokens.label),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: OverlayTokens.hairline),
        ),
      ),
      child: Row(
        children: [
          _tabButton(_Tab.rebuilds, 'REBUILD'),
          _tabButton(_Tab.api, 'API'),
          _tabButton(_Tab.leaks, 'LEAK'),
          _tabButton(_Tab.memory, 'MEM'),
        ],
      ),
    );
  }

  Widget _tabButton(_Tab tab, String label) {
    final selected = _tab == tab;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tab = tab),
        child: Semantics(
          button: true,
          selected: selected,
          label: '$label tab',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      selected ? OverlayTokens.charge : OverlayTokens.hairline,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: OverlayTokens.eyebrow.copyWith(
                color: selected ? OverlayTokens.charge : OverlayTokens.paper,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _memory() {
    final a = _agg;
    final cache = a.imageCache;
    final series = a.rssSeries.map((v) => v.toDouble()).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stat('RSS', _bytes(a.latestRssBytes)),
        if (a.latestMaxRssBytes > 0)
          _stat('PEAK RSS', _bytes(a.latestMaxRssBytes)),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: series.length < 2
              ? const _Empty('Sampling memory…')
              : Sparkline(
                  values: series,
                  color: OverlayTokens.charge,
                  fillColor: OverlayTokens.charge.withValues(alpha: 0.12),
                ),
        ),
        const SizedBox(height: 8),
        if (cache != null) ...[
          _stat('IMG CACHE', _bytes(cache.sizeBytes)),
          _stat('LIVE IMAGES', '${cache.liveCount}'),
        ] else
          const _Empty('No image-cache reading yet'),
      ],
    );
  }

  Widget _leaks() {
    final n = _agg.leakCount;
    if (n == 0) return const _Empty('No leaks detected — yet.');
    return _stat('LEAKED OBJECTS', '$n', tone: OverlayTokens.verdict);
  }

  Widget _api() {
    final a = _agg;
    if (a.redundantCalls == 0) return const _Empty('No redundant calls — yet.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stat('REDUNDANT', '${a.redundantCalls}', tone: OverlayTokens.charge),
        _stat('COALESCED', '${a.coalescedCalls}', tone: OverlayTokens.cleared),
        _stat('WASTED', _bytes(a.wastedBytes)),
      ],
    );
  }

  Widget _rebuilds() {
    final a = _agg;
    if (a.deadRebuilds == 0 && a.churnEvents == 0) {
      return const _Empty('No wasted rebuilds — yet.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stat('DEAD REBUILDS', '${a.deadRebuilds}', tone: OverlayTokens.charge),
        _stat('CHURN WARNINGS', '${a.churnEvents}'),
      ],
    );
  }

  Widget _stat(String label, String value, {Color? tone}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
              child: Text(label,
                  style: OverlayTokens.eyebrow
                      .copyWith(color: OverlayTokens.paper))),
          Text(value, style: OverlayTokens.value.copyWith(color: tone)),
        ],
      ),
    );
  }

  static String _bytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final precision = size >= 100 || unit == 0 ? 0 : 1;
    return '${size.toStringAsFixed(precision)} ${units[unit]}';
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        message,
        style: OverlayTokens.label.copyWith(
          color: OverlayTokens.paper.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(6), child: child),
      ),
    );
  }
}
