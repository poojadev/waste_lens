import 'package:flutter/material.dart';
import 'package:waste_lens/waste_lens.dart';

/// Minimal `waste_lens` setup: wrap your app once. The diagnostics overlay
/// appears in debug/profile; in release this is a zero-overhead no-op.
///
/// The full "Evidence Ledger" demo — one screen per module, each committing a
/// deliberate offence the overlay catches live — lives in the repository's
/// top-level `example/` directory.
void main() {
  runApp(
    const WasteLens(
      config: WasteLensConfig(
        memory: true,
        leaks: true,
        rebuilds: true,
        overlay: true,
      ),
      child: _DemoApp(),
    ),
  );
}

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('waste_lens')),
        body: Center(
          // A dead rebuild caught red-handed: the probe proves the price never
          // changes even when an ancestor rebuilds.
          child: DeadRebuildProbe(
            label: 'PriceTag',
            fingerprint: () => const [42.0, 'USD'],
            child: const Text(r'$42.00'),
          ),
        ),
      ),
    );
  }
}
