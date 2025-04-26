import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ServerConfig {
  // Base server URL that changes based on debug/release mode
  static String get baseUrl {
    if (kDebugMode) {
      return dotenv.env['SERVER_URL_DEBUG'] ?? 'localhost';
    } else {
      return dotenv.env['SERVER_URL_PROD'] ?? 'tetrisback.kog.gr';
    }
  }

  // For components that need the host and port separately
  static String get host => baseUrl;

  // Port is only used in debug mode
  static int get port => kDebugMode ? 7000 : 443;

  // HTTP API URL (with port for debug, without for production)
  static String get apiUrl {
    if (kDebugMode) {
      return 'http://$baseUrl:7000';
    } else {
      return 'https://$baseUrl';
    }
  }

  // WebSocket URL (with port for debug, without for production)
  static String get wsUrl {
    if (kDebugMode) {
      return 'ws://$baseUrl:7000';
    } else {
      return 'wss://$baseUrl';
    }
  }
}
