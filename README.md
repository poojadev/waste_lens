# waste_lens

[![CI](https://github.com/poojadev/waste_lens/actions/workflows/ci.yml/badge.svg)](https://github.com/poojadev/waste_lens/actions/workflows/ci.yml)
[![pub: waste_lens](https://img.shields.io/pub/v/waste_lens.svg?label=waste_lens)](https://pub.dev/packages/waste_lens)
[![pub: waste_lens_dio](https://img.shields.io/pub/v/waste_lens_dio.svg?label=waste_lens_dio)](https://pub.dev/packages/waste_lens_dio)
[![pub: waste_lens_lints](https://img.shields.io/pub/v/waste_lens_lints.svg?label=waste_lens_lints)](https://pub.dev/packages/waste_lens_lints)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A Flutter developer-tooling package set for catching **wasted work** — dead
widget rebuilds, redundant API calls, memory leaks, and memory pressure —
surfaced live in-app and exportable as a report.

> The differentiator is **"wasted," not "frequent."** `waste_lens` proves a
> rebuild produced identical output (dead) and that an API call was a genuine
> duplicate — then shows it in a live overlay.

Everything is gated behind `kDebugMode || kProfileMode`; in release the whole
package compiles to a **zero-overhead no-op**.

## Packages

| Package | What it does |
|---|---|
| [`waste_lens`](packages/waste_lens) | Core: bus, overlay, memory, leaks, dead-rebuild detection, optimization helpers. |
| [`waste_lens_dio`](packages/waste_lens_dio) | Dio add-on: redundant-call detection + in-flight coalescing. |
| [`waste_lens_lints`](packages/waste_lens_lints) | `custom_lint` rules: the static half of the toolkit. |

The [`example/`](example) app — the "Evidence Ledger" — is a forensic demo where
each screen deliberately commits one kind of waste so the overlay catches it
live.

## Layout

A native Dart [pub workspace](https://dart.dev/tools/pub/workspaces) (Dart
≥ 3.6). From the root:

```sh
flutter pub get
flutter analyze
flutter test packages/waste_lens
flutter test packages/waste_lens_dio
flutter test example
```

## Publishing

Publish order (dio and lints depend on core): `waste_lens` first, then
`waste_lens_dio` and `waste_lens_lints`.

## License

MIT — see [LICENSE](LICENSE).
