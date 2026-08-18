import Array "mo:core/Array";
import Nat "mo:core/Nat";
import Text "mo:core/Text";
import Bench "mo:bench-helper";

import Borsh "../src/lib";

module {
  public func init() : Bench.V1 {

    let schema : Bench.Schema = {
      name = "Borsh";
      description = "Serialize and deserialize Borsh primitive and composite types";
      rows = [
        "u8",
        "u16",
        "u32",
        "u64",
        "u128",
        "bool",
        "string (5 B)",
        "string (1 KB)",
        "Vec<u8> 100",
        "Vec<u8> 1000",
        "Vec<u32> 100",
        "FixedArray<u8> 256",
        "Option<u8> Some",
        "Tuple3(u8, u32, u64)",
        "Vec<Vec<u8>> 10x10",
      ];
      cols = ["serialize", "deserialize"];
    };

    // Pre-generate inputs
    let shortStr = "hello";
    let longStr = Array.tabulate<Char>(1024, func(_) = 'x')
    |> Array.values(_)
    |> Text.fromIter(_);

    let vecU8_100 : [Nat8] = Array.tabulate<Nat8>(100, func(i) = (i % 256).toNat8());
    let vecU8_1k : [Nat8] = Array.tabulate<Nat8>(1000, func(i) = (i % 256).toNat8());
    let vecU32_100 : [Nat32] = Array.tabulate<Nat32>(100, func(i) = (i).toNat32());
    let fixed256 : [Nat8] = Array.tabulate<Nat8>(256, func(i) = (i % 256).toNat8());
    let nestedVec : [[Nat8]] = Array.tabulate<[Nat8]>(10, func(r) = Array.tabulate<Nat8>(10, func(c) = ((r * 10 + c) % 256).toNat8()));

    // Pre-serialized payloads for deserialization benchmarks
    let serU8 = Borsh.serializeU8(42);
    let serU16 = Borsh.serializeU16(1000);
    let serU32 = Borsh.serializeU32(70000);
    let serU64 = Borsh.serializeU64(9876543210);
    let serU128 = Borsh.serializeU128(1_000_000_000_000_000_000);
    let serBool = Borsh.serializeBool(true);
    let serStrS = Borsh.serializeString(shortStr);
    let serStrL = Borsh.serializeString(longStr);
    let serVecU8_100 = Borsh.serializeVector<Nat8>(vecU8_100, Borsh.serializeU8);
    let serVecU8_1k = Borsh.serializeVector<Nat8>(vecU8_1k, Borsh.serializeU8);
    let serVecU32_100 = Borsh.serializeVector<Nat32>(vecU32_100, Borsh.serializeU32);
    let serFixed256 = Borsh.serializeFixedArray<Nat8>(fixed256, Borsh.serializeU8);
    let serOptSomeU8 = Borsh.serializeOption<Nat8>(?42, Borsh.serializeU8);
    let serTuple3 = Borsh.serializeTuple3<Nat8, Nat32, Nat64>((1, 300, 9876543210), Borsh.serializeU8, Borsh.serializeU32, Borsh.serializeU64);
    let serNested = Borsh.serializeVector<[Nat8]>(
      nestedVec,
      func(inner : [Nat8]) : [Nat8] {
        Borsh.serializeVector<Nat8>(inner, Borsh.serializeU8);
      },
    );

    // Deserializer helpers
    let readU8 = func(r : Borsh.Reader) : Nat8 { r.readU8() };
    let readU32 = func(r : Borsh.Reader) : Nat32 { r.readU32Le() };

    let routines : [[() -> ()]] = [
      // u8
      [
        func() { ignore Borsh.serializeU8(42) },
        func() { ignore Borsh.deserializeU8(serU8) },
      ],
      // u16
      [
        func() { ignore Borsh.serializeU16(1000) },
        func() { ignore Borsh.deserializeU16(serU16) },
      ],
      // u32
      [
        func() { ignore Borsh.serializeU32(70000) },
        func() { ignore Borsh.deserializeU32(serU32) },
      ],
      // u64
      [
        func() { ignore Borsh.serializeU64(9876543210) },
        func() { ignore Borsh.deserializeU64(serU64) },
      ],
      // u128
      [
        func() { ignore Borsh.serializeU128(1_000_000_000_000_000_000) },
        func() { ignore Borsh.deserializeU128(serU128) },
      ],
      // bool
      [
        func() { ignore Borsh.serializeBool(true) },
        func() { ignore Borsh.deserializeBool(serBool) },
      ],
      // string (5 B)
      [
        func() { ignore Borsh.serializeString(shortStr) },
        func() { ignore Borsh.deserializeString(serStrS) },
      ],
      // string (1 KB)
      [
        func() { ignore Borsh.serializeString(longStr) },
        func() { ignore Borsh.deserializeString(serStrL) },
      ],
      // Vec<u8> 100
      [
        func() {
          ignore Borsh.serializeVector<Nat8>(vecU8_100, Borsh.serializeU8);
        },
        func() { ignore Borsh.deserializeVector<Nat8>(serVecU8_100, readU8) },
      ],
      // Vec<u8> 1000
      [
        func() {
          ignore Borsh.serializeVector<Nat8>(vecU8_1k, Borsh.serializeU8);
        },
        func() { ignore Borsh.deserializeVector<Nat8>(serVecU8_1k, readU8) },
      ],
      // Vec<u32> 100
      [
        func() {
          ignore Borsh.serializeVector<Nat32>(vecU32_100, Borsh.serializeU32);
        },
        func() { ignore Borsh.deserializeVector<Nat32>(serVecU32_100, readU32) },
      ],
      // FixedArray<u8> 256
      [
        func() {
          ignore Borsh.serializeFixedArray<Nat8>(fixed256, Borsh.serializeU8);
        },
        func() {
          ignore Borsh.deserializeFixedArray<Nat8>(serFixed256, 256, readU8);
        },
      ],
      // Option<u8> Some
      [
        func() { ignore Borsh.serializeOption<Nat8>(?42, Borsh.serializeU8) },
        func() { ignore Borsh.deserializeOption<Nat8>(serOptSomeU8, readU8) },
      ],
      // Tuple3(u8, u32, u64)
      [
        func() {
          ignore Borsh.serializeTuple3<Nat8, Nat32, Nat64>((1, 300, 9876543210), Borsh.serializeU8, Borsh.serializeU32, Borsh.serializeU64);
        },
        func() {
          ignore Borsh.deserializeTuple3<Nat8, Nat32, Nat64>(
            serTuple3,
            readU8,
            readU32,
            func(r : Borsh.Reader) : Nat64 { r.readU64Le() },
          );
        },
      ],
      // Vec<Vec<u8>> 10x10
      [
        func() {
          ignore Borsh.serializeVector<[Nat8]>(nestedVec, func(inner : [Nat8]) : [Nat8] { Borsh.serializeVector<Nat8>(inner, Borsh.serializeU8) });
        },
        func() {
          ignore Borsh.deserializeVector<[Nat8]>(
            serNested,
            func(r : Borsh.Reader) : [Nat8] {
              let len = r.readU32Len();
              Array.tabulate<Nat8>(len, func(_) = r.readU8());
            },
          );
        },
      ],
    ];

    Bench.V1(
      schema,
      func(ri : Nat, ci : Nat) = routines[ri][ci](),
    );
  };
};
