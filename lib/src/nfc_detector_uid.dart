import 'dart:async';

import 'package:ad_hoc_ident/ad_hoc_ident.dart';
import 'package:ad_hoc_ident_nfc/ad_hoc_ident_nfc.dart';

/// Exception thrown when a [NfcTag.identifier] is read for the first time.
///
/// This should be handled by restarting the [NfcScanner] after a short,
/// unawaited delay.
class FirstScanException implements Exception {
  /// Evaluates if an object is a [FirstScanException].
  ///
  /// This is a convenience method to use as a test delegate when handling this.
  static bool match(Object? error) => error is FirstScanException;

  /// Returns an error handler restarting the [nfcScanner] after an
  /// unawaited delay.
  ///
  /// The delay is required to allow the nfc scanner to release
  /// the connection to the tag before restarting.
  static void Function(Object error, StackTrace? stackTrace)
      createDefaultHandler(NfcScanner nfcScanner,
          [Duration timeout = const Duration(milliseconds: 200)]) {
    return (error, stackTrace) {
      // Do not await and delay to allow the
      // nfc service to release the connection to the tag before
      // restarting.

      Future.delayed(timeout).then((_) => nfcScanner.restart());
    };
  }

  static const String _defaultMessage =
      "The tag needs to be scanned a second time to ensure its uid is static.";

  /// The message to display.
  final String message;

  /// Creates a new [FirstScanException] with the given [message].
  const FirstScanException([this.message = _defaultMessage]);

  @override
  String toString() {
    return message;
  }
}

/// Detects an [AdHocIdentity] based on the [NfcTag.identifier].
///
/// Depending on its configuration, only a static [NfcTag.identifier] is accepted.
/// If used in a pipeline with other detectors, this should be the first one
/// and the pipeline should be processed sequentially to avoid reapplying
/// other detectors multiple times.
class NfcDetectorUid implements AdHocIdentityDetector<NfcTag> {
  /// The [Duration] for how long the last detected identifier is cached
  /// before resetting the detector.
  ///
  /// For more information see [detect].
  Duration restartTimeout;

  /// The last detected [NfcTag.identifier] value.
  ///
  /// For more information see [detect].
  String? _lastScannedUid;

  /// The timestamp when the last [NfcTag.identifier] value was detected.
  ///
  /// Used to determine if the [_lastScannedUid] should be evaluated or it its
  /// validity expired in reference to the [restartTimeout].
  DateTime _lastScanTime = DateTime.utc(0);

  /// Creates a new [NfcDetectorUid].
  ///
  /// The [restartTimeout] defines how long after a scan the [NfcTag] is cached.
  /// Incoming tags are matched against the cached [NfcTag] to determine if
  /// the tag's UID is static. For more information see [detect].
  /// [FirstScanException]s should be caught and the [NfcScanner] restarted.
  /// Alternatively discard the exception and let the user reintroduce the
  /// [NfcTag] manually.
  NfcDetectorUid({
    this.restartTimeout = const Duration(milliseconds: 1000),
  });

  /// Detects an [AdHocIdentity] based on the UID of the [NfcTag],
  /// attempting to restart the [NfcScanner] in the process.
  ///
  /// Reads the UID of a tag, then throws a [FirstScanException],
  /// if the [restartTimeout] elapsed since the last scan.
  /// If the [restartTimeout] did not elapse,
  /// the read UID will be matched against the result
  /// of the first scan, to determine if the UID is static or if it
  /// changed in between scans.
  @override
  Future<AdHocIdentity?> detect(NfcTag input) async {
    final uid = await _getUidFromTag(input);
    if (uid == null) {
      return null;
    }

    final timestamp = DateTime.timestamp();
    final lastUid = _lastScannedUid;
    final lastScanExpired =
        timestamp.difference(_lastScanTime) > restartTimeout;

    if (lastScanExpired) {
      _lastScannedUid = uid;
      _lastScanTime = timestamp;

      throw FirstScanException();
    }

    final identity = lastUid == uid ? _toIdentity(uid) : null;
    return identity;
  }

  /// Converts the binary [NfcTag.identifier] to a hex [String].
  Future<String?> _getUidFromTag(NfcTag nfcTag) async {
    final uidBytes = await nfcTag.identifier;
    final uid = uidBytes
        ?.map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .reduce((val1, val2) => '$val1:$val2');
    return uid;
  }

  /// Creates an [AdHocIdentity] from the identifier String.
  AdHocIdentity? _toIdentity(String? uid) =>
      uid != null ? AdHocIdentity(type: 'nfc.uid', identifier: uid) : null;
}
