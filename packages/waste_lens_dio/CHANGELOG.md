## 0.1.0

Initial release.

- `RedundantCallInterceptor`: in-flight coalescing for idempotent duplicates
  (opt-in) and always-on redundancy-window detection.
- `requestSignature`: canonical, order-independent request signatures with
  body sensitivity.
- `CallReport`: totals, redundant count, % wasted, wasted bytes, and top
  offending endpoints. Routes findings into the `waste_lens` bus.
