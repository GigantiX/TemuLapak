import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class Logger {
  static void log(String message) {
    if (kDebugMode) {
      developer.log(message, name: "AxelabsLogger", time: DateTime.now());
    }
  }

  static void error(String message, {Object? error}) {
    if (kDebugMode) {
      developer.log(message,
        error: error, name: "AxelabsLogger", time: DateTime.now(), level: 1000);
    }
  }
}
