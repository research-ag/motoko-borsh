/// Borsh Reader - Deserializes data from Borsh format.
///
/// All multi-byte integers are read in little-endian format.
/// This is a low-level core; higher-level helpers (Vec, String, Option, etc.)
/// are built on top of this in `lib.mo`.

import Runtime "mo:core/Runtime";
import Nat8 "mo:core/Nat8";
import Nat16 "mo:core/Nat16";
import Nat32 "mo:core/Nat32";
import Nat64 "mo:core/Nat64";
import Array "mo:core/Array";

module {
  public class Reader(data : [Nat8]) {
    private var position : Nat = 0;
    private let bytes = data;

    /// Current cursor position
    public func getPosition() : Nat {
      position;
    };

    /// Whether more bytes are available
    public func hasMore() : Bool {
      position < bytes.size();
    };

    /// Shift the cursor forward by `count` bytes
    public func shift(count : Nat) {
      position += count;
    };

    /// Read a single byte (u8)
    public func readU8() : Nat8 {
      if (position >= bytes.size()) {
        Runtime.trap("Borsh Reader: buffer overflow");
      };
      let value = bytes[position];
      position += 1;
      value;
    };

    /// Read a 16-bit unsigned integer in little-endian
    public func readU16Le() : Nat16 {
      let b1 = Nat16.fromNat(Nat8.toNat(readU8()));
      let b2 = Nat16.fromNat(Nat8.toNat(readU8()));
      b1 | (b2 << 8);
    };

    /// Read a 32-bit unsigned integer in little-endian
    public func readU32Le() : Nat32 {
      let b1 = Nat32.fromNat(Nat8.toNat(readU8()));
      let b2 = Nat32.fromNat(Nat8.toNat(readU8()));
      let b3 = Nat32.fromNat(Nat8.toNat(readU8()));
      let b4 = Nat32.fromNat(Nat8.toNat(readU8()));
      b1 | (b2 << 8) | (b3 << 16) | (b4 << 24);
    };

    /// Read a 64-bit unsigned integer in little-endian
    public func readU64Le() : Nat64 {
      var result : Nat64 = 0;
      var shift : Nat64 = 0;

      var i = 0;
      while (i < 8) {
        let byte = Nat64.fromNat(Nat8.toNat(readU8()));
        result := result | (byte << shift);
        shift += 8;
        i += 1;
      };

      result;
    };

    /// Read a 128-bit unsigned integer in little-endian (returns Nat)
    public func readU128Le() : Nat {
      var result : Nat = 0;
      var multiplier : Nat = 1;

      var i = 0;
      while (i < 16) {
        let byte = Nat8.toNat(readU8());
        result += byte * multiplier;
        multiplier *= 256;
        i += 1;
      };

      result;
    };

    /// Convenience: read a Borsh length prefix (u32 little-endian)
    public func readU32Len() : Nat {
      let len32 = readU32Le();
      Nat32.toNat(len32);
    };

    /// Convenience: read a boolean encoded as 0 or 1
    public func readBool() : Bool {
      let b = readU8();
      if (b == 0) {
        false;
      } else if (b == 1) {
        true;
      } else {
        Runtime.trap("Borsh Reader: invalid bool value (must be 0 or 1)");
      };
    };

    /// Read a specific number of bytes
    public func readBytes(count : Nat) : [Nat8] {
      if (position + count > bytes.size()) {
        Runtime.trap("Borsh Reader: buffer overflow - not enough bytes");
      };

      let result = Array.tabulate<Nat8>(
        count,
        func(i) { bytes[position + i] },
      );
      position += count;
      result;
    };

    /// Read all remaining bytes
    public func readRemainingBytes() : [Nat8] {
      readBytes(bytes.size() - position);
    };
  };
};
