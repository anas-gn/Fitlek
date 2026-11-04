import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Transport failures only: HTTP rejections and invalid content are not offline.
class ConnectionRecovery {
  static final failure = ValueNotifier<String?>(null);
  static final _refreshes = StreamController<void>.broadcast();
  static Stream<void> get refreshes => _refreshes.stream;
  static const message =
      'Your connection may be weak or interrupted, or the server may be temporarily unavailable. Check your Wi-Fi or mobile data, then try again.';

  static bool report(Object error) {
    if (error is! http.ClientException && error is! TimeoutException) {
      return false;
    }
    failure.value = message;
    return true;
  }

  static void refreshApp() {
    failure.value = null;
    _refreshes.add(null);
  }
}
