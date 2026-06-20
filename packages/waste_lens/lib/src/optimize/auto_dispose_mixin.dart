import 'package:flutter/widgets.dart';

/// A [State] mixin that disposes everything you register, in reverse order, so
/// a forgotten `dispose` can't leak.
///
/// Register a resource with [autoDispose], passing how to tear it down. The
/// mixin calls those teardowns from its own [dispose].
///
/// ```dart
/// class _MyState extends State<MyWidget> with AutoDisposeMixin<MyWidget> {
///   late final controller = autoDispose(
///     TextEditingController(),
///     (c) => c.dispose(),
///   );
///   late final sub = autoDispose(
///     stream.listen(_onData),
///     (s) => s.cancel(),
///   );
/// }
/// ```
mixin AutoDisposeMixin<T extends StatefulWidget> on State<T> {
  final List<VoidCallback> _disposers = <VoidCallback>[];

  /// Registers [resource] and returns it unchanged. [dispose] runs during the
  /// state's [dispose], in reverse registration order.
  R autoDispose<R>(R resource, void Function(R resource) dispose) {
    _disposers.add(() => dispose(resource));
    return resource;
  }

  @override
  void dispose() {
    for (final disposer in _disposers.reversed) {
      disposer();
    }
    _disposers.clear();
    super.dispose();
  }
}
