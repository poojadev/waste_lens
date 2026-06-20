# waste_lens_dio

Dio add-on for [`waste_lens`](https://pub.dev/packages/waste_lens): detect
redundant API calls, coalesce in-flight duplicates, and report wasted bytes.

The interceptor sits at the network edge — the wrong place to *decide* a call is
unnecessary — so it is a **safety net + diagnostic**: it eliminates exact
in-flight duplicates, flags everything else, and points you at the call site to
fix properly.

## Install

```yaml
dependencies:
  waste_lens: ^0.1.0
  waste_lens_dio: ^0.1.0
  dio: ^5.9.2
```

## Usage

```dart
import 'package:waste_lens/waste_lens.dart';
import 'package:waste_lens_dio/waste_lens_dio.dart';

final dio = Dio()
  ..interceptors.add(
    RedundantCallInterceptor(
      bus: WasteLens.current?.bus, // mirror findings to the overlay
      coalesce: true,              // collapse in-flight idempotent duplicates
      redundancyWindow: const Duration(seconds: 2),
    ),
  );
```

## What it does

| Case | Behaviour |
|---|---|
| **Concurrent duplicate** (idempotent, in-flight) | Coalesced into one network call (opt-in). |
| **Recent duplicate** (within the window) | Flagged; optionally served from a short-lived cache (`serveCache`). |
| **Everything else** | Identified and counted; never silently suppressed. |

Non-idempotent methods (POST/PATCH/DELETE) are never coalesced. Streamed
responses are left untouched.

## Reports

```dart
final report = interceptor.report; // CallReport
print('${report.wastedPercent}% wasted, ${report.redundantCalls} redundant');
for (final e in report.topOffenders()) {
  print('${e.endpoint}: ${e.wastedBytes} bytes');
}
```

## The real fix

The most common redundant call is a `FutureProvider`/`AsyncNotifier` re-firing
on an unrelated rebuild. The interceptor catches the symptom; the cure is to
cache at the provider and narrow with `ref.watch(p.select(...))`.

## License

MIT.
