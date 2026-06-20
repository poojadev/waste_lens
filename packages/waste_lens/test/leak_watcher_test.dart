import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:waste_lens/waste_lens.dart';

/// A custom disposable that "forgets" to dispose — the canonical leak.
class _LeakyController with DisposeGuard {
  _LeakyController() {
    trackCreation();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DisposeGuard double-dispatch is asserted', () {
    final guarded = _DisposedController()..dispose();
    expect(guarded.dispose, throwsA(isA<AssertionError>()));
  });

  test('a custom disposable that is never disposed is reported as a leak',
      () async {
    final bus = DiagnosticsBus();
    addTearDown(bus.dispose);
    final watcher = LeakWatcher(checkPeriod: const Duration(hours: 1));
    addTearDown(watcher.stop);
    watcher.start(bus);

    // Create and immediately drop a tracked-but-undisposed object.
    _LeakyController();

    // Declare not-disposed objects as leaks now, then collect deterministically.
    LeakTracking.declareNotDisposedObjectsAsLeaks();
    await watcher.collectNow();

    expect(bus.aggregates.leakCount, greaterThanOrEqualTo(1));
  });
}

class _DisposedController with DisposeGuard {
  _DisposedController() {
    trackCreation();
  }

  @mustCallSuper
  void dispose() {
    trackDisposal();
  }
}
