/// Test vectors for Borsh composite type serialization / deserialization.
/// Covers: Vec<T>, fixed-size arrays, Option<T>, Result<Ok,Err>, tuples.
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
// Vec<u8>  —  u32 LE length prefix + raw bytes
// ===========================================================================

do {
  // Empty vector: Borsh(Vec::<u8>::new()) == [0, 0, 0, 0]
  let empty = Borsh.serializeVector<Nat8>([], Borsh.serializeU8);
  assert_(arrEq(empty, [0, 0, 0, 0]), "serializeVector<u8>(empty)");

  // Vec [1, 2, 3]: length 3 + bytes
  // == [3, 0, 0, 0, 1, 2, 3]
  let v123 = Borsh.serializeVector<Nat8>([1, 2, 3], Borsh.serializeU8);
  assert_(arrEq(v123, [3, 0, 0, 0, 1, 2, 3]), "serializeVector<u8>([1,2,3])");

  // Single element
  let v42 = Borsh.serializeVector<Nat8>([42], Borsh.serializeU8);
  assert_(arrEq(v42, [1, 0, 0, 0, 42]), "serializeVector<u8>([42])");
};

// ===========================================================================
// Vec<u32>  —  4-byte length prefix + each element is 4 bytes LE
// ===========================================================================

do {
  // Vec [1u32, 2u32] == [2, 0, 0, 0,   1, 0, 0, 0,   2, 0, 0, 0]
  let v = Borsh.serializeVector<Nat32>([1, 2], Borsh.serializeU32);
  assert_(arrEq(v, [2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0]), "serializeVector<u32>([1,2])");
};

// ===========================================================================
// Deserialize Vec<u8>
// ===========================================================================

do {
  let result = Borsh.deserializeVector<Nat8>(
    [3, 0, 0, 0, 10, 20, 30],
    func(r : Borsh.Reader) : Nat8 { r.readU8() },
  );
  assert_(result.size() == 3, "deserializeVector<u8> length");
  assert_(result[0] == 10, "deserializeVector<u8>[0]");
  assert_(result[1] == 20, "deserializeVector<u8>[1]");
  assert_(result[2] == 30, "deserializeVector<u8>[2]");
};

// ===========================================================================
// Fixed array [u8; 3]  —  no length prefix
// ===========================================================================

do {
  let fixed = Borsh.serializeFixedArray<Nat8>([0xAA, 0xBB, 0xCC], Borsh.serializeU8);
  assert_(arrEq(fixed, [0xAA, 0xBB, 0xCC]), "serializeFixedArray<u8>([0xAA,0xBB,0xCC])");

  // Deserialize
  let result = Borsh.deserializeFixedArray<Nat8>(
    [0xAA, 0xBB, 0xCC],
    3,
    func(r : Borsh.Reader) : Nat8 { r.readU8() },
  );
  assert_(arrEq(result, [0xAA, 0xBB, 0xCC]), "deserializeFixedArray<u8>");
};

// ===========================================================================
// Option<u8>
// ===========================================================================

do {
  // None → [0]
  let none = Borsh.serializeOption<Nat8>(null, Borsh.serializeU8);
  assert_(arrEq(none, [0]), "serializeOption<u8>(None)");

  // Some(5) → [1, 5]
  let some5 = Borsh.serializeOption<Nat8>(?5, Borsh.serializeU8);
  assert_(arrEq(some5, [1, 5]), "serializeOption<u8>(Some(5))");

  // Some(0) → [1, 0]
  let some0 = Borsh.serializeOption<Nat8>(?0, Borsh.serializeU8);
  assert_(arrEq(some0, [1, 0]), "serializeOption<u8>(Some(0))");

  // Deserialize None
  let rNone = Borsh.deserializeOption<Nat8>(
    [0],
    func(r : Borsh.Reader) : Nat8 { r.readU8() },
  );
  assert_(rNone == null, "deserializeOption<u8>(None)");

  // Deserialize Some(5)
  let rSome = Borsh.deserializeOption<Nat8>(
    [1, 5],
    func(r : Borsh.Reader) : Nat8 { r.readU8() },
  );
  switch (rSome) {
    case (?v) assert_(v == 5, "deserializeOption<u8>(Some(5)) value");
    case null { Runtime.trap("Expected Some(5)") };
  };
};

// ===========================================================================
// Option<u32>
// ===========================================================================

do {
  // Some(256u32) → [1, 0, 1, 0, 0]
  let s256 = Borsh.serializeOption<Nat32>(?256, Borsh.serializeU32);
  assert_(arrEq(s256, [1, 0, 1, 0, 0]), "serializeOption<u32>(Some(256))");

  // None → [0]
  let none = Borsh.serializeOption<Nat32>(null, Borsh.serializeU32);
  assert_(arrEq(none, [0]), "serializeOption<u32>(None)");
};

// ===========================================================================
// Result<u8, u8>  —  Borsh uses 0=Err, 1=Ok (note: NOT the other way!)
//   Actually looking at the impl: #ok → tag 1, #err → tag 0
// ===========================================================================

do {
  // Ok(7) → [1, 7]
  let ok7 = Borsh.serializeResult<Nat8, Nat8>(
    #ok(7),
    Borsh.serializeU8,
    Borsh.serializeU8,
  );
  assert_(arrEq(ok7, [1, 7]), "serializeResult Ok(7)");

  // Err(3) → [0, 3]
  let err3 = Borsh.serializeResult<Nat8, Nat8>(
    #err(3),
    Borsh.serializeU8,
    Borsh.serializeU8,
  );
  assert_(arrEq(err3, [0, 3]), "serializeResult Err(3)");

  // Deserialize Ok
  let rOk = Borsh.deserializeResult<Nat8, Nat8>(
    [1, 7],
    func(r : Borsh.Reader) : Nat8 { r.readU8() },
    func(r : Borsh.Reader) : Nat8 { r.readU8() },
  );
  switch (rOk) {
    case (#ok v) assert_(v == 7, "deserializeResult Ok value");
    case (#err _) { Runtime.trap("Expected Ok") };
  };

  // Deserialize Err
  let rErr = Borsh.deserializeResult<Nat8, Nat8>(
    [0, 3],
    func(r : Borsh.Reader) : Nat8 { r.readU8() },
    func(r : Borsh.Reader) : Nat8 { r.readU8() },
  );
  switch (rErr) {
    case (#err e) assert_(e == 3, "deserializeResult Err value");
    case (#ok _) { Runtime.trap("Expected Err") };
  };
};

// ===========================================================================
// Tuple2 (u8, u16)
// ===========================================================================

do {
  // (5u8, 256u16) → [5, 0, 1]
  let t = Borsh.serializeTuple2<Nat8, Nat16>(
    (5, 256),
    Borsh.serializeU8,
    Borsh.serializeU16,
  );
  assert_(arrEq(t, [5, 0, 1]), "serializeTuple2(5u8, 256u16)");
};

// ===========================================================================
// Tuple3 (u8, u8, u32)
// ===========================================================================

do {
  // (1u8, 2u8, 1u32) → [1, 2, 1, 0, 0, 0]
  let t = Borsh.serializeTuple3<Nat8, Nat8, Nat32>(
    (1, 2, 1),
    Borsh.serializeU8,
    Borsh.serializeU8,
    Borsh.serializeU32,
  );
  assert_(arrEq(t, [1, 2, 1, 0, 0, 0]), "serializeTuple3(1u8, 2u8, 1u32)");
};

// ===========================================================================
// Nested: Vec<Option<u8>>
// ===========================================================================

do {
  // [Some(1), None, Some(255)]
  // length prefix: [3, 0, 0, 0]
  // Some(1): [1, 1]
  // None:    [0]
  // Some(255): [1, 0xFF]
  // total: [3, 0, 0, 0, 1, 1, 0, 1, 0xFF]
  let v = Borsh.serializeVector<?Nat8>(
    [?1, null, ?255],
    func(opt : ?Nat8) : [Nat8] {
      Borsh.serializeOption<Nat8>(opt, Borsh.serializeU8);
    },
  );
  assert_(arrEq(v, [3, 0, 0, 0, 1, 1, 0, 1, 0xFF]), "serializeVector<Option<u8>>([Some(1), None, Some(255)])");
};

Debug.print("\n=== All composite tests passed ===");
