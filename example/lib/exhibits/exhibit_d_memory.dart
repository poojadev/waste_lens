import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:waste_lens/waste_lens.dart';

import '../format.dart';
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
                      formatBytes(aggregates.latestRssBytes),
                      style: Ledger.data.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 64,
                      width: double.infinity,
                      child: series.length < 2
                          ? Text('sampling…', style: Ledger.body)
                          : Sparkline(values: series, color: Ledger.charge),
                    ),
                    const SizedBox(height: 12),
                    _row('Ballast held', '${_ballast.length} × 8 MB'),
                    _row(
                      'Image cache budget',
                      formatBytes(aggregates.imageCache?.maxSizeBytes ?? 0),
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
}
