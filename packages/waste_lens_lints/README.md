# waste_lens_lints

`custom_lint` rules for [`waste_lens`](https://pub.dev/packages/waste_lens) — the
static half of the toolkit. Catch waste before it runs.

## Install

```yaml
dev_dependencies:
  waste_lens_lints: ^0.1.0
  custom_lint: ^0.8.1
```

Enable the plugin in `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint
```

Run from the CLI:

```sh
dart run custom_lint
```

## Rules

| Rule | Flags |
|---|---|
| `no_setstate_in_build` | `setState()` called synchronously during `build()` — forces an immediate, wasted rebuild. |
| `dispose_required` | A disposable `State` field never released in `dispose()`. |
| `image_needs_cache_dimensions` | `Image.network` / `Image.asset` without `cacheWidth` / `cacheHeight`. |
| `prefer_const_widget` | A widget with only constant arguments and a const constructor that isn't `const`. |

`prefer_const_widget` is conservative by design: it only fires when the static
type is a `Widget`, the constructor is `const`, and **every** argument is a
compile-time constant — so the suggestion is always safe (and it never
mis-fires on non-const constructors like `Image.network`).

## License

MIT.
