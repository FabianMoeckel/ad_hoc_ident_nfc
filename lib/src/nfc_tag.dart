import 'dart:typed_data';

/// Representation of a native [NfcTag], providing capabilities
/// needed for identity detection.
///
/// Concrete implementations depend on the native NFC implementation.
/// Not all technologies will support all capabilities.
abstract class NfcTag {
  /// A [String] identifying the [NfcTag] in the native system.
  ///
  /// This value is used to identify the tag when referring back to it at
  /// a later time. This can be a physical identity present on the tag or
  /// a newly generated one, such as an UUID.
  final String handle;

  /// The native object representing the [NfcTag].
  ///
  /// This raw value is used to access the native capabilities provided by the
  /// [identifier], [getAt] and [transceive].
  final dynamic raw;

  /// Creates a [NfcTag] from an existing native object.
  ///
  /// Provide a [handle] to identify this [NfcTag] by, and the native object.
  /// The native object is stored in the [raw] value for later access.
  const NfcTag({required this.handle, required this.raw});

  /// The manufacturer-supplied unique identifier.
  ///
  /// Depending on the NFC chip, this identifier might change on each scan.
  Future<Uint8List?> get identifier;

  /// Returns the NFC chip's ATR (Answer To Reset) or ATS (Answer To Select).
  Future<Uint8List?> getAt();

  /// Sends a raw binary command to the NFC chip and reads the response.
  ///
  /// For NFC chips capable of this, the implementation should never
  /// return null. The return type is nullable to allow returning null
  /// if the chip does not support this capability.
  Future<Uint8List?> transceive(Uint8List data);
}
