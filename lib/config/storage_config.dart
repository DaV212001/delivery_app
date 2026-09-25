import 'package:shared_preferences/shared_preferences.dart';

class ConfigPreference {
  static late SharedPreferences sharedPreferencesInstance;

  static Future<void> init() async {
    sharedPreferencesInstance = await SharedPreferences.getInstance();
  }

  static String? getAccessToken() =>
      sharedPreferencesInstance.getString('access_token');

  static String? getRefreshToken() =>
      sharedPreferencesInstance.getString('refresh_token');

  static bool isAccessTokenExpired() {
    final expiry = sharedPreferencesInstance.getInt('access_token_expiry');
    return expiry == null || DateTime.now().millisecondsSinceEpoch > expiry;
  }

  static Future<void> updateTokens(
    String accessToken,
    String refreshToken,
    int expiresIn,
  ) async {
    final expiry = DateTime.now()
        .add(Duration(seconds: expiresIn))
        .millisecondsSinceEpoch;
    await sharedPreferencesInstance.setString('access_token', accessToken);
    await sharedPreferencesInstance.setString('refresh_token', refreshToken);
    await sharedPreferencesInstance.setInt('access_token_expiry', expiry);
  }

  static Future<void> clearTokens() async {
    await sharedPreferencesInstance.remove('access_token');
    await sharedPreferencesInstance.remove('refresh_token');
    await sharedPreferencesInstance.remove('access_token_expiry');
    await sharedPreferencesInstance.remove('user_id');
    await sharedPreferencesInstance.remove('user_name');
    await sharedPreferencesInstance.remove('user_phone');
    if (!getRememberMe()) {
      await sharedPreferencesInstance.remove('user_email');
    }
  }

  // User credentials & identity persistence
  static int? getUserId() =>
      sharedPreferencesInstance.getInt('user_id');

  static Future<void> setUserId(int id) async {
    await sharedPreferencesInstance.setInt('user_id', id);
  }

  static String? getUserPhone() =>
      sharedPreferencesInstance.getString('user_phone');

  static Future<void> setUserPhone(String phone) async {
    await sharedPreferencesInstance.setString('user_phone', phone);
  }

  static String? getUserName() =>
      sharedPreferencesInstance.getString('user_name');

  static Future<void> setUserName(String name) async {
    await sharedPreferencesInstance.setString('user_name', name);
  }
  static String? getUserEmail() =>
      sharedPreferencesInstance.getString('user_email');

  static Future<void> setUserEmail(String email) async {
    await sharedPreferencesInstance.setString('user_email', email);
  }

  static bool getRememberMe() =>
      sharedPreferencesInstance.getBool('remember_me') ?? true;

  static Future<void> setRememberMe(bool remember) async {
    await sharedPreferencesInstance.setBool('remember_me', remember);
  }

  // Theme preference
  static bool isDarkMode() =>
      sharedPreferencesInstance.getBool('is_dark_mode') ?? false;

  static Future<void> setDarkMode(bool isDark) async {
    await sharedPreferencesInstance.setBool('is_dark_mode', isDark);
  }

  // Language preference
  static String getLanguage() =>
      sharedPreferencesInstance.getString('language_code') ?? 'en';

  static Future<void> setLanguage(String langCode) async {
    await sharedPreferencesInstance.setString('language_code', langCode);
  }
}
