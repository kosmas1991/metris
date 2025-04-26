import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tetris/imports/app_imports.dart';
import '../config/server_config.dart';

class UserService {
  // Fetch user win rate from the API
  static Future<Map<String, dynamic>?> getUserWinRate(
      int userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ServerConfig.apiUrl}/user/winrate/$userId'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          print('Failed to load win rate data: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching win rate: $e');
      }
      return null;
    }
  }
}
