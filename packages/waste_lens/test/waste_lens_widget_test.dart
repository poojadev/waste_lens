import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_lens/waste_lens.dart';
import 'package:waste_lens/src/overlay/overlay_panel.dart';
import 'package:waste_lens/src/overlay/waste_overlay.dart';

void main() {
  // These run in debug mode, so Gate.enabled is true and the instrumented path
  // is exercised. The release no-op (identical tree, no timers) is verified by
  // the `flutter run --release` smoke check in the build plan.

  Future<void> pump(WidgetTester tester, [WasteLensConfig? config]) {
    return tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 600)),
        child: WasteLens(
          config: config ?? const WasteLensConfig(),
          child: const _Host(),
        ),
      ),
    );
  }

  testWidgets('mounts overlay bubble and exposes runtime in debug',
      (tester) async {
    await pump(tester);

    expect(find.byType(WasteOverlay), findsOneWidget);
    expect(find.text('child'), findsOneWidget);

    final context = tester.element(find.text('child'));
    final runtime = WasteLens.maybeOf(context);
    expect(runtime, isNotNull);
    expect(WasteLens.current, same(runtime));
  });

  testWidgets('overlay absent when config.overlay is false', (tester) async {
    await pump(tester, const WasteLensConfig(overlay: false));

    expect(find.byType(WasteOverlay), findsNothing);
    // Runtime still present for non-overlay consumers.
    final context = tester.element(find.text('child'));
    expect(WasteLens.maybeOf(context), isNotNull);
  });

  testWidgets('tapping the bubble expands the panel', (tester) async {
    await pump(tester);

    expect(find.byType(OverlayPanel), findsNothing);
    await tester.tap(find.byType(WasteOverlay));
    await tester.pump();
    expect(find.byType(OverlayPanel), findsOneWidget);
    // Zero state copy is shown before any module reports.
    expect(find.text('No wasted rebuilds — yet.'), findsOneWidget);
  });

  testWidgets('exportReport returns the aggregate shape', (tester) async {
    await pump(tester);

    final report = WasteLens.exportReport();
    expect(report.keys, containsAll(<String>['memory', 'leaks', 'rebuilds']));
    expect((report['rebuilds']! as Map)['dead'], 0);
  });
}

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Text('child'),
    );
  }
}
