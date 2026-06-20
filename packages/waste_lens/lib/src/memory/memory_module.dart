import 'dart:async';

import '../core/diagnostic_event.dart';
import '../core/diagnostics_bus.dart';
import '../core/waste_module.dart';
import 'image_cache_probe.dart';
import 'memory_sampler.dart';
import 'vm_service_profiler.dart';

/// Bundles the three memory layers — RSS sampling, image-cache probing, and the
/// VM-service deep profiler — behind one [WasteModule] and a single timer.
class MemoryModule implements WasteModule {
  MemoryModule({
    required this.interval,
    this.deepProfiling = true,
  })  : _sampler = MemorySampler(),
        _imageCache = const ImageCacheProbe(),
        _profiler = deepProfiling ? VmServiceProfiler() : null;

  /// How often RSS and the image cache are sampled.
  final Duration interval;

  /// Whether the VM-service allocation profiler is enabled.
  final bool deepProfiling;

  final MemorySampler _sampler;
  final ImageCacheProbe _imageCache;
  final VmServiceProfiler? _profiler;

  Timer? _timer;
  DiagnosticsBus? _bus;

  @override
  String get id => 'memory';

  @override
  void start(DiagnosticsBus bus) {
    _bus = bus;
    _tick(); // emit an immediate first sample
    _timer = Timer.periodic(interval, (_) => _tick());
    // Warm up the VM-service connection in the background; failures are silent.
    unawaited(_profiler?.connect());
  }

  void _tick() {
    final bus = _bus;
    if (bus == null) return;
    _sampler.sample(bus);
    _imageCache.sample(bus);
  }

  /// Top-N allocating classes from the VM service, or an empty list when deep
  /// profiling is off or the service is unavailable.
  Future<List<AllocationSample>> topAllocators({int limit = 15}) async {
    return _profiler?.topAllocators(limit: limit) ?? const [];
  }

  /// Current heap usage in bytes, or `null` when unavailable.
  Future<int?> heapUsageBytes() async => _profiler?.heapUsageBytes();

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _bus = null;
    await _profiler?.dispose();
  }
}
