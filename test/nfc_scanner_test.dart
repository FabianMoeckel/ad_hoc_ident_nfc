import 'dart:async';

import 'package:ad_hoc_ident/ad_hoc_ident.dart';
import 'package:ad_hoc_ident_nfc/ad_hoc_ident_nfc.dart';
import 'package:test/test.dart';

import 'mock_scanner.dart';

void main() {
  test('handle FirstScanException by extension method', () async {
    final mock = MockScanner();

    final wrappedScanner = mock.handle<FirstScanException>(
        FirstScanException.createDefaultHandler(mock));

    final receivedCompleter = Completer<AdHocIdentity?>();

    int errorCounter = 0;
    wrappedScanner.stream
        .handleError((error) => errorCounter++)
        .listen((identity) => receivedCompleter.complete(identity));

    mock.addError(FirstScanException());
    mock.add(null);
    mock.close();

    final result =
        await receivedCompleter.future.timeout(Duration(milliseconds: 200));

    // Wait for the delay the handler uses before restarting
    await Future.delayed(Duration(milliseconds: 200));

    expect(errorCounter, 0);
    expect(result, null);
    expect(mock.restartCounter, 1);
  });
}
