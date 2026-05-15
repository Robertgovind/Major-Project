import 'package:flutter/foundation.dart';

class ApiConfig {
  static const int port = 5000;
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _configuredWebsocketUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: '',
  );
  static const String _configuredHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '',
  );

  static String get _defaultHost {
    if (_configuredHost.isNotEmpty) return _configuredHost;
    if (kIsWeb) return 'localhost';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'localhost';
    }
  }

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }

    return 'http://$_defaultHost:$port';
  }

  static String get websocketUrl {
    if (_configuredWebsocketUrl.isNotEmpty) return _configuredWebsocketUrl;

    final wsBase = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');

    return '$wsBase/ws';
  }
}
