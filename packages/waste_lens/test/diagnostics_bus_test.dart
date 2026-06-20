import 'package:flutter_test/flutter_test.dart';
import 'package:waste_lens/waste_lens.dart';

void main() {
  group('DiagnosticsBus', () {
    late DiagnosticsBus bus;

    setUp(() => bus = DiagnosticsBus(sparklineCapacity: 4));
    tearDown(() => bus.dispose());

    test('emit reaches subscribers', () async {
      final received = <DiagnosticEvent>[];
      final sub = bus.stream.listen(received.add);

      final event = RebuildEvent(
        at: DateTime.now(),
        widget: 'PriceTag',
        count: 1,
        dead: true,
      );
      bus.emit(event);
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single, same(event));
      await sub.cancel();
    });

    test('folds events into aggregates', () {
      bus
        ..emit(
            RebuildEvent(at: DateTime.now(), widget: 'A', count: 1, dead: true))
        ..emit(RebuildEvent(
            at: DateTime.now(), widget: 'B', count: 9, dead: false))
        ..emit(LeakReported(
            at: DateTime.now(), type: 'Ctl', kind: 'not-disposed', count: 2))
        ..emit(RedundantCall(
          at: DateTime.now(),
          endpoint: 'GET /x',
          signature: 'sig',
          sinceLast: const Duration(milliseconds: 200),
          wastedBytes: 1024,
        ));

      final a = bus.aggregates;
      expect(a.deadRebuilds, 1);
      expect(a.churnEvents, 1);
      expect(a.leakCount, 2);
      expect(a.redundantCalls, 1);
      expect(a.wastedBytes, 1024);
    });

    test('memory samples feed the rolling sparkline series', () {
      for (final rss in [10, 20, 30, 40, 50]) {
        bus.emit(MemorySample(at: DateTime.now(), rssBytes: rss));
      }
      // capacity 4 -> oldest (10) dropped.
      expect(bus.aggregates.rssSeries.toList(), [20, 30, 40, 50]);
      expect(bus.aggregates.latestRssBytes, 50);
    });

    test('emit after dispose is a no-op', () async {
      await bus.dispose();
      expect(() => bus.emit(MemorySample(at: DateTime.now(), rssBytes: 1)),
          returnsNormally);
      expect(bus.aggregates.latestRssBytes, 0);
    });
  });
}
