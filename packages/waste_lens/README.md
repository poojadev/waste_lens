# waste_lens

Catch **wasted work** in your Flutter app — dead widget rebuilds, redundant API
calls, memory leaks, and memory pressure — surfaced live in-app and exportable
as a report.

> Many tools show you rebuilds/sec and FPS. `waste_lens` is different: it proves
> a rebuild produced **identical output** (dead) and that work was genuinely
> *wasted* — not just frequent.

`waste_lens` is a **debug/profile tool**. Everything is gated behind
`kDebugMode || kProfileMode`; in release builds it compiles to a **zero-overhead
no-op** — no timers, no listeners, an identical widget tree.

## Install

```yaml
dependencies:
  waste_lens: ^0.1.0
```

## Quick start

Wrap your app once:

```dart
import 'package:waste_lens/waste_lens.dart';

void main() {
  runApp(
    WasteLens(
      config: WasteLensConfig(
        memory: true,
        leaks: true,
        rebuilds: true,
        overlay: true,
      ),
      child: const MyApp(),
    ),
  );
}
```

A draggable diagnostics bubble appears in debug/profile. Tap it for per-module
tabs and live sparklines.

## Modules

### Dead rebuilds (the flagship)

A *dead rebuild* ran but produced identical output, so it was wasted.

- **Tier A — churn (zero-config):** hooks `debugOnRebuildDirtyWidget` and warns
  when a widget type rebuilds above `churnThreshold` within a window.
- **Tier B — proven dead:** wrap a subtree with a fingerprint of the inputs that
  *should* determine its output. If the fingerprint is unchanged across a
  rebuild, it was dead:

```dart
DeadRebuildProbe(
  label: 'PriceTag',
  fingerprint: () => [price, currency], // inputs that matter
  child: PriceTag(price: price, currency: currency),
);
```

The probe outlines the subtree in amber for a moment when it catches a dead
rebuild — caught red-handed.

### Jank Radar

Watches real frame timings and flags dropped frames, classifying each as
**build-bound** (Dart UI work — usually your wasted rebuilds) or
**raster-bound** (GPU overdraw, large images, shaders). Build-bound jank is the
user-visible cost of the waste the other modules hunt. The overlay's **JANK**
tab shows the jank rate, worst frame, and the build-vs-raster split.

```dart
WasteLens(
  config: WasteLensConfig(
    jank: true,
    jankBudget: Duration(milliseconds: 16), // 8ms for 120fps
  ),
  child: const MyApp(),
);
```

### Memory

RSS sampling (every mode), image-cache pressure, and a best-effort VM-service
allocation profiler:

```dart
final top = await WasteLens.snapshot(); // top allocating classes (debug)
```

### Leaks

A thin wrapper over the official [`leak_tracker`]. Framework disposables are
tracked automatically. For custom disposables, use the `DisposeGuard` mixin:

```dart
class SearchController with DisposeGuard {
  SearchController() {
    trackCreation();
  }
  void dispose() {
    trackDisposal();
    // release inner resources…
  }
}
```

### Redundant API calls

Live in the companion package
[`waste_lens_dio`](https://pub.dev/packages/waste_lens_dio).

## Optimization helpers

```dart
imageCacheTuner(maxBytes: 50 << 20); // cap decoded-image memory

class _MyState extends State<MyWidget> with AutoDisposeMixin<MyWidget> {
  late final controller =
      autoDispose(TextEditingController(), (c) => c.dispose());
}
```

## Reports

```dart
final json = WasteLens.exportReport(); // aggregate snapshot for CI / bug reports
```

## Release behaviour

`Gate.enabled` is a compile-time constant (`kDebugMode || kProfileMode`). In
release every entry point short-circuits and the compiler tree-shakes the gated
branches away.

## Lints

Static companion: [`waste_lens_lints`](https://pub.dev/packages/waste_lens_lints).

## License

MIT.

[`leak_tracker`]: https://pub.dev/packages/leak_tracker
