import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rules/dispose_required.dart';
import 'src/rules/image_needs_cache_dimensions.dart';
import 'src/rules/no_setstate_in_build.dart';
import 'src/rules/prefer_const_widget.dart';

/// custom_lint entry point — returns the `waste_lens` rule set.
///
/// Enable in a consumer's `analysis_options.yaml`:
/// ```yaml
/// analyzer:
///   plugins:
///     - custom_lint
/// ```
PluginBase createPlugin() => _WasteLensLints();

class _WasteLensLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
        NoSetStateInBuild(),
        DisposeRequired(),
        ImageNeedsCacheDimensions(),
        PreferConstWidget(),
      ];
}
