import 'package:flutter/foundation.dart';

class ApiConfig {
  static const int port = 5000;

  // Android emulator reaches your computer through 10.0.2.2.
  // For a physical phone, run Flutter with:
  // --dart-define=API_HOST=your-computer-lan-ip
  static const String host = String.fromEnvironment(
    'API_HOST',
    defaultValue: '10.0.2.2',
  );

  static String get baseUrl {
    final resolvedHost = kIsWeb ? 'localhost' : host;
    return 'http://$resolvedHost:$port';
  }

  static String get websocketUrl {
    final resolvedHost = kIsWeb ? 'localhost' : host;
    return 'ws://$resolvedHost:$port/ws';
  }
}
