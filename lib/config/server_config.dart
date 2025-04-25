import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ServerConfig {
  // Base server URL that changes based on debug/release mode
  static String get baseUrl {
    if (kDebugMode) {
      return dotenv.env['SERVER_URL_DEBUG'] ?? 'localhost';
    } else {
      return dotenv.env['SERVER_URL_PROD'] ?? 'kog.gr';
    }
  }

  // For components that need the host and port separately
  static String get host => baseUrl;
  static int get port => 8000;

  // HTTP API URL (with port)
  static String get apiUrl => 'http://$baseUrl:8000';

  // WebSocket URL (with port)
  static String get wsUrl => 'ws://$baseUrl:8000';
}
