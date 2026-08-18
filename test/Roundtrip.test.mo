/// Roundtrip tests: serialize then deserialize, verify identity.
/// Also tests Writer/Reader directly, toHex, toBytes/fromBytes helpers.
///
/// Run with: mops test

import Borsh "../src/lib";
import Nat8 "mo:core/Nat8";
import Nat16 "mo:core/Nat16";
import Nat32 "mo:core/Nat32";
import Nat64 "mo:core/Nat64";
import Debug "mo:core/Debug";
import Runtime "mo:core/Runtime";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

func arrEq(a : [Nat8], b : [Nat8]) : Bool {
  if (a.size() != b.size()) return false;
  for (i in a.keys()) {
    if (a[i] != b[i]) return false;
  };
  true;
};

func assert_(cond : Bool, msg : Text) {
  if (not cond) {
    Debug.print("FAIL: " # msg);
    Runtime.trap("assertion failed: " # msg);
  };
  Debug.print("PASS: " # msg);
};

// ===========================================================================
// Roundtrip: all primitive types
// ===========================================================================

do {
  // u8 roundtrip for boundary values
  let u8vals : [Nat8] = [0, 1, 127, 128, 255];
  for (v in u8vals.values()) {
    let rt = Borsh.deserializeU8(Borsh.serializeU8(v));
    assert_(rt == v, "roundtrip u8 " # Nat8.toText(v));
  };
};

do {
  // u16 roundtrip
  let vals : [Nat16] = [0, 1, 255, 256, 32767, 65535];
  for (v in vals.values()) {
    let rt = Borsh.deserializeU16(Borsh.serializeU16(v));
    assert_(rt == v, "roundtrip u16 " # Nat16.toText(v));
  };
};

do {
  // u32 roundtrip
  let vals : [Nat32] = [0, 1, 255, 65535, 16777216, 4294967295];
  for (v in vals.values()) {
    let rt = Borsh.deserializeU32(Borsh.serializeU32(v));
    assert_(rt == v, "roundtrip u32 " # Nat32.toText(v));
  };
};

do {
  // u64 roundtrip
  let vals : [Nat64] = [0, 1, 1_000_000, 4294967296, 18446744073709551615];
  for (v in vals.values()) {
    let rt = Borsh.deserializeU64(Borsh.serializeU64(v));
    assert_(rt == v, "roundtrip u64 " # Nat64.toText(v));
  };
};

do {
  // u128 roundtrip
  let vals : [Nat] = [0, 1, 256, 1_000_000_000_000_000_000, 340282366920938463463374607431768211455];
  for (v in vals.values()) {
    let rt = Borsh.deserializeU128(Borsh.serializeU128(v));
    assert_(rt == v, "roundtrip u128");
  };
};

do {
  // bool roundtrip
  assert_(Borsh.deserializeBool(Borsh.serializeBool(true)) == true, "roundtrip bool true");
  assert_(Borsh.deserializeBool(Borsh.serializeBool(false)) == false, "roundtrip bool false");
};

do {
  // string roundtrip
  let strings = ["", "hello", "A", "ü", "hello world 123!@#"];
  for (s in strings.values()) {
    let rt = Borsh.deserializeString(Borsh.serializeString(s));
    assert_(rt == s, "roundtrip string \"" # s # "\"");
  };
};

// ===========================================================================
// Writer / Reader direct usage
// ===========================================================================

do {
  // Write multiple values, read them back in order
  let w = Borsh.newWriter();
  w.writeU8(42);
  w.writeU16Le(1000);
  w.writeU32Le(70000);
  w.writeBool(true);
  w.writeU64Le(9876543210);

  let bytes = w.toBytes();
  let r = Borsh.newReader(bytes);

  assert_(r.readU8() == 42, "Writer/Reader u8");
  assert_(r.readU16Le() == (1000 : Nat16), "Writer/Reader u16");
  assert_(r.readU32Le() == (70000 : Nat32), "Writer/Reader u32");
  assert_(r.readBool() == true, "Writer/Reader bool");
  assert_(r.readU64Le() == (9876543210 : Nat64), "Writer/Reader u64");
  assert_(not r.hasMore(), "Writer/Reader no extra bytes");
};

do {
  // Writer size and clear
  let w = Borsh.newWriter();
  assert_(w.size() == 0, "Writer size initially 0");
  w.writeU8(1);
  w.writeU8(2);
  assert_(w.size() == 2, "Writer size after 2 writes");
  w.clear();
  assert_(w.size() == 0, "Writer size after clear");
};

do {
  // Reader position tracking
  let r = Borsh.newReader([10, 20, 30, 40]);
  assert_(r.getPosition() == 0, "Reader initial position");
  ignore r.readU8();
  assert_(r.getPosition() == 1, "Reader position after 1 byte");
  ignore r.readBytes(2);
  assert_(r.getPosition() == 3, "Reader position after readBytes(2)");
  assert_(r.hasMore(), "Reader hasMore with 1 remaining");
  ignore r.readU8();
  assert_(not r.hasMore(), "Reader hasMore at end");
};

do {
  // Reader shift
  let r = Borsh.newReader([0, 0, 0, 42]);
  r.shift(3);
  assert_(r.readU8() == 42, "Reader shift(3) then readU8");
};

do {
  // Reader readRemainingBytes
  let r = Borsh.newReader([1, 2, 3, 4, 5]);
  ignore r.readU8(); // skip first
  let rest = r.readRemainingBytes();
  assert_(arrEq(rest, [2, 3, 4, 5]), "Reader readRemainingBytes");
};

// ===========================================================================
// toHex
// ===========================================================================

do {
  assert_(Borsh.toHex([]) == "", "toHex([])");
  assert_(Borsh.toHex([0x00]) == "00", "toHex([0x00])");
  assert_(Borsh.toHex([0xFF]) == "ff", "toHex([0xFF])");
  assert_(Borsh.toHex([0xDE, 0xAD, 0xBE, 0xEF]) == "deadbeef", "toHex(deadbeef)");
  assert_(Borsh.toHex([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF]) == "0123456789abcdef", "toHex(0123456789abcdef)");
};

// ===========================================================================
// toBytes / fromBytes generic helpers
// ===========================================================================

do {
  // toBytes with a custom serializer
  let bytes = Borsh.toBytes<Nat8>(
    42,
    func(v : Nat8, w : Borsh.Writer) { w.writeU8(v) },
  );
  assert_(arrEq(bytes, [42]), "toBytes<u8>(42)");

  // fromBytes with custom deserializer
  let val = Borsh.fromBytes<Nat8>(
    [42],
    func(r : Borsh.Reader) : Nat8 { r.readU8() },
  );
  assert_(val == 42, "fromBytes<u8>(42)");
};

do {
  // toBytes: serialize a "struct-like" composite (u8, u32)
  let bytes = Borsh.toBytes<(Nat8, Nat32)>(
    (7, 256),
    func(v : (Nat8, Nat32), w : Borsh.Writer) {
      w.writeU8(v.0);
      w.writeU32Le(v.1);
    },
  );
  // Expected: [7, 0, 1, 0, 0]
  assert_(arrEq(bytes, [7, 0, 1, 0, 0]), "toBytes (u8=7, u32=256)");

  // fromBytes roundtrip
  let (a, b) = Borsh.fromBytes<(Nat8, Nat32)>(
    bytes,
    func(r : Borsh.Reader) : (Nat8, Nat32) {
      (r.readU8(), r.readU32Le());
    },
  );
  assert_(a == 7 and b == (256 : Nat32), "fromBytes (u8, u32) roundtrip");
};

// ===========================================================================
// Borsh spec: combined struct-like encoding
// Simulating Rust: struct Test { x: u8, y: u32, name: String }
// ===========================================================================

do {
  let w = Borsh.newWriter();
  // x = 1
  w.writeU8(1);
  // y = 300 → LE: [0x2C, 0x01, 0x00, 0x00]
  w.writeU32Le(300);
  // name = "ab" → length 2 + bytes
  let nameBytes = Borsh.serializeString("ab");
  w.writeBytes(nameBytes);

  let encoded = w.toBytes();
  // Expected: [1, 0x2C, 0x01, 0x00, 0x00, 2, 0, 0, 0, 0x61, 0x62]
  assert_(arrEq(encoded, [1, 0x2C, 0x01, 0x00, 0x00, 2, 0, 0, 0, 0x61, 0x62]), "struct encoding {x:1, y:300, name:\"ab\"}");

  // Decode
  let r = Borsh.newReader(encoded);
  let x = r.readU8();
  let y = r.readU32Le();
  let nameLen = r.readU32Len();
  let nameRaw = r.readBytes(nameLen);

  assert_(x == 1, "struct decode x");
  assert_(y == (300 : Nat32), "struct decode y");
  assert_(arrEq(nameRaw, [0x61, 0x62]), "struct decode name bytes");
  assert_(not r.hasMore(), "struct no trailing bytes");
};

Debug.print("\n=== All roundtrip tests passed ===");
