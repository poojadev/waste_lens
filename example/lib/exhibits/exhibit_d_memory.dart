import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:waste_lens/waste_lens.dart';

import '../ledger_theme.dart';
import '../widgets/dossier.dart';

/// Exhibit D — allocates large buffers to drive RSS up while a live sparkline
/// tracks it, and exposes the image-cache budget with a one-tap tuner. Release
/// the ballast (or tune the cache) and the curve flattens.
class ExhibitDMemory extends StatefulWidget {
  const ExhibitDMemory({super.key});

  @override
  State<ExhibitDMemory> createState() => _ExhibitDMemoryState();
}

class _ExhibitDMemoryState extends State<ExhibitDMemory> {
  // Holding these references keeps the memory resident until released.
  final List<Uint8List> _ballast = [];

  void _allocate() {
    // ~8 MB of resident, touched memory.
    final block = Uint8List(8 * 1024 * 1024);
    for (var i = 0; i < block.length; i += 4096) {
      block[i] = 1;
    }
    setState(() => _ballast.add(block));
  }

  void _release() => setState(_ballast.clear);

  void _tuneCache() {
    imageCacheTuner(maxBytes: 20 * 1024 * 1024, maxEntries: 100);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final aggregates = WasteLens.maybeOf(context)?.bus.aggregates;

    return DossierScaffold(
      exhibit: 'EXHIBIT D',
      charge: 'MEMORY PRESSURE',
      title: 'The evidence that wouldn\'t fit in memory',
      blurb:
          'Each allocation pins 8 MB of resident memory; the sparkline below '
          'tracks RSS live. Release the ballast or tune the image cache and the '
          'curve falls back.',
      children: [
        if (aggregates != null)
          OffenceZone(
            label: 'RESIDENT SET SIZE',
            child: AnimatedBuilder(
              animation: aggregates,
              builder: (context, _) {
                final series = aggregates.rssSeries
                    .map((v) => v.toDouble())
                    .toList(growable: false);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatBytes(aggregates.latestRssBytes),
                      style: Ledger.data.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 64,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _RssSparkline(series),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _row('Ballast held', '${_ballast.length} × 8 MB'),
                    _row(
                      'Image cache budget',
                      _formatBytes(aggregates.imageCache?.maxSizeBytes ?? 0),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: LedgerButton(
                label: 'Allocate evidence',
                onPressed: _allocate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LedgerButton(
                label: 'Release',
                filled: false,
                tone: Ledger.cleared,
                onPressed: _ballast.isEmpty ? null : _release,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LedgerButton(
          label: 'Tune image cache → 20 MB',
          filled: false,
          tone: Ledger.cleared,
          onPressed: _tuneCache,
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: Ledger.body)),
            Text(value, style: Ledger.data),
          ],
        ),
      );

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(size >= 100 || unit == 0 ? 0 : 1)} ${units[unit]}';
  }
}

class _RssSparkline extends CustomPainter {
  _RssSparkline(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      final tp = TextPainter(
        text: TextSpan(text: 'sampling…', style: Ledger.body),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, size.height / 2 - tp.height / 2));
      return;
    }
    var min = values.first, max = values.first;
    for (final v in values) {
      if (v < min) min = v;
      if (v > max) max = v;
    }
    final range = (max - min).abs() < 1 ? 1.0 : max - min;
    final dx = size.width / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = dx * i;
      final y = size.height - ((values[i] - min) / range) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Ledger.charge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_RssSparkline old) => old.values != values;
}
