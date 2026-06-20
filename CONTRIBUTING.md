# Contributing to waste_lens

Thanks for your interest! This repo is a native Dart **pub workspace** holding
three published packages and one example app.

## Layout

```
packages/
  waste_lens/        core: bus, overlay, memory, leaks, dead rebuilds
  waste_lens_dio/    Dio add-on: redundant-call detection
  waste_lens_lints/  custom_lint rules
example/             the "Evidence Ledger" demo
```

## Getting started

```sh
flutter pub get                  # resolves the whole workspace
flutter analyze                  # must be clean (zero issues)
dart format .                    # must be a no-op

flutter test packages/waste_lens
flutter test packages/waste_lens_dio
flutter test packages/waste_lens_lints
flutter test example
```

CI runs all of the above on every push and PR; please make sure they pass
locally first.

## Ground rules

- **No warnings, no deprecated APIs.** `flutter analyze` must report zero
  issues and the code must be `dart format`-clean.
- **Debug/profile only.** Every runtime feature must be gated behind
  `Gate.enabled` (`kDebugMode || kProfileMode`) and be a no-op in release.
- **Add a test with every change.** Unit-test pure logic; widget-test anything
  that touches the tree. New lint rules need good + bad fixtures.
- **Keep the core dependency-light.** Anything Dio-specific belongs in
  `waste_lens_dio`; lints belong in `waste_lens_lints`.
- **SDK-constrained deps** (`vm_service`, `leak_tracker`, `analyzer`, …) stay on
  loose constraints — never tight caret pins, which break consumer resolution.

## Commit & PR

- Branch off `main`, keep commits focused, and open a PR against `main`.
- Update the relevant package `CHANGELOG.md` under an unreleased heading.

## Publishing (maintainers)

Publish order matters — the add-ons depend on the core:

```sh
cd packages/waste_lens && flutter pub publish        # first
cd ../waste_lens_dio && flutter pub publish
cd ../waste_lens_lints && flutter pub publish
```

## License

By contributing you agree your work is licensed under the [MIT License](LICENSE).
