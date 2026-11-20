import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_lens/waste_lens.dart';

/// Regression: a DeadRebuildProbe reports from `didUpdateWidget`, i.e. during
/// the build phase. With the overlay mounted, that used to notify the
/// overlay's AnimatedBuilder mid-build and throw
/// "setState() or markNeedsBuild() called during build" on every dead rebuild.
void main() {
  testWidgets(
      'dead rebuilds with the overlay on: no build-phase exception, '
      'counter still increments', (tester) async {
    final parent = GlobalKey<_RebuildingParentState>();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 600)),
        child: WasteLens(
          config: const WasteLensConfig(
            overlay: true,
            rebuilds: true,
            memory: false,
            leaks: false,
          ),
          child: _RebuildingParent(key: parent),
        ),
      ),
    );

    // Rebuild the parent a few times. The probe's fingerprint never changes,
    // so every rebuild after the first is a dead rebuild.
    for (var i = 0; i < 3; i++) {
      parent.currentState!.rebuild();
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    // Let the probe's 400ms highlight timer and the deferred notify settle.
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    final aggregates = WasteLens.current!.bus.aggregates;
    expect(aggregates.deadRebuilds, greaterThan(0));
    // The report reads the same counter, synchronously.
    final report = WasteLens.exportReport();
    expect(
      (report['rebuilds']! as Map<String, Object?>)['dead'],
      aggregates.deadRebuilds,
    );
  });
}

/// Rebuilds its probe on demand with an UNCHANGED fingerprint.
class _RebuildingParent extends StatefulWidget {
  const _RebuildingParent({super.key});

  @override
  State<_RebuildingParent> createState() => _RebuildingParentState();
}

class _RebuildingParentState extends State<_RebuildingParent> {
  int _builds = 0;

  void rebuild() => setState(() => _builds++);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DeadRebuildProbe(
        label: 'Probe',
        fingerprint: () => const ['unchanged'],
        // _builds is deliberately NOT in the fingerprint.
        child: Text('builds: $_builds'),
      ),
    );
  }
}
