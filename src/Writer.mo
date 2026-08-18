/// Borsh Writer - Serializes data into Borsh format.
///
/// All multi-byte integers are written in little-endian format.
/// This is a low-level core; higher-level helpers (Vec, String, Option, etc.)
/// are built on top of this in `lib.mo`.

import VarArray "mo:core/VarArray";
import Runtime "mo:core/Runtime";
import Nat8 "mo:core/Nat8";
import Nat16 "mo:core/Nat16";
import Nat32 "mo:core/Nat32";
import Nat64 "mo:core/Nat64";
import List "mo:core/List";
import Array "mo:core/Array";

module {
  public class Writer() {
    private let buffer = List.empty<Nat8>();

    /// Write a single byte (u8)
    public func writeU8(value : Nat8) {
      List.add(buffer, value);
    };

    /// Write a 16-bit unsigned integer in little-endian
    public func writeU16Le(value : Nat16) {
      let v = Nat16.toNat(value);
      List.add(buffer, Nat8.fromNat(v % 256));
      List.add(buffer, Nat8.fromNat(v / 256));
    };

    /// Write a 32-bit unsigned integer in little-endian
    public func writeU32Le(value : Nat32) {
      let v = value;
      List.add(buffer, Nat8.fromNat(Nat32.toNat((v >> 0) & 0xFF)));
      List.add(buffer, Nat8.fromNat(Nat32.toNat((v >> 8) & 0xFF)));
      List.add(buffer, Nat8.fromNat(Nat32.toNat((v >> 16) & 0xFF)));
      List.add(buffer, Nat8.fromNat(Nat32.toNat((v >> 24) & 0xFF)));
    };

    /// Write a 64-bit unsigned integer in little-endian
    public func writeU64Le(value : Nat64) {
      let bytes = toLittleEndian64(value);
      for (byte in bytes.values()) {
        List.add(buffer, byte);
      };
    };

    /// Write a 128-bit unsigned integer in little-endian
    /// (Borsh's u128 support)
    public func writeU128Le(value : Nat) {
      let bytes = toLittleEndian(value, 16);
      for (byte in bytes.values()) {
        List.add(buffer, byte);
      };
    };

    /// Convenience: write a boolean (false = 0, true = 1)
    public func writeBool(value : Bool) {
      if (value) {
        writeU8(1);
      } else {
        writeU8(0);
      };
    };

    /// Convenience: write a Borsh length prefix (u32 little-endian)
    public func writeU32Len(len : Nat) {
      if (len > 4294967295) {
        Runtime.trap("Borsh Writer: length exceeds u32 range");
      };
      let v32 = Nat32.fromNat(len);
      writeU32Le(v32);
    };

    /// Write raw bytes
    public func writeBytes(bytes : [Nat8]) {
      for (byte in bytes.values()) {
        List.add(buffer, byte);
      };
    };

    /// Get the serialized bytes
    public func toBytes() : [Nat8] {
      List.toArray(buffer);
    };

    /// Current size of the buffer
    public func size() : Nat {
      List.size(buffer);
    };

    /// Clear the buffer
    public func clear() {
      List.clear(buffer);
    };

    // === helpers ===

    // Convert Nat64 to little-endian bytes
    private func toLittleEndian64(value : Nat64) : [Nat8] {
      let result = VarArray.repeat<Nat8>(0, 8);
      var v = value;
      var i = 0;

      while (i < 8) {
        result[i] := Nat8.fromNat(Nat64.toNat(v & 0xFF));
        v := v >> 8;
        i += 1;
      };

      Array.fromVarArray(result);
    };

    // Convert Nat to little-endian bytes with fixed size
    private func toLittleEndian(value : Nat, size : Nat) : [Nat8] {
      let result = VarArray.repeat<Nat8>(0, size);
      var v = value;
      var i = 0;

      while (i < size) {
        result[i] := Nat8.fromNat(v % 256);
        v := v / 256;
        i += 1;
      };

      Array.fromVarArray(result);
    };
  };
};
