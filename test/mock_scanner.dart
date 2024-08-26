import 'dart:async';

import 'package:ad_hoc_ident/ad_hoc_ident.dart';
import 'package:ad_hoc_ident_nfc/ad_hoc_ident_nfc.dart';

class MockScanner implements NfcScanner {
  final _outController = StreamController<AdHocIdentity?>.broadcast();

  int restartCounter = 0;

  void add(AdHocIdentity? value) => _outController.add(value);
  void addError(Object error, [StackTrace? stackTrace]) =>
      _outController.addError(error, stackTrace);

  @override
  AdHocIdentityDetector<NfcTag> get detector => throw UnimplementedError();

  @override
  set detector(AdHocIdentityDetector<NfcTag> value) =>
      throw UnimplementedError();

  @override
  AdHocIdentityEncrypter get encrypter => throw UnimplementedError();

  @override
  set encrypter(AdHocIdentityEncrypter value) => throw UnimplementedError();

  @override
  void close() => _outController.close();

  @override
  Future<bool> isAvailable() => throw UnimplementedError();

  @override
  Future<void> restart() async => restartCounter++;

  @override
  Future<void> start() => throw UnimplementedError();

  @override
  Future<void> stop() => throw UnimplementedError();

  @override
  Stream<AdHocIdentity?> get stream => _outController.stream;
}
