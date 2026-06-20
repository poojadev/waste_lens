import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_lens/waste_lens.dart';

Widget _wrap(Widget child) => MediaQuery(
      data: const MediaQueryData(size: Size(400, 800)),
      child: WasteLens(
        config: const WasteLensConfig(
          overlay: false,
          memory: false,
          leaks: false,
          rebuilds: false, // we drive the probe / tracker directly
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: child,
        ),
      ),
    );

void main() {
  group('DeadRebuildProbe (Tier B)', () {
    testWidgets('flags a rebuild as dead when the fingerprint is unchanged',
        (tester) async {
      final tick = ValueNotifier<int>(0);
      addTearDown(tick.dispose);

      await tester.pumpWidget(
        _wrap(
          ValueListenableBuilder<int>(
            valueListenable: tick,
            builder: (context, _, __) => DeadRebuildProbe(
              label: 'PriceTag',
              highlightWhenDead: false,
              fingerprint: () => const ['constant'], // never changes
              child: const SizedBox(),
            ),
          ),
        ),
      );

      final agg = WasteLens.current!.bus.aggregates;
      expect(agg.deadRebuilds, 0); // baseline build is never dead

      tick.value = 1;
      await tester.pump();
      expect(agg.deadRebuilds, 1);

      tick.value = 2;
      await tester.pump();
      expect(agg.deadRebuilds, 2);
    });

    testWidgets('does not flag when the fingerprint changes', (tester) async {
      final tick = ValueNotifier<int>(0);
      addTearDown(tick.dispose);

      await tester.pumpWidget(
        _wrap(
          ValueListenableBuilder<int>(
            valueListenable: tick,
            builder: (context, value, __) => DeadRebuildProbe(
              label: 'LiveValue',
              highlightWhenDead: false,
              fingerprint: () => [value], // changes every tick
              child: const SizedBox(),
            ),
          ),
        ),
      );

      final agg = WasteLens.current!.bus.aggregates;
      tick.value = 1;
      await tester.pump();
      tick.value = 2;
      await tester.pump();
      expect(agg.deadRebuilds, 0);
    });

    testWidgets('an internal highlight repaint is not a false positive',
        (tester) async {
      final tick = ValueNotifier<int>(0);
      addTearDown(tick.dispose);

      await tester.pumpWidget(
        _wrap(
          ValueListenableBuilder<int>(
            valueListenable: tick,
            builder: (context, _, __) => DeadRebuildProbe(
              label: 'Flashing',
              fingerprint: () => const ['x'],
              child: const SizedBox(),
            ),
          ),
        ),
      );

      final agg = WasteLens.current!.bus.aggregates;
      tick.value = 1; // one parent-driven dead rebuild -> triggers a flash
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200)); // flash repaint
      // The highlight setState must not be counted as another dead rebuild.
      expect(agg.deadRebuilds, 1);
      await tester.pump(const Duration(milliseconds: 300)); // let flash expire
    });
  });

  group('RebuildChurnTracker (Tier A)', () {
    testWidgets('flags a widget type that rebuilds above the threshold',
        (tester) async {
      final bus = DiagnosticsBus();
      addTearDown(bus.dispose);
      final tracker = RebuildChurnTracker(
        threshold: 3,
        window: const Duration(hours: 1),
      );
      tracker.start(bus);

      final tick = ValueNotifier<int>(0);
      addTearDown(tick.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ValueListenableBuilder<int>(
            valueListenable: tick,
            builder: (context, value, __) => Text('v$value'),
          ),
        ),
      );

      for (var i = 1; i <= 4; i++) {
        tick.value = i;
        await tester.pump();
      }

      tracker.debugFlush();
      expect(bus.aggregates.churnEvents, greaterThanOrEqualTo(1));

      // Cancel the periodic timer before the binding's invariant check.
      await tracker.stop();
    });
  });
}
