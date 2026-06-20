## 0.1.0

Initial release. custom_lint rules built against the custom_lint 0.8.x API:

- `no_setstate_in_build` — `setState()` called during `build`.
- `dispose_required` — disposable `State` field never released in `dispose()`.
- `image_needs_cache_dimensions` — `Image.network`/`Image.asset` without
  `cacheWidth`/`cacheHeight`.
- `prefer_const_widget` — a widget with only constant arguments and a const
  constructor that isn't `const`.
