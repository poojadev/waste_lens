import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_lens_example/exhibits/exhibit_a_dead_rebuild.dart';
import 'package:waste_lens_example/exhibits/exhibit_b_redundant_calls.dart';
import 'package:waste_lens_example/exhibits/exhibit_c_leak.dart';
import 'package:waste_lens_example/exhibits/exhibit_d_memory.dart';

Future<void> _pumpThenDispose(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pump();
  // Replace the tree so any State (and its timers) is disposed before the test
  // ends and the binding checks for pending timers.
  await tester.pumpWidget(const SizedBox());
}

void main() {
  testWidgets('Exhibit A renders its dossier', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExhibitADeadRebuild()));
    await tester.pump();
    expect(find.text('EXHIBIT A · DEAD REBUILD'), findsOneWidget);
    expect(find.text('Apply the const fix'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // dispose the clock timer
  });

  testWidgets('Exhibit B fires duplicate calls and tallies them',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExhibitBRedundantCalls()));
    await tester.pump();
    expect(find.text('EXHIBIT B · REDUNDANT CALLS'), findsOneWidget);
    await tester.tap(find.text('Commit the offence'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.textContaining('Redundant'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Exhibit C and D render', (tester) async {
    await _pumpThenDispose(tester, const ExhibitCLeak());
    await _pumpThenDispose(tester, const ExhibitDMemory());
  });
}
