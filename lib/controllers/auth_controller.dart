import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/storage_config.dart';
import '../constants/pages.dart';
import '../controllers/profile_controller.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../utils/api_call_status.dart';

class AuthController extends GetxController {
  final _isLoggedIn = false.obs;
  bool get isLoggedIn => _isLoggedIn.value;
  bool get isGuest => !_isLoggedIn.value;

  static const UserProfile emptyUser = UserProfile(
    id: '',
    name: 'Customer',
    email: '',
    phone: '',
    avatarUrl: '',
    tagline: 'AMN Delivery Customer',
    rating: 5.0,
    totalOrders: 0,
    defaultAddress: 'Addis Ababa, Ethiopia',
    walletAmount: 0.0,
  );

  final Rx<UserProfile> _user = emptyUser.obs;
  UserProfile get user => _user.value;
  set user(UserProfile val) => _user.value = val;

  final rememberMe = true.obs;
  final isLoading = false.obs;
  final status = ApiCallStatus.holding.obs;

  // Temporary storage while awaiting OTP verification after registration
  int? _pendingUserId;
  String? _pendingToken;
  String? _pendingName;
  String? _pendingPhone;
  String? _pendingEmail;
  String? _pendingOtp; // client-generated OTP sent to the server

  int? get currentUserId => ConfigPreference.getUserId();

  @override
  void onInit() {
    super.onInit();
    rememberMe.value = ConfigPreference.getRememberMe();
    final savedUserId = ConfigPreference.getUserId();
    final token = ConfigPreference.getAccessToken();
    final isExpired = ConfigPreference.isAccessTokenExpired();

    if (savedUserId != null || (token != null && !isExpired)) {
      _isLoggedIn.value = true;
      final savedPhone = ConfigPreference.getUserPhone();
      final savedName = ConfigPreference.getUserName();
      final savedEmail = ConfigPreference.getUserEmail();
      _user.value = UserProfile(
        id: savedUserId?.toString() ?? '',
        name: savedName ?? 'Customer',
        email: savedEmail ?? '',
        phone: savedPhone ?? '',
        avatarUrl: '',
        tagline: 'AMN Delivery Customer',
        rating: 5.0,
        totalOrders: 0,
        defaultAddress: 'Addis Ababa, Ethiopia',
        walletAmount: 0.0,
      );
      refreshUserProfile();
    } else {
      _isLoggedIn.value = false;
      _user.value = emptyUser;
    }
  }

  Future<void> refreshUserProfile() async {
    final uid = ConfigPreference.getUserId();
    if (uid != null) {
      final p = await ProfileService.fetchProfile(uid);
      if (p != null) {
        _user.value = p;
      }
    }
  }

  Future<void> login(String phoneOrEmail, String password) async {
    isLoading.value = true;
    status.value = ApiCallStatus.loading;

    // Sanitize phone number (strip spaces, symbols; if starting with 09, convert to 2519)
    String cleanPhone = phoneOrEmail.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('09')) {
      cleanPhone = '251${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('9') && cleanPhone.length == 9) {
      cleanPhone = '251$cleanPhone';
    }

    await AuthService.customerLogin(
      phone: cleanPhone,
      password: password,
      onSuccess: (data) async {
        isLoading.value = false;
        status.value = ApiCallStatus.success;
        _isLoggedIn.value = true;

        // Response can be { user: {...}, token: "..." } or { id: ..., token: ... }
        final userMap = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : data;

        // Check both root and nested user object for id/user_id
        final rawId = data['id'] ?? userMap['id'] ?? data['user_id'] ?? userMap['user_id'];
        final uid = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;

        final firstName = userMap['f_name']?.toString() ?? data['f_name']?.toString() ?? '';
        final lastName = userMap['l_name']?.toString() ?? data['l_name']?.toString() ?? '';
        final fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
            ? '$firstName $lastName'.trim()
            : (userMap['name']?.toString() ?? data['name']?.toString() ?? '');
        final email = userMap['email']?.toString() ?? data['email']?.toString() ?? '';

        await ConfigPreference.setUserId(uid);
        await ConfigPreference.setUserPhone(cleanPhone);
        if (fullName.isNotEmpty) await ConfigPreference.setUserName(fullName);
        if (email.isNotEmpty) await ConfigPreference.setUserEmail(email);

        final token = data['token']?.toString() ?? userMap['token']?.toString() ?? '';
        final expiresIn = rememberMe.value ? 30 * 24 * 3600 : 3600;
        if (token.isNotEmpty) {
          await ConfigPreference.updateTokens(token, token, expiresIn);
        }
        await ConfigPreference.setRememberMe(rememberMe.value);

        final profile = UserProfile.fromJson(data);
        _user.value = profile;

        // Refresh wallet, addresses, and full profile in background
        refreshUserProfile();
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().loadProfileData();
        }

        Get.offAllNamed(AppRoutes.mainNav);
        Get.snackbar(
          'welcome_back'.tr,
          '${'success'.tr}: ${_user.value.name}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      },
      onFailure: (error) {
        isLoading.value = false;
        status.value = ApiCallStatus.error;
        Get.snackbar(
          'login_failed'.tr,
          error,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
    );
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    status.value = ApiCallStatus.loading;

    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('09')) {
      cleanPhone = '251${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('9') && cleanPhone.length == 9) {
      cleanPhone = '251$cleanPhone';
    }

    await AuthService.customerRegister(
      firstName: firstName,
      lastName: lastName,
      phone: cleanPhone,
      email: email,
      password: password,
      onSuccess: (data) async {
        isLoading.value = false;
        status.value = ApiCallStatus.success;

        // Extract user info from response: can be { id: ..., ... } or { user: { id: ... }, token: "..." }
        final userMap = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : data;
        final rawId = data['id'] ?? userMap['id'] ?? data['user_id'] ?? userMap['user_id'];
        final uid = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;
        final token = data['token']?.toString() ?? userMap['token']?.toString() ?? '';

        // Hold credentials in memory — don't persist until OTP is verified
        _pendingUserId = uid;
        _pendingToken = token;
        _pendingPhone = cleanPhone;
        _pendingEmail = email;
        _pendingName = '$firstName $lastName'.trim();

        // Generate 4-digit OTP client-side and send to server (server SMS's it to user)
        _pendingOtp = (1000 + Random().nextInt(9000)).toString();

        // Pre-set user object so OTP screen can show name if needed
        _user.value = UserProfile.fromJson(data);

        await AuthService.sendOtp(
          phone: cleanPhone,
          otp: _pendingOtp!,
          onSuccess: () {},
          onFailure: (_) {},
        );

        Get.toNamed(AppRoutes.otp, arguments: {
          'userId': uid,
          'phone': cleanPhone,
        });
      },
      onFailure: (error) {
        isLoading.value = false;
        status.value = ApiCallStatus.error;
        Get.snackbar(
          'registration_failed'.tr,
          error,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
    );
  }

  /// Called by OtpScreen after the user enters the correct code.
  Future<void> verifyOtpAndComplete({
    required int userId,
    required String otp,
  }) async {
    // Check locally first — OTP was generated client-side
    if (_pendingOtp != null && otp != _pendingOtp) {
      Get.snackbar(
        'invalid_code'.tr,
        'invalid_code_desc'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Notify server that this user is verified
    await AuthService.verifyOtp(
      userId: userId,
      otp: otp,
      onSuccess: () async {
        final uid = _pendingUserId ?? userId;
        final token = _pendingToken ?? '';
        final name = _pendingName ?? '';
        final phone = _pendingPhone ?? '';
        final email = _pendingEmail ?? '';

        // Now persist everything
        await ConfigPreference.setUserId(uid);
        await ConfigPreference.setUserPhone(phone);
        if (email.isNotEmpty) await ConfigPreference.setUserEmail(email);
        if (name.isNotEmpty) await ConfigPreference.setUserName(name);
        final expiresIn = rememberMe.value ? 30 * 24 * 3600 : 3600;
        if (token.isNotEmpty) {
          await ConfigPreference.updateTokens(token, token, expiresIn);
        }

        // Clear all pending state
        _pendingUserId = null;
        _pendingToken = null;
        _pendingPhone = null;
        _pendingEmail = null;
        _pendingName = null;
        _pendingOtp = null;

        _isLoggedIn.value = true;

        // Refresh profile data now that we have a real user
        refreshUserProfile();
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().loadProfileData();
        }

        Get.offAllNamed(AppRoutes.mainNav);
        Get.snackbar(
          'account_verified'.tr,
          '${'welcome_back'.tr}, $name!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
      onFailure: (error) {
        Get.snackbar(
          'verification_failed'.tr,
          error,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
    );
  }

  /// Resend OTP to the given phone (called by OtpScreen resend button).
  Future<void> resendOtp({required String phone}) async {
    // Generate a fresh OTP so the old one is invalidated
    _pendingOtp = (1000 + Random().nextInt(9000)).toString();

    await AuthService.sendOtp(
      phone: phone,
      otp: _pendingOtp!,
      onSuccess: () {
        Get.snackbar(
          'code_sent'.tr,
          'A new verification code has been sent to $phone',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      onFailure: (error) {
        Get.snackbar(
          'failed_to_resend'.tr,
          error,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  Future<void> logout() async {
    final uid = ConfigPreference.getUserId();
    if (uid != null) {
      await AuthService.customerLogout(userId: uid, onSuccess: () {}, onFailure: (_) {});
    }
    _isLoggedIn.value = false;
    await ConfigPreference.clearTokens();
    _user.value = emptyUser;
    Get.offAllNamed(AppRoutes.login);
  }
}
