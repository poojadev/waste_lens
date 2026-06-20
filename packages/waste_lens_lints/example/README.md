# waste_lens_lints example

Enable the rules in any Flutter package.

`pubspec.yaml`:

```yaml
dev_dependencies:
  waste_lens_lints: ^0.1.0
  custom_lint: ^0.8.1
```

`analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint
```

Then run:

```sh
dart run custom_lint
```

## What gets flagged

```dart
class _MyState extends State<MyWidget> {
  final controller = TextEditingController(); // dispose_required: never disposed

  @override
  Widget build(BuildContext context) {
    setState(() {}); // no_setstate_in_build

    return Column(
      children: [
        Text('static'),                         // prefer_const_widget
        Image.network('https://x/y.png'),       // image_needs_cache_dimensions
      ],
    );
  }
}
```

Runnable good/bad fixtures for every rule live in
[`test/fixtures/`](../test/fixtures).
