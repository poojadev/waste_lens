import 'dart:async';

import 'package:flutter/material.dart';
import 'package:waste_lens/waste_lens.dart';

import '../ledger_theme.dart';
import '../widgets/dossier.dart';

/// Exhibit A — a ticking clock high in the tree rebuilds a static price tag on
/// every frame. The [DeadRebuildProbe] proves the tag's inputs never changed,
/// so each rebuild was wasted. The "apply const fix" toggle isolates the tag in
/// a const subtree and the charges stop climbing.
class ExhibitADeadRebuild extends StatefulWidget {
  const ExhibitADeadRebuild({super.key});

  @override
  State<ExhibitADeadRebuild> createState() => _ExhibitADeadRebuildState();
}

class _ExhibitADeadRebuildState extends State<ExhibitADeadRebuild> {
  static const double _price = 42.00;

  Timer? _clock;
  int _tick = 0;
  bool _fixed = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aggregates = WasteLens.maybeOf(context)?.bus.aggregates;

    return DossierScaffold(
      exhibit: 'EXHIBIT A',
      charge: 'DEAD REBUILD',
      title: 'The tag that rebuilt and changed nothing',
      blurb: 'A clock ticks every 600ms and rebuilds this whole screen. The '
          'price never changes — so every rebuild of the tag is wasted work a '
          'const would prevent.',
      children: [
        OffenceZone(
          label: 'TICK $_tick · THE ACCUSED',
          child: Center(
            child: _fixed
                // FIXED: a const subtree Flutter skips rebuilding.
                ? const _PriceTag(price: _price)
                // BUGGY: rebuilt every tick; the probe proves it's dead.
                : DeadRebuildProbe(
                    label: 'PriceTag',
                    fingerprint: () => const [_price],
                    child: const _PriceTag(price: _price),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        if (aggregates != null)
          Docket(
            listenable: aggregates,
            selector: () => aggregates.deadRebuilds,
            label: 'Dead rebuilds charged',
          ),
        const SizedBox(height: 16),
        LedgerButton(
          label: _fixed ? 'Revert the fix' : 'Apply the const fix',
          tone: _fixed ? Ledger.cleared : Ledger.charge,
          onPressed: () => setState(() => _fixed = !_fixed),
        ),
        const SizedBox(height: 10),
        Text(
          _fixed
              ? 'Fixed: the tag is const, so the tick no longer rebuilds it. '
                  'The charge count holds.'
              : 'Watch the docket stamp a new charge on each tick.',
          style: Ledger.body,
        ),
      ],
    );
  }
}

class _PriceTag extends StatelessWidget {
  const _PriceTag({required this.price});

  final double price;

  @override
  Widget build(BuildContext context) {
    return Text(
      '\$${price.toStringAsFixed(2)}',
      style: Ledger.data.copyWith(fontSize: 40, fontWeight: FontWeight.w700),
    );
  }
}
