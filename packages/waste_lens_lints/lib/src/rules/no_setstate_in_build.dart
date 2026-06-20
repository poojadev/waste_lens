import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Flags `setState()` invoked synchronously during `build` — it marks the
/// element dirty again immediately and schedules a redundant rebuild (often an
/// infinite rebuild loop). State changes belong in event handlers, `initState`,
/// or `didChangeDependencies`.
class NoSetStateInBuild extends DartLintRule {
  const NoSetStateInBuild() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'no_setstate_in_build',
    problemMessage:
        'setState() is called during build(), forcing an immediate, wasted '
        'rebuild.',
    correctionMessage:
        'Move the state change into an event handler, initState(), or '
        'didChangeDependencies().',
  );

  // `reporter`'s type is inferred from the base class. We avoid naming it
  // because custom_lint_core 0.8.x still types it as the upstream-deprecated
  // reporter; spelling it out would surface a third-party deprecation.
  @override
  void run(
    CustomLintResolver resolver,
    reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'setState') return;
      if (_calledDirectlyInBuild(node)) {
        reporter.atNode(node, _code);
      }
    });
  }

  /// True only when [node] runs as part of `build`'s synchronous body — not
  /// inside a nested closure (a callback like `onPressed: () => setState(...)`
  /// is legitimate).
  bool _calledDirectlyInBuild(AstNode node) {
    for (AstNode? current = node.parent;
        current != null;
        current = current.parent) {
      if (current is FunctionExpression) {
        // Hit a closure boundary before build() — the call is deferred.
        return false;
      }
      if (current is MethodDeclaration) {
        return current.name.lexeme == 'build';
      }
    }
    return false;
  }
}
