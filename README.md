# borsh for Motoko

A pure-Motoko implementation of the [Borsh](https://borsh.io) (Binary Object
Representation Serializer for Hashing) binary serialization format.

## Overview

Borsh is the canonical binary serialization format used by Solana, NEAR and
various cryptographic systems. It is designed to be deterministic, compact and
free of ambiguity, which makes it suitable for hashing and signing.

This package provides a small, allocation-friendly encoder/decoder built on two
low-level primitives — a byte-accumulating `Writer` and a cursor-based `Reader`
— plus a set of pure functional helpers for all Borsh primitive and composite
types.

### Motivation

Interacting with Solana, NEAR and similar chains from an ICP canister requires a
Borsh codec. This package extracts a single, tested and benchmarked
implementation so it can be shared instead of being copied into every canister.

### Interface

- **Primitives**: `u8`, `u16`, `u32`, `u64`, `u128`, `bool`, and UTF-8
  `String` (u32 little-endian length prefix).
- **Composites**: length-prefixed vectors (`[T]`), fixed-size arrays,
  `Option<T>`, `Result<Ok, Err>`, and tuples.
- **Low-level**: `Writer` / `Reader` for hand-rolled struct and enum encodings.
- **Generic helpers**: `toBytes` / `fromBytes`, plus `toHex`.

All multi-byte integers are little-endian.

## Usage

### Install with mops

You need `mops` installed. In your project directory run:

```
mops add borsh
```

In the Motoko source file import the package as:

```motoko
import Borsh "mo:borsh";

```

### Example

```motoko
import Borsh "mo:borsh";

// Encode a Rust-like `struct { x: u8, y: u32, name: String }`.
let bytes = Borsh.toBytes<(Nat8, Nat32, Text)>(
  (1, 300, "ab"),
  func((x, y, name), w) {
    w.writeU8(x);
    w.writeU32Le(y);
    w.writeBytes(Borsh.serializeString(name));
  },
);

// Decode it back.
let (x, y, name) = Borsh.fromBytes<(Nat8, Nat32, Text)>(
  bytes,
  func(r) {
    let x = r.readU8();
    let y = r.readU32Le();
    let len = r.readU32Len();
    let raw = r.readBytes(len);
    (x, y, Borsh.deserializeString(Borsh.serializeVector<Nat8>(raw, Borsh.serializeU8)));
  },
);

```

### Build & test

We need up-to-date versions of `node`, `moc` and `mops` installed.

Then run:

```
mops install
mops test
```

### Benchmark

Run

```
mops bench --replica pocket-ic
```

### Format the code

We use `prettier` with the `prettier-plugin-motoko` plugin (configured in
`.prettierrc`). The CI checks formatting on every pull request.

To format the code locally run:

```
npx -y prettier --plugin prettier-plugin-motoko --write '**/*.{mo,json,md}'
```

To only check the formatting (as CI does) run:

```
npx -y prettier --plugin prettier-plugin-motoko --check '**/*.{mo,json,md}'
```

## Design

The package is organized as:

```
src/
├── Writer.mo   # byte accumulator with little-endian integer encoding
├── Reader.mo   # cursor-based binary parser with bounds safety
├── Types.mo    # serializer / deserializer trait types
└── lib.mo      # public encode/decode helpers for all primitives & composites
```

`Writer` and `Reader` are stateful classes; the top-level helpers in `lib.mo`
are pure functions that build on them.

## Authors

Main author: Menese contributors

## License

Apache-2.0
