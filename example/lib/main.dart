import 'package:flutter/material.dart';
import 'package:waste_lens/waste_lens.dart';

import 'exhibits/exhibit_a_dead_rebuild.dart';
import 'exhibits/exhibit_b_redundant_calls.dart';
import 'exhibits/exhibit_c_leak.dart';
import 'exhibits/exhibit_d_memory.dart';
import 'ledger_theme.dart';

void main() {
  runApp(
    const WasteLens(
      config: WasteLensConfig(
        memory: true,
        leaks: true,
        rebuilds: true,
        overlay: true,
      ),
      child: EvidenceLedgerApp(),
    ),
  );
}

/// The "Evidence Ledger" — each screen deliberately commits one kind of waste
/// so the waste_lens overlay catches it live.
class EvidenceLedgerApp extends StatelessWidget {
  const EvidenceLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'waste_lens · Evidence Ledger',
      debugShowCheckedModeBanner: false,
      theme: Ledger.themeData(),
      home: const _HomePage(),
    );
  }
}

class _Case {
  const _Case(this.exhibit, this.charge, this.title, this.builder);
  final String exhibit;
  final String charge;
  final String title;
  final WidgetBuilder builder;
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  static const List<_Case> _cases = [
    _Case('EXHIBIT A', 'DEAD REBUILD', 'The tag that changed nothing', _buildA),
    _Case(
        'EXHIBIT B', 'REDUNDANT CALLS', 'Five fetches for one record', _buildB),
    _Case(
        'EXHIBIT C', 'MEMORY LEAK', 'The controller no one disposed', _buildC),
    _Case(
        'EXHIBIT D', 'MEMORY PRESSURE', 'Evidence that wouldn\'t fit', _buildD),
  ];

  static Widget _buildA(BuildContext _) => const ExhibitADeadRebuild();
  static Widget _buildB(BuildContext _) => const ExhibitBRedundantCalls();
  static Widget _buildC(BuildContext _) => const ExhibitCLeak();
  static Widget _buildD(BuildContext _) => const ExhibitDMemory();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Row(
              children: [
                Text('waste',
                    style: Ledger.title.copyWith(fontFamily: Ledger.mono)),
                Text('_lens',
                    style: Ledger.title
                        .copyWith(fontFamily: Ledger.mono, color: Ledger.mark)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'THE EVIDENCE LEDGER',
              style: Ledger.eyebrow,
            ),
            const SizedBox(height: 16),
            Text(
              'Four case files. Each screen commits one performance offence; '
              'open the lens bubble to watch the charges filed live.',
              style: Ledger.body,
            ),
            const SizedBox(height: 24),
            for (final c in _cases) ...[
              _CaseCard(
                data: c,
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: c.builder),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.data, required this.onOpen});

  final _Case data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${data.exhibit}, ${data.charge}: ${data.title}',
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Ledger.inkRaised,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Ledger.hairline),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${data.exhibit} · ${data.charge}',
                        style: Ledger.eyebrow),
                    const SizedBox(height: 8),
                    Text(data.title,
                        style: Ledger.title.copyWith(fontSize: 18)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Ledger.charge),
            ],
          ),
        ),
      ),
    );
  }
}
