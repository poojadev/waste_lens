import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Flags `Image.network` / `Image.asset` without `cacheWidth` or `cacheHeight`.
///
/// Without cache dimensions an image decodes at full resolution and costs
/// `width × height × 4` bytes in memory regardless of how small it's drawn —
/// a frequent, invisible source of memory pressure in lists and grids.
class ImageNeedsCacheDimensions extends DartLintRule {
  const ImageNeedsCacheDimensions() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'image_needs_cache_dimensions',
    problemMessage:
        'Image decodes at full resolution: no cacheWidth/cacheHeight given.',
    correctionMessage:
        'Add cacheWidth and/or cacheHeight sized to how the image is displayed.',
  );

  static const Set<String> _constructors = {'Image.network', 'Image.asset'};

  // `reporter`'s type is inferred from the base class — see NoSetStateInBuild.
  @override
  void run(
    CustomLintResolver resolver,
    reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final constructor = node.constructorName.toSource();
      if (!_constructors.contains(constructor)) return;

      final hasCacheDimension =
          node.argumentList.arguments.whereType<NamedExpression>().any((arg) {
        final name = arg.name.label.name;
        return name == 'cacheWidth' || name == 'cacheHeight';
      });

      if (!hasCacheDimension) {
        reporter.atNode(node, _code);
      }
    });
  }
}
