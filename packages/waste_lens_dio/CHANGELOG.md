## 0.1.1

- Widen the `waste_lens` constraint to `>=0.1.0 <0.3.0` so it installs
  alongside `waste_lens` 0.2.x (Jank Radar). No API changes.

## 0.1.0

Initial release.

- `RedundantCallInterceptor`: in-flight coalescing for idempotent duplicates
  (opt-in) and always-on redundancy-window detection.
- `requestSignature`: canonical, order-independent request signatures with
  body sensitivity.
- `CallReport`: totals, redundant count, % wasted, wasted bytes, and top
  offending endpoints. Routes findings into the `waste_lens` bus.
