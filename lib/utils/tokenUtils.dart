import 'package:shared_preferences/shared_preferences.dart';

class TokenUtils {
  static Future<String?> getFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }
}