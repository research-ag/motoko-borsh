/// Test vectors for Borsh primitive serialization / deserialization.
/// Reference: https://borsh.io — all multi-byte integers are little-endian.
///
/// Run with: mops test

import Borsh "../src/lib";
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
// u8
// ===========================================================================

do {
  // Borsh(0u8) == [0x00]
  let bytes = Borsh.serializeU8(0);
  assert_(arrEq(bytes, [0x00]), "serializeU8(0)");

  // Borsh(1u8) == [0x01]
  let bytes1 = Borsh.serializeU8(1);
  assert_(arrEq(bytes1, [0x01]), "serializeU8(1)");

  // Borsh(255u8) == [0xFF]
  let bytes255 = Borsh.serializeU8(255);
  assert_(arrEq(bytes255, [0xFF]), "serializeU8(255)");

  // roundtrip
  assert_(Borsh.deserializeU8([0x00]) == 0, "deserializeU8(0)");
  assert_(Borsh.deserializeU8([0x01]) == 1, "deserializeU8(1)");
  assert_(Borsh.deserializeU8([0xFF]) == 255, "deserializeU8(255)");
};

// ===========================================================================
// u16 (little-endian)
// ===========================================================================

do {
  // Borsh(0u16) == [0x00, 0x00]
  assert_(arrEq(Borsh.serializeU16(0), [0x00, 0x00]), "serializeU16(0)");

  // Borsh(1u16) == [0x01, 0x00]
  assert_(arrEq(Borsh.serializeU16(1), [0x01, 0x00]), "serializeU16(1)");

  // Borsh(256u16) == [0x00, 0x01]
  assert_(arrEq(Borsh.serializeU16(256), [0x00, 0x01]), "serializeU16(256)");

  // Borsh(65535u16) == [0xFF, 0xFF]
  assert_(arrEq(Borsh.serializeU16(65535), [0xFF, 0xFF]), "serializeU16(65535)");

  // Borsh(512u16) == [0x00, 0x02]
  assert_(arrEq(Borsh.serializeU16(512), [0x00, 0x02]), "serializeU16(512)");

  // deserialize
  assert_(Borsh.deserializeU16([0x01, 0x00]) == (1 : Nat16), "deserializeU16(1)");
  assert_(Borsh.deserializeU16([0x00, 0x01]) == (256 : Nat16), "deserializeU16(256)");
  assert_(Borsh.deserializeU16([0xFF, 0xFF]) == (65535 : Nat16), "deserializeU16(65535)");
};

// ===========================================================================
// u32 (little-endian)
// ===========================================================================

do {
  // Borsh(0u32) == [0,0,0,0]
  assert_(arrEq(Borsh.serializeU32(0), [0, 0, 0, 0]), "serializeU32(0)");

  // Borsh(1u32) == [1,0,0,0]
  assert_(arrEq(Borsh.serializeU32(1), [1, 0, 0, 0]), "serializeU32(1)");

  // Borsh(256u32) == [0, 1, 0, 0]
  assert_(arrEq(Borsh.serializeU32(256), [0, 1, 0, 0]), "serializeU32(256)");

  // Borsh(65536u32) == [0, 0, 1, 0]
  assert_(arrEq(Borsh.serializeU32(65536), [0, 0, 1, 0]), "serializeU32(65536)");

  // Borsh(16777216u32) == [0, 0, 0, 1]
  assert_(arrEq(Borsh.serializeU32(16777216), [0, 0, 0, 1]), "serializeU32(16777216)");

  // Borsh(4294967295u32) == [0xFF, 0xFF, 0xFF, 0xFF]
  assert_(arrEq(Borsh.serializeU32(4294967295), [0xFF, 0xFF, 0xFF, 0xFF]), "serializeU32(u32::MAX)");

  // deserialize
  assert_(Borsh.deserializeU32([1, 0, 0, 0]) == (1 : Nat32), "deserializeU32(1)");
  assert_(Borsh.deserializeU32([0xFF, 0xFF, 0xFF, 0xFF]) == (4294967295 : Nat32), "deserializeU32(u32::MAX)");
};

// ===========================================================================
// u64 (little-endian)
// ===========================================================================

do {
  // Borsh(0u64)
  assert_(arrEq(Borsh.serializeU64(0), [0, 0, 0, 0, 0, 0, 0, 0]), "serializeU64(0)");

  // Borsh(1u64) == [1, 0, 0, 0, 0, 0, 0, 0]
  assert_(arrEq(Borsh.serializeU64(1), [1, 0, 0, 0, 0, 0, 0, 0]), "serializeU64(1)");

  // Borsh(1_000_000u64) = 0xF4240 → LE: [0x40, 0x42, 0x0F, 0x00, 0x00, 0x00, 0x00, 0x00]
  assert_(arrEq(Borsh.serializeU64(1_000_000), [0x40, 0x42, 0x0F, 0x00, 0x00, 0x00, 0x00, 0x00]), "serializeU64(1_000_000)");

  // Borsh(u64::MAX) == [0xFF x 8]
  // 18446744073709551615
  assert_(arrEq(Borsh.serializeU64(18446744073709551615), [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]), "serializeU64(u64::MAX)");

  // deserialize
  assert_(Borsh.deserializeU64([1, 0, 0, 0, 0, 0, 0, 0]) == (1 : Nat64), "deserializeU64(1)");
  assert_(Borsh.deserializeU64([0x40, 0x42, 0x0F, 0x00, 0x00, 0x00, 0x00, 0x00]) == (1_000_000 : Nat64), "deserializeU64(1_000_000)");
};

// ===========================================================================
// u128 (little-endian, 16 bytes)
// ===========================================================================

do {
  // Borsh(0u128) = 16 zero bytes
  assert_(arrEq(Borsh.serializeU128(0), [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]), "serializeU128(0)");

  // Borsh(1u128) = [1, 0 x 15]
  assert_(arrEq(Borsh.serializeU128(1), [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]), "serializeU128(1)");

  // Borsh(256u128) = [0, 1, 0 x 14]
  assert_(arrEq(Borsh.serializeU128(256), [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]), "serializeU128(256)");

  // 1_000_000_000_000_000_000 (1e18) = 0x0DE0B6B3A7640000
  // LE: [0x00, 0x00, 0x64, 0xA7, 0xB3, 0xB6, 0xE0, 0x0D, 0x00 x 8]
  assert_(
    arrEq(
      Borsh.serializeU128(1_000_000_000_000_000_000),
      [0x00, 0x00, 0x64, 0xA7, 0xB3, 0xB6, 0xE0, 0x0D, 0, 0, 0, 0, 0, 0, 0, 0],
    ),
    "serializeU128(1e18)",
  );

  // roundtrip
  assert_(Borsh.deserializeU128([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]) == 1, "deserializeU128(1)");
  assert_(Borsh.deserializeU128([0x00, 0x00, 0x64, 0xA7, 0xB3, 0xB6, 0xE0, 0x0D, 0, 0, 0, 0, 0, 0, 0, 0]) == 1_000_000_000_000_000_000, "deserializeU128(1e18)");
};

// ===========================================================================
// bool
// ===========================================================================

do {
  // Borsh(false) == [0x00]
  assert_(arrEq(Borsh.serializeBool(false), [0x00]), "serializeBool(false)");

  // Borsh(true) == [0x01]
  assert_(arrEq(Borsh.serializeBool(true), [0x01]), "serializeBool(true)");

  // deserialize
  assert_(Borsh.deserializeBool([0x00]) == false, "deserializeBool(false)");
  assert_(Borsh.deserializeBool([0x01]) == true, "deserializeBool(true)");
};

// ===========================================================================
// String (UTF-8, u32 LE length prefix)
// ===========================================================================

do {
  // Borsh("") == [0, 0, 0, 0]  (length 0, no payload)
  assert_(arrEq(Borsh.serializeString(""), [0, 0, 0, 0]), "serializeString(\"\")");

  // Borsh("hello") == [5, 0, 0, 0, 'h', 'e', 'l', 'l', 'o']
  assert_(
    arrEq(
      Borsh.serializeString("hello"),
      [5, 0, 0, 0, 0x68, 0x65, 0x6C, 0x6C, 0x6F],
    ),
    "serializeString(\"hello\")",
  );

  // Borsh("A") == [1, 0, 0, 0, 0x41]
  assert_(arrEq(Borsh.serializeString("A"), [1, 0, 0, 0, 0x41]), "serializeString(\"A\")");

  // Unicode: "ü" is U+00FC → UTF-8: [0xC3, 0xBC], length 2
  assert_(
    arrEq(
      Borsh.serializeString("ü"),
      [2, 0, 0, 0, 0xC3, 0xBC],
    ),
    "serializeString(\"ü\") – UTF-8 multibyte",
  );

  // deserialize roundtrip
  assert_(Borsh.deserializeString([5, 0, 0, 0, 0x68, 0x65, 0x6C, 0x6C, 0x6F]) == "hello", "deserializeString(\"hello\")");
  assert_(Borsh.deserializeString([0, 0, 0, 0]) == "", "deserializeString(\"\")");
  assert_(Borsh.deserializeString([2, 0, 0, 0, 0xC3, 0xBC]) == "ü", "deserializeString(\"ü\")");
};

Debug.print("\n=== All primitive tests passed ===");
