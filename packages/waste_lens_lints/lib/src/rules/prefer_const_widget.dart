import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Flags a widget instantiation that could be `const` but isn't — every such
/// widget is rebuilt and re-allocated on each parent build even though its
/// output never changes. A `const` constructor lets Flutter skip the rebuild
/// entirely.
///
/// Conservative by design: it only fires when the static type is a `Widget`,
/// the expression isn't already in a constant context, and **every** argument
/// is itself a compile-time constant — so the suggestion is always safe.
class PreferConstWidget extends DartLintRule {
  const PreferConstWidget() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'prefer_const_widget',
    problemMessage:
        'This widget has only constant arguments and could be const, avoiding '
        'a rebuild and allocation on every parent build.',
    correctionMessage: 'Add the const keyword.',
  );

  static const TypeChecker _widgetChecker =
      TypeChecker.fromName('Widget', packageName: 'flutter');

  // `reporter`'s type is inferred from the base class — see NoSetStateInBuild.
  @override
  void run(
    CustomLintResolver resolver,
    reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (node.isConst || node.inConstantContext) return;

      final type = node.staticType;
      if (type == null || !_widgetChecker.isAssignableFromType(type)) return;

      // Only const constructors can be made const — never flag e.g.
      // `Image.network(...)`, whose constructor isn't const.
      final constructor = node.constructorName.element;
      if (constructor == null || !constructor.isConst) return;

      final allArgsConst = node.argumentList.arguments.every((argument) {
        final expression =
            argument is NamedExpression ? argument.expression : argument;
        return _isCompileTimeConstant(expression);
      });
      if (!allArgsConst) return;

      reporter.atNode(node, _code);
    });
  }

  bool _isCompileTimeConstant(Expression expression) {
    return switch (expression) {
      BooleanLiteral() => true,
      IntegerLiteral() => true,
      DoubleLiteral() => true,
      NullLiteral() => true,
      SimpleStringLiteral() => true,
      InstanceCreationExpression(:final isConst) => isConst,
      _ => false,
    };
  }
}
