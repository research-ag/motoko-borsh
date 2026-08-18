/// Borsh trait / interface types.
///
/// These type aliases describe the shape of the serialization and
/// deserialization callbacks used throughout the public Borsh API.
/// Encoding a value to bytes is a pure function `T -> [Nat8]`; decoding
/// pulls a value out of a stateful `Reader` cursor.

import WriterModule "./Writer";
import ReaderModule "./Reader";

module {
  /// Stateful little-endian byte accumulator.
  public type Writer = WriterModule.Writer;

  /// Stateful cursor-based binary parser with bounds safety.
  public type Reader = ReaderModule.Reader;

  /// Pure serializer: encodes a value of type `T` into Borsh bytes.
  public type Serialize<T> = (T) -> [Nat8];

  /// Deserializer: reads a value of type `T` from a `Reader` cursor.
  public type Deserialize<T> = (Reader) -> T;

  /// In-place serializer: writes a value of type `T` into a `Writer`.
  public type WriteInto<T> = (T, Writer) -> ();
};
