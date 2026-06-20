import 'dart:io';

import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_lens_lints/src/rules/dispose_required.dart';
import 'package:waste_lens_lints/src/rules/image_needs_cache_dimensions.dart';
import 'package:waste_lens_lints/src/rules/no_setstate_in_build.dart';
import 'package:waste_lens_lints/src/rules/prefer_const_widget.dart';

void main() {
  // Each fixture pairs one rule-violating "bad" case with "good" cases that
  // must stay clean, so the expected lint count is always exactly 1.
  //
  // The rules need a resolved unit, which custom_lint's `testAnalyzeAndRun`
  // builds via a fresh analyzer context. On a machine where the active Flutter
  // SDK doesn't expose the engine-version stamp the analyzer expects, that
  // bootstrap can't start a Dart SDK — there we skip (only on that specific
  // environment error; assertion failures still fail the suite).
  File fixtureFile(String name) {
    const candidates = [
      'test/fixtures/',
      'packages/waste_lens_lints/test/fixtures/',
    ];
    for (final base in candidates) {
      final file = File('$base$name');
      if (file.existsSync()) return file.absolute;
    }
    fail('missing fixture: $name');
  }

  Future<void> expectOneLint(DartLintRule rule, String fixture) async {
    final List<Object?> errors;
    try {
      errors = await rule.testAnalyzeAndRun(fixtureFile(fixture));
    } on Object catch (error) {
      if (error.toString().contains('artifacts/engine')) {
        markTestSkipped(
          'Skipped: active Flutter SDK lacks the engine-version stamp the '
          'analyzer needs to bootstrap a context for $fixture.',
        );
        return;
      }
      rethrow;
    }
    expect(errors, hasLength(1), reason: 'fixture: $fixture');
  }

  test('no_setstate_in_build flags the in-build call, not the callback',
      () async {
    await expectOneLint(
        const NoSetStateInBuild(), 'no_setstate_in_build_fixture.dart');
  });

  test('dispose_required flags the undisposed controller only', () async {
    await expectOneLint(
        const DisposeRequired(), 'dispose_required_fixture.dart');
  });

  test('image_needs_cache_dimensions flags the dimension-less image only',
      () async {
    await expectOneLint(const ImageNeedsCacheDimensions(),
        'image_needs_cache_dimensions_fixture.dart');
  });

  test('prefer_const_widget flags const-capable widgets, not Image.network',
      () async {
    await expectOneLint(
        const PreferConstWidget(), 'prefer_const_widget_fixture.dart');
  });
}
