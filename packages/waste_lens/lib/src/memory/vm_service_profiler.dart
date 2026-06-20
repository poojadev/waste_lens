import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../core/diagnostic_event.dart';

/// Best-effort deep memory profiling over the Dart VM service.
///
/// The VM service is only present in debug/profile and may still be absent
/// (e.g. headless tests). Every call is wrapped so failures degrade to an empty
/// result and log at most once — the profiler never throws into the host app.
class VmServiceProfiler {
  VmServiceProfiler();

  VmService? _service;
  String? _isolateId;
  bool _connectAttempted = false;
  bool _warned = false;

  /// Whether a live VM-service connection is currently held.
  bool get isConnected => _service != null;

  /// Connects to the VM service and resolves the main isolate. Idempotent and
  /// safe to await repeatedly; returns `true` once connected.
  Future<bool> connect() async {
    if (_service != null) return true;
    if (_connectAttempted && _service == null) return false;
    _connectAttempted = true;
    try {
      final info = await developer.Service.getInfo();
      final uri = info.serverUri;
      if (uri == null) return false;
      final service = await vmServiceConnectUri(_toWebSocket(uri).toString());
      final vm = await service.getVM();
      final isolate = vm.isolates?.firstOrNull;
      if (isolate?.id == null) {
        await service.dispose();
        return false;
      }
      _service = service;
      _isolateId = isolate!.id;
      return true;
    } on Object catch (error) {
      _logOnce(error);
      return false;
    }
  }

  /// The top [limit] classes by retained bytes, or an empty list when the VM
  /// service is unavailable.
  Future<List<AllocationSample>> topAllocators({int limit = 15}) async {
    if (!await connect()) return const [];
    final service = _service;
    final isolateId = _isolateId;
    if (service == null || isolateId == null) return const [];
    try {
      final profile = await service.getAllocationProfile(isolateId);
      final members = profile.members ?? const <ClassHeapStats>[];
      final ranked = members
          .where((m) => (m.bytesCurrent ?? 0) > 0)
          .toList(growable: false)
        ..sort((a, b) => (b.bytesCurrent ?? 0).compareTo(a.bytesCurrent ?? 0));
      final now = DateTime.now();
      return [
        for (final m in ranked.take(limit))
          AllocationSample(
            at: now,
            className: m.classRef?.name ?? '<anonymous>',
            instances: m.instancesCurrent ?? 0,
            bytes: m.bytesCurrent ?? 0,
          ),
      ];
    } on Object catch (error) {
      _logOnce(error);
      return const [];
    }
  }

  /// Current heap usage in bytes, or `null` when unavailable.
  Future<int?> heapUsageBytes() async {
    if (!await connect()) return null;
    final service = _service;
    final isolateId = _isolateId;
    if (service == null || isolateId == null) return null;
    try {
      final usage = await service.getMemoryUsage(isolateId);
      return usage.heapUsage;
    } on Object catch (error) {
      _logOnce(error);
      return null;
    }
  }

  /// Releases the VM-service connection. Idempotent.
  Future<void> dispose() async {
    final service = _service;
    _service = null;
    _isolateId = null;
    if (service != null) {
      try {
        await service.dispose();
      } on Object {
        // Disposing a dead connection is fine to ignore.
      }
    }
  }

  void _logOnce(Object error) {
    if (_warned) return;
    _warned = true;
    debugPrint('waste_lens: VM-service profiling unavailable ($error). '
        'Allocation profiles disabled for this session.');
  }

  static Uri _toWebSocket(Uri httpUri) {
    final segments = [
      ...httpUri.pathSegments.where((s) => s.isNotEmpty),
      'ws',
    ];
    return httpUri.replace(scheme: 'ws', pathSegments: segments);
  }
}
