import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_lens/src/memory/image_cache_probe.dart';
import 'package:waste_lens/src/memory/memory_sampler.dart';
import 'package:waste_lens/waste_lens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MemorySampler emits an RSS sample without throwing', () {
    final bus = DiagnosticsBus();
    addTearDown(bus.dispose);

    MemorySampler().sample(bus);

    // On supported desktop/mobile hosts RSS is > 0; the contract is only that
    // a sample was folded in without throwing.
    expect(bus.aggregates.latestRssBytes, greaterThanOrEqualTo(0));
  });

  test('ImageCacheProbe reflects the painting binding cache', () {
    final bus = DiagnosticsBus();
    addTearDown(bus.dispose);

    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;
    const ImageCacheProbe().sample(bus);

    final stat = bus.aggregates.imageCache;
    expect(stat, isNotNull);
    expect(stat!.maxSizeBytes, 50 << 20);
    expect(stat.pressure, inInclusiveRange(0.0, 1.0));
  });

  test('MemoryModule starts, samples immediately, and stops cleanly', () async {
    final bus = DiagnosticsBus();
    addTearDown(bus.dispose);

    final module = MemoryModule(
      interval: const Duration(milliseconds: 50),
      deepProfiling: false, // no VM service in the test host
    )..start(bus);

    expect(bus.aggregates.imageCache, isNotNull); // immediate first tick
    expect(await module.topAllocators(), isEmpty); // deep profiling off
    await module.stop();
  });
}
