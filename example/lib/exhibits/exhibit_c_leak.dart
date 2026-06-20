import 'package:flutter/material.dart';
import 'package:waste_lens/waste_lens.dart';

import '../ledger_theme.dart';
import '../widgets/dossier.dart';

/// Exhibit C — a screen that allocates controllers and "forgets" to dispose
/// them. Once the objects are garbage-collected, leak_tracker (running via the
/// leak module) reports them and the docket logs the leak. The "dispose
/// properly" toggle releases them on creation so nothing leaks.
class ExhibitCLeak extends StatefulWidget {
  const ExhibitCLeak({super.key});

  @override
  State<ExhibitCLeak> createState() => _ExhibitCLeakState();
}

class _ExhibitCLeakState extends State<ExhibitCLeak> {
  bool _disposeProperly = false;
  int _created = 0;

  void _commitOffence() {
    // Create a batch and immediately drop the references. When disposed
    // properly they release cleanly; otherwise leak_tracker catches them.
    for (var i = 0; i < 16; i++) {
      final ctl = _ForensicController();
      if (_disposeProperly) ctl.dispose();
    }
    setState(() => _created += 16);
  }

  @override
  Widget build(BuildContext context) {
    final aggregates = WasteLens.maybeOf(context)?.bus.aggregates;

    return DossierScaffold(
      exhibit: 'EXHIBIT C',
      charge: 'MEMORY LEAK',
      title: 'The controller no one disposed',
      blurb: 'Each offence allocates 16 controllers and drops them. Without '
          'dispose() they linger; leak_tracker confirms the leak after the '
          'next garbage-collection cycle and the docket records it.',
      children: [
        OffenceZone(
          label: 'EVIDENCE LOCKER',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Controllers created this session: $_created',
                  style: Ledger.data),
              const SizedBox(height: 8),
              Text(
                _disposeProperly
                    ? 'Disposing properly — nothing should leak.'
                    : 'Leaking — dispose() is never called.',
                style: Ledger.body.copyWith(
                  color: _disposeProperly ? Ledger.cleared : Ledger.verdict,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (aggregates != null)
          Docket(
            listenable: aggregates,
            selector: () => aggregates.leakCount,
            label: 'Leaks confirmed',
            tone: Ledger.verdict,
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: LedgerButton(
                label: 'Commit the offence',
                tone: Ledger.verdict,
                onPressed: _commitOffence,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LedgerButton(
                label: _disposeProperly ? 'Resume leaking' : 'Dispose properly',
                filled: false,
                tone: Ledger.cleared,
                onPressed: () =>
                    setState(() => _disposeProperly = !_disposeProperly),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Confirmation depends on GC timing — give it a second or two after '
          'committing.',
          style: Ledger.body,
        ),
      ],
    );
  }
}

/// A custom disposable tracked by waste_lens. Calling [dispose] releases it;
/// never calling it makes it a leak.
class _ForensicController with DisposeGuard {
  _ForensicController() {
    trackCreation();
  }

  void dispose() {
    trackDisposal();
  }
}
