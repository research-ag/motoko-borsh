# Changelog

## 0.1.0

- Initial Borsh codec implementation.
- `Writer` and `Reader` low-level primitives with little-endian integer support.
- Pure functional encode/decode helpers for primitives (`u8`–`u128`, `bool`, UTF-8 `String`) and composites (vectors, fixed arrays, `Option`, `Result`, tuples).
- `toBytes` / `fromBytes` generic helpers and `toHex` utility.
- Primitive, composite and roundtrip test suites plus a benchmark.
