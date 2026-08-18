/// Pure-Motoko Borsh binary codec.
///
/// Borsh (Binary Object Representation Serializer for Hashing) is the standard
/// binary serialization format used by Solana, NEAR and various cryptographic
/// systems. This module exposes a small, allocation-friendly encode/decode API
/// built on top of the low-level `Writer` and `Reader`.
///
/// All multi-byte integers are little-endian. Strings are UTF-8 with a `u32`
/// little-endian length prefix. Vectors are length-prefixed; fixed arrays are
/// not.
///
/// Main author: Menese contributors

import Runtime "mo:core/Runtime";
import Nat8 "mo:core/Nat8";
import Text "mo:core/Text";
import Blob "mo:core/Blob";
import Array "mo:core/Array";

import WriterModule "./Writer";
import ReaderModule "./Reader";
import Types "./Types";

module {

  public type Writer = WriterModule.Writer;
  public type Reader = ReaderModule.Reader;

  public type Serialize<T> = Types.Serialize<T>;
  public type Deserialize<T> = Types.Deserialize<T>;
  public type WriteInto<T> = Types.WriteInto<T>;

  public func Writer() : Writer {
    WriterModule.Writer();
  };

  public func Reader(bytes : [Nat8]) : Reader {
    ReaderModule.Reader(bytes);
  };

  // ===========================================================================
  // PRIMITIVE TYPES - Serialization
  // ===========================================================================

  public func serializeU8(v : Nat8) : [Nat8] { [v] };

  public func serializeU16(v : Nat16) : [Nat8] {
    let w = Writer();
    w.writeU16Le(v);
    w.toBytes();
  };

  public func serializeU32(v : Nat32) : [Nat8] {
    let w = Writer();
    w.writeU32Le(v);
    w.toBytes();
  };

  public func serializeU64(v : Nat64) : [Nat8] {
    let w = Writer();
    w.writeU64Le(v);
    w.toBytes();
  };

  public func serializeU128(v : Nat) : [Nat8] {
    let w = Writer();
    w.writeU128Le(v);
    w.toBytes();
  };

  public func serializeBool(b : Bool) : [Nat8] {
    let w = Writer();
    w.writeBool(b);
    w.toBytes();
  };

  /// raw bytes (no length prefix)
  public func serializeBytes(bytes : [Nat8]) : [Nat8] {
    bytes;
  };

  /// Borsh string: UTF-8, length-prefixed with u32 LE
  public func serializeString(t : Text) : [Nat8] {
    let blob = Text.encodeUtf8(t);
    let bytes = Blob.toArray(blob);
    let w = Writer();
    w.writeU32Len(bytes.size());
    w.writeBytes(bytes);
    w.toBytes();
  };

  // ===========================================================================
  // PRIMITIVE TYPES - Deserialization
  // ===========================================================================

  public func deserializeU8(bytes : [Nat8]) : Nat8 {
    let r = Reader(bytes);
    r.readU8();
  };

  public func deserializeU16(bytes : [Nat8]) : Nat16 {
    let r = Reader(bytes);
    r.readU16Le();
  };

  public func deserializeU32(bytes : [Nat8]) : Nat32 {
    let r = Reader(bytes);
    r.readU32Le();
  };

  public func deserializeU64(bytes : [Nat8]) : Nat64 {
    let r = Reader(bytes);
    r.readU64Le();
  };

  public func deserializeU128(bytes : [Nat8]) : Nat {
    let r = Reader(bytes);
    r.readU128Le();
  };

  public func deserializeBool(bytes : [Nat8]) : Bool {
    let r = Reader(bytes);
    r.readBool();
  };

  public func deserializeString(bytes : [Nat8]) : Text {
    let r = Reader(bytes);
    let len = r.readU32Len();
    let strBytes = r.readBytes(len);
    let blob = Blob.fromArray(strBytes);
    switch (Text.decodeUtf8(blob)) {
      case (?t) t;
      case null Runtime.trap("Borsh: invalid UTF-8");
    };
  };

  // ===========================================================================
  // COMPOSITE TYPES - Serialization
  // ===========================================================================

  /// Vec<T>: u32 length + elements
  public func serializeVector<T>(
    values : [T],
    serializeElem : (T) -> [Nat8],
  ) : [Nat8] {
    let w = Writer();
    w.writeU32Len(values.size());
    for (v in values.values()) {
      w.writeBytes(serializeElem(v));
    };
    w.toBytes();
  };

  /// Fixed-size array [T; N]: just elements, no length prefix
  public func serializeFixedArray<T>(
    values : [T],
    serializeElem : (T) -> [Nat8],
  ) : [Nat8] {
    let w = Writer();
    for (v in values.values()) {
      w.writeBytes(serializeElem(v));
    };
    w.toBytes();
  };

  /// Option<T>: 0 = None, 1 = Some(value)
  public func serializeOption<T>(
    value : ?T,
    serializeElem : (T) -> [Nat8],
  ) : [Nat8] {
    let w = Writer();
    switch (value) {
      case null {
        w.writeU8(0);
      };
      case (?v) {
        w.writeU8(1);
        w.writeBytes(serializeElem(v));
      };
    };
    w.toBytes();
  };

  /// Result<Ok, Err>: 0 = Err, 1 = Ok (matches Rust impl)
  public func serializeResult<Ok, Err>(
    value : { #ok : Ok; #err : Err },
    serializeOk : (Ok) -> [Nat8],
    serializeErr : (Err) -> [Nat8],
  ) : [Nat8] {
    let w = Writer();
    switch (value) {
      case (#ok v) {
        w.writeU8(1);
        w.writeBytes(serializeOk(v));
      };
      case (#err e) {
        w.writeU8(0);
        w.writeBytes(serializeErr(e));
      };
    };
    w.toBytes();
  };

  /// (T1, T2)
  public func serializeTuple2<T1, T2>(
    v : (T1, T2),
    s1 : (T1) -> [Nat8],
    s2 : (T2) -> [Nat8],
  ) : [Nat8] {
    let w = Writer();
    w.writeBytes(s1(v.0));
    w.writeBytes(s2(v.1));
    w.toBytes();
  };

  /// (T1, T2, T3)
  public func serializeTuple3<T1, T2, T3>(
    v : (T1, T2, T3),
    s1 : (T1) -> [Nat8],
    s2 : (T2) -> [Nat8],
    s3 : (T3) -> [Nat8],
  ) : [Nat8] {
    let w = Writer();
    w.writeBytes(s1(v.0));
    w.writeBytes(s2(v.1));
    w.writeBytes(s3(v.2));
    w.toBytes();
  };

  // ===========================================================================
  // COMPOSITE TYPES - Deserialization
  // ===========================================================================

  public func deserializeVector<T>(
    bytes : [Nat8],
    deserializeElem : (Reader) -> T,
  ) : [T] {
    let r = Reader(bytes);
    let len = r.readU32Len();
    Array.tabulate<T>(
      len,
      func(_) { deserializeElem(r) },
    );
  };

  public func deserializeFixedArray<T>(
    bytes : [Nat8],
    size : Nat,
    deserializeElem : (Reader) -> T,
  ) : [T] {
    let r = Reader(bytes);
    Array.tabulate<T>(
      size,
      func(_) { deserializeElem(r) },
    );
  };

  public func deserializeOption<T>(
    bytes : [Nat8],
    deserializeElem : (Reader) -> T,
  ) : ?T {
    let r = Reader(bytes);
    let tag = r.readU8();
    if (tag == 0) {
      null;
    } else if (tag == 1) {
      ?deserializeElem(r);
    } else {
      Runtime.trap("Borsh: invalid Option tag");
    };
  };

  public func deserializeResult<Ok, Err>(
    bytes : [Nat8],
    deserializeOk : (Reader) -> Ok,
    deserializeErr : (Reader) -> Err,
  ) : { #ok : Ok; #err : Err } {
    let r = Reader(bytes);
    let tag = r.readU8();
    if (tag == 1) {
      #ok(deserializeOk(r));
    } else if (tag == 0) {
      #err(deserializeErr(r));
    } else {
      Runtime.trap("Borsh: invalid Result tag");
    };
  };

  public func deserializeTuple2<T1, T2>(
    bytes : [Nat8],
    d1 : (Reader) -> T1,
    d2 : (Reader) -> T2,
  ) : (T1, T2) {
    let r = Reader(bytes);
    let v1 = d1(r);
    let v2 = d2(r);
    (v1, v2);
  };

  public func deserializeTuple3<T1, T2, T3>(
    bytes : [Nat8],
    d1 : (Reader) -> T1,
    d2 : (Reader) -> T2,
    d3 : (Reader) -> T3,
  ) : (T1, T2, T3) {
    let r = Reader(bytes);
    let v1 = d1(r);
    let v2 = d2(r);
    let v3 = d3(r);
    (v1, v2, v3);
  };

  /// Generic "serialize with Writer"
  public func toBytes<T>(
    value : T,
    serialize : (T, Writer) -> (),
  ) : [Nat8] {
    let w = Writer();
    serialize(value, w);
    w.toBytes();
  };

  /// Generic "deserialize with Reader", requires full consumption
  public func fromBytes<T>(
    bytes : [Nat8],
    deserialize : (Reader) -> T,
  ) : T {
    let r = Reader(bytes);
    let value = deserialize(r);
    if (r.hasMore()) {
      Runtime.trap("Borsh: extra bytes remaining after deserialize");
    };
    value;
  };

  public func newWriter() : Writer {
    Writer();
  };

  public func newReader(bytes : [Nat8]) : Reader {
    Reader(bytes);
  };

  public func toHex(bytes : [Nat8]) : Text {
    var result = "";
    for (b in bytes.values()) {
      result #= byteToHex(b);
    };
    result;
  };

  private func byteToHex(byte : Nat8) : Text {
    // prettier-ignore
    let chars = [
      "0", "1", "2", "3", "4", "5", "6", "7",
      "8", "9", "a", "b", "c", "d", "e", "f",
    ];
    let high = Nat8.toNat(byte / 16);
    let low = Nat8.toNat(byte % 16);
    chars[high] # chars[low];
  };
};
