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
    await sharedPreferencesInstance.remove('user_avatar');
    await sharedPreferencesInstance.remove('user_type');
    await sharedPreferencesInstance.remove('user_company_id');
    await sharedPreferencesInstance.remove('user_branch_id');
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

  static String? getUserAvatar() =>
      sharedPreferencesInstance.getString('user_avatar');

  static Future<void> setUserAvatar(String url) async {
    await sharedPreferencesInstance.setString('user_avatar', url);
  }

  static String? getUserType() =>
      sharedPreferencesInstance.getString('user_type');

  static Future<void> setUserType(String type) async {
    await sharedPreferencesInstance.setString('user_type', type);
  }

  static String? getUserCompanyId() =>
      sharedPreferencesInstance.getString('user_company_id');

  static Future<void> setUserCompanyId(String companyId) async {
    await sharedPreferencesInstance.setString('user_company_id', companyId);
  }

  static String? getUserBranchId() =>
      sharedPreferencesInstance.getString('user_branch_id');

  static Future<void> setUserBranchId(String branchId) async {
    await sharedPreferencesInstance.setString('user_branch_id', branchId);
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

  // Favorite stores persistence
  static List<String> getFavorites() =>
      sharedPreferencesInstance.getStringList('favorite_store_ids') ?? [];

  static Future<void> setFavorites(List<String> ids) async {
    await sharedPreferencesInstance.setStringList('favorite_store_ids', ids);
  }

  // User location persistence
  static double? getUserLatitude() =>
      sharedPreferencesInstance.getDouble('user_latitude');

  static double? getUserLongitude() =>
      sharedPreferencesInstance.getDouble('user_longitude');

  static Future<void> setUserLocation(double lat, double lng) async {
    await sharedPreferencesInstance.setDouble('user_latitude', lat);
    await sharedPreferencesInstance.setDouble('user_longitude', lng);
  }

  static String? getUserAddress() =>
      sharedPreferencesInstance.getString('user_address');

  static Future<void> setUserAddress(String address) async {
    await sharedPreferencesInstance.setString('user_address', address);
  }

  static Future<void> clearUserLocation() async {
    await sharedPreferencesInstance.remove('user_latitude');
    await sharedPreferencesInstance.remove('user_longitude');
    await sharedPreferencesInstance.remove('user_address');
  }

  static bool get isInitialized {
    try {
      sharedPreferencesInstance;
      return true;
    } catch (_) {
      return false;
    }
  }

  // Cart items & batches persistence
  static String? getActiveCartJson() {
    if (!isInitialized) return null;
    return sharedPreferencesInstance.getString('active_cart_items');
  }

  static Future<void> setActiveCartJson(String json) async {
    if (!isInitialized) return;
    await sharedPreferencesInstance.setString('active_cart_items', json);
  }

  static Future<void> clearActiveCartJson() async {
    if (!isInitialized) return;
    await sharedPreferencesInstance.remove('active_cart_items');
  }

  static String? getSavedCartBatchesJson() {
    if (!isInitialized) return null;
    return sharedPreferencesInstance.getString('saved_cart_batches');
  }

  static Future<void> setSavedCartBatchesJson(String json) async {
    if (!isInitialized) return;
    await sharedPreferencesInstance.setString('saved_cart_batches', json);
  }

  static Future<void> clearSavedCartBatchesJson() async {
    if (!isInitialized) return;
    await sharedPreferencesInstance.remove('saved_cart_batches');
  }
}
