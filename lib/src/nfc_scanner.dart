import 'dart:async';

import 'package:ad_hoc_ident/ad_hoc_ident.dart';
import 'package:ad_hoc_ident_nfc/ad_hoc_ident_nfc.dart';

/// Tries to detect an [AdHocIdentity] from an [NfcTag].
abstract class NfcScanner implements AdHocIdentityScanner<NfcTag> {
  /// Whether NFC is currently available on the system.
  ///
  /// This might return false, if the system does not support NFC at all or
  /// if the user needs to enable NFC manually.
  Future<bool> isAvailable();

  /// Starts listening for NFC tags.
  Future<void> start();

  /// Stops listening for NFC tags.
  Future<void> stop();

  /// Stops and restarts listening for NFC tags.
  ///
  /// If the [NfcScanner] was stopped before and is not running,
  /// this can safely be used to restart the [NfcScanner].
  Future<void> restart();
}

extension FunctionalityWrappers on NfcScanner {
  /// Handles [TException] by executing the [handler].
  ///
  /// This is the intended behavior when using the [NfcDetectorUid].
  NfcScanner handle<TException>(void Function(Object error, StackTrace? stackTrace) handler) {
    return _HandledExceptionNfcScanner<TException>(
      handlerDelegate: handler,
      innerScanner: this,
    );
  }
}

class _HandledExceptionNfcScanner<TException> implements NfcScanner {
  final NfcScanner innerScanner;
  final FutureOr<void> Function(Object error, StackTrace? stackTrace)
      handlerDelegate;

  _HandledExceptionNfcScanner(
      {required this.innerScanner, required this.handlerDelegate});

  @override
  AdHocIdentityDetector<NfcTag> get detector => innerScanner.detector;

  @override
  set detector(AdHocIdentityDetector<NfcTag> value) =>
      innerScanner.detector = value;

  @override
  AdHocIdentityEncrypter get encrypter => innerScanner.encrypter;

  @override
  set encrypter(AdHocIdentityEncrypter value) => innerScanner.encrypter = value;

  @override
  void close() => innerScanner.close();

  @override
  Stream<AdHocIdentity?> get stream => innerScanner.stream.handleError(
        handlerDelegate,
        test: (error) => error is TException,
      );

  @override
  Future<bool> isAvailable() => innerScanner.isAvailable();

  @override
  Future<void> restart() => innerScanner.restart();

  @override
  Future<void> start() => innerScanner.start();

  @override
  Future<void> stop() => innerScanner.stop();
}
