import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Flags disposable fields on a `State` that are never released in `dispose()`
/// — the most common Flutter leak.
///
/// A field is considered disposable when its declared type is a well-known
/// disposable or its name ends in `Controller`. It is considered released when
/// `dispose()` calls `.dispose()`, `.cancel()`, or `.close()` on the field.
class DisposeRequired extends DartLintRule {
  const DisposeRequired() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'dispose_required',
    problemMessage:
        'This disposable field is never released in dispose(), leaking its '
        'resources.',
    correctionMessage:
        'Release it in dispose() (e.g. field.dispose() / .cancel() / .close()).',
  );

  static const Set<String> _disposableTypes = {
    'AnimationController',
    'TextEditingController',
    'ScrollController',
    'PageController',
    'TabController',
    'FocusNode',
    'StreamController',
    'StreamSubscription',
    'Ticker',
    'OverlayPortalController',
    'ValueNotifier',
    'ChangeNotifier',
  };

  // `reporter`'s type is inferred from the base class — see NoSetStateInBuild.
  @override
  void run(
    CustomLintResolver resolver,
    reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final superclass = node.extendsClause?.superclass.toSource();
      if (superclass == null || !superclass.startsWith('State')) return;

      final disposeBody = _disposeBodySource(node);

      for (final member in node.members) {
        if (member is! FieldDeclaration || member.isStatic) continue;
        final typeName = member.fields.type?.toSource();
        for (final variable in member.fields.variables) {
          final name = variable.name.lexeme;
          if (!_isDisposable(typeName, name)) continue;
          if (!_isReleased(disposeBody, name)) {
            reporter.atNode(variable, _code);
          }
        }
      }
    });
  }

  bool _isDisposable(String? typeName, String fieldName) {
    if (fieldName.endsWith('Controller')) return true;
    if (typeName == null) return false;
    // Strip generics: `StreamController<int>` -> `StreamController`.
    final base = typeName.split('<').first.trim();
    return _disposableTypes.contains(base);
  }

  String? _disposeBodySource(ClassDeclaration node) {
    for (final member in node.members) {
      if (member is MethodDeclaration && member.name.lexeme == 'dispose') {
        return member.body.toSource();
      }
    }
    return null;
  }

  bool _isReleased(String? disposeBody, String fieldName) {
    if (disposeBody == null) return false;
    return disposeBody.contains('$fieldName.dispose(') ||
        disposeBody.contains('$fieldName.cancel(') ||
        disposeBody.contains('$fieldName.close(') ||
        disposeBody.contains('$fieldName?.dispose(') ||
        disposeBody.contains('$fieldName?.cancel(') ||
        disposeBody.contains('$fieldName?.close(');
  }
}
