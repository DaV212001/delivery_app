import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/storage_config.dart';
import '../constants/pages.dart';
import '../controllers/cart_controller.dart';
import '../controllers/corporate_controller.dart';
import '../controllers/my_property_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/restaurant_controller.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/customer_socket_service.dart';
import '../services/profile_service.dart';
import '../services/user_location_service.dart';
import '../utils/api_call_status.dart';

class AuthController extends GetxController {
  static bool get isInTest =>
      Get.testMode || Platform.environment.containsKey('FLUTTER_TEST');

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

  // Temporary storage while awaiting OTP verification for password reset
  String? _resetPhone;
  String? _resetOtp;
  bool _resetOtpVerified = false;
  final isSendingResetOtp = false.obs;
  final isResettingPassword = false.obs;
  final resetResendCooldown = 0.obs;

  bool get isResetOtpVerified => _resetOtpVerified;
  String? get resetPhone => _resetPhone;
  String? get pendingEmail => _pendingEmail;
  String? get pendingPhone => _pendingPhone;

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
      final savedAvatar = ConfigPreference.getUserAvatar();
      String firstName = '';
      String lastName = '';
      if (savedName != null && savedName.isNotEmpty) {
        final parts = savedName.trim().split(RegExp(r'\s+'));
        firstName = parts.first;
        if (parts.length > 1) {
          lastName = parts.sublist(1).join(' ');
        }
      }
      final savedType = ConfigPreference.getUserType() ?? '0';
      final savedCompanyId = ConfigPreference.getUserCompanyId() ?? '0';
      final savedBranchId = ConfigPreference.getUserBranchId() ?? '0';

      _user.value = UserProfile(
        id: savedUserId?.toString() ?? '',
        name: savedName ?? 'Customer',
        firstName: firstName,
        lastName: lastName,
        email: savedEmail ?? '',
        phone: savedPhone ?? '',
        avatarUrl: savedAvatar ?? '',
        tagline: 'AMN Delivery Customer',
        rating: 5.0,
        totalOrders: 0,
        defaultAddress: 'Addis Ababa, Ethiopia',
        walletAmount: 0.0,
        type: savedType,
        companyId: savedCompanyId,
        branchId: savedBranchId,
      );
      refreshUserProfile();
    } else {
      _isLoggedIn.value = false;
      _user.value = emptyUser;

      final pendingReg = ConfigPreference.getPendingRegistration();
      if (pendingReg != null) {
        _pendingUserId = pendingReg['userId'] as int?;
        _pendingPhone = pendingReg['phone'] as String?;
        _pendingEmail = pendingReg['email'] as String?;
        _pendingName = pendingReg['name'] as String?;
        _pendingToken = pendingReg['token'] as String?;
        _pendingOtp = pendingReg['otp'] as String?;
      }

      final pendingReset = ConfigPreference.getPendingResetPassword();
      if (pendingReset != null) {
        _resetPhone = pendingReset['phone'] as String?;
        _resetOtp = pendingReset['otp'] as String?;
      }
    }
  }

  Future<void> refreshUserProfile() async {
    final uid = ConfigPreference.getUserId();
    if (uid != null) {
      final p = await ProfileService.fetchProfile(uid);
      if (p != null) {
        _user.value = p;
        if (p.avatarUrl.isNotEmpty) {
          await ConfigPreference.setUserAvatar(p.avatarUrl);
        }
        await ConfigPreference.setUserType(p.type);
        await ConfigPreference.setUserCompanyId(p.companyId);
        await ConfigPreference.setUserBranchId(p.branchId);
        if (p.isCorporateUser && Get.isRegistered<CorporateController>()) {
          Get.find<CorporateController>().loadDashboard();
        }
      }
    }
  }

  /// Triggers loading and hydration of all data domains upon successful authentication.
  Future<void> onLoginSuccess() async {
    // 1. Refresh user profile details
    refreshUserProfile();

    // 2. Refresh profile data if already active
    if (Get.isRegistered<ProfileController>() && !Get.isPrepared<ProfileController>()) {
      Get.find<ProfileController>().loadProfileData();
    }

    // 3. Connect real-time tracking socket if already active
    if (Get.isRegistered<CustomerSocketService>() && !Get.isPrepared<CustomerSocketService>()) {
      CustomerSocketService.to.connect();
    }

    // 4. Load user orders if already active
    if (Get.isRegistered<OrderController>() && !Get.isPrepared<OrderController>()) {
      Get.find<OrderController>().loadOrders();
    }

    // 5. Reload catalog & location distances if already active
    if (Get.isRegistered<RestaurantController>() && !Get.isPrepared<RestaurantController>()) {
      final rc = Get.find<RestaurantController>();
      rc.loadRestaurants();
      rc.requestLocationAndCalculateDistances();
    }

    // 6. Reload properties if merchant controller is already active
    if (Get.isRegistered<MyPropertyController>() && !Get.isPrepared<MyPropertyController>()) {
      Get.find<MyPropertyController>().loadProperties(forceRefresh: true);
    }

    // 7. Update live location
    if (Get.isRegistered<UserLocationService>()) {
      Get.find<UserLocationService>().updateLocation();
    }
  }

  Future<void> login(String phoneOrEmail, String password, {String? countryCode}) async {
    isLoading.value = true;
    status.value = ApiCallStatus.loading;

    final cleanPhone = sanitizePhone(phoneOrEmail, countryCode);

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

        // Hydrate all data across all controllers & services before/during navigation
        await onLoginSuccess();

        if (!isInTest) {
          Get.offAllNamed(AppRoutes.mainNav);
          Get.snackbar(
            'welcome_back'.tr,
            '${'success'.tr}: ${_user.value.name}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
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
    String? countryCode,
  }) async {
    isLoading.value = true;
    status.value = ApiCallStatus.loading;

    final cleanPhone = sanitizePhone(phone, countryCode);

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

        await ConfigPreference.setPendingRegistration(
          userId: uid,
          phone: cleanPhone,
          email: email,
          name: '$firstName $lastName'.trim(),
          token: token,
          otp: _pendingOtp!,
        );

        await AuthService.sendOtp(
          phone: cleanPhone,
          otp: _pendingOtp!,
          onSuccess: () {},
          onFailure: (_) {},
        );

        if (!isInTest) {
          Get.toNamed(AppRoutes.otp, arguments: {
            'userId': uid,
            'phone': cleanPhone,
            'email': email,
          });
        }
      },
      onFailure: (error) {
        isLoading.value = false;
        status.value = ApiCallStatus.error;
        if (!isInTest) {
          Get.snackbar(
            'registration_failed'.tr,
            error,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            colorText: Colors.white,
          );
        }
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
      if (!isInTest) {
        Get.snackbar(
          'invalid_code'.tr,
          'invalid_code_desc'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
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
        await ConfigPreference.clearPendingRegistration();
        _pendingUserId = null;
        _pendingToken = null;
        _pendingPhone = null;
        _pendingEmail = null;
        _pendingName = null;
        _pendingOtp = null;

        _isLoggedIn.value = true;

        // Hydrate all data across all controllers & services before/during navigation
        await onLoginSuccess();

        if (!isInTest) {
          Get.offAllNamed(AppRoutes.mainNav);
          Get.snackbar(
            'account_verified'.tr,
            '${'welcome_back'.tr}, $name!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            colorText: Colors.white,
          );
        }
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

  Future<void> clearPendingRegistration() async {
    await ConfigPreference.clearPendingRegistration();
    _pendingUserId = null;
    _pendingToken = null;
    _pendingPhone = null;
    _pendingEmail = null;
    _pendingName = null;
    _pendingOtp = null;
  }

  /// Resend OTP to the given phone (called by OtpScreen resend button).
  Future<void> resendOtp({required String phone}) async {
    // Generate a fresh OTP so the old one is invalidated
    _pendingOtp = (1000 + Random().nextInt(9000)).toString();
    if (_pendingUserId != null) {
      await ConfigPreference.setPendingRegistration(
        userId: _pendingUserId!,
        phone: _pendingPhone ?? phone,
        email: _pendingEmail ?? '',
        name: _pendingName ?? '',
        token: _pendingToken ?? '',
        otp: _pendingOtp!,
      );
    }

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

  /// Sanitize phone number (strip non-digits, attach dial code if specified, default to 251 prefix for local Ethiopian numbers)
  static String sanitizePhone(String phone, [String? dialCode]) {
    final trimmed = phone.trim();
    if (dialCode != null && dialCode.isNotEmpty) {
      final cleanDial = dialCode.replaceAll(RegExp(r'[^0-9]'), '');
      String cleanPhone = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.startsWith(cleanDial)) {
        return cleanPhone;
      }
      if (cleanPhone.startsWith('0')) {
        cleanPhone = cleanPhone.substring(1);
      }
      return '$cleanDial$cleanPhone';
    }

    if (trimmed.startsWith('+')) {
      return trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    }

    String cleanPhone = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('09')) {
      cleanPhone = '251${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('9') && cleanPhone.length == 9) {
      cleanPhone = '251$cleanPhone';
    }
    return cleanPhone;
  }

  Timer? _resetCooldownTimer;

  void _showSnackbar(
    String title,
    String message, {
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
  }) {
    if (isInTest) return;
    if (Get.context != null && Get.overlayContext != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: backgroundColor,
        colorText: colorText,
        duration: duration,
      );
    }
  }

  /// Request OTP for forgot password flow
  Future<bool> sendPasswordResetOtp(String phone, {String? countryCode}) async {
    final cleanPhone = sanitizePhone(phone, countryCode);
    if (cleanPhone.length < 9) {
      _showSnackbar(
        'error'.tr,
        'enter_valid_phone'.tr,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return false;
    }

    isSendingResetOtp.value = true;
    final otp = (1000 + Random().nextInt(9000)).toString();
    _resetPhone = cleanPhone;
    _resetOtp = otp;
    _resetOtpVerified = false;

    bool success = false;
    await AuthService.sendOtp(
      phone: cleanPhone,
      otp: otp,
      onSuccess: () {
        success = true;
        ConfigPreference.setPendingResetPassword(
          phone: cleanPhone,
          otp: otp,
          step: 1,
        );
        _startResetCooldown();
        _showSnackbar(
          'code_sent'.tr,
          '${'enter_code_sent_to'.tr} $cleanPhone',
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
      onFailure: (err) {
        success = false;
        _showSnackbar(
          'error'.tr,
          err,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
    );
    isSendingResetOtp.value = false;
    return success;
  }

  void _startResetCooldown([int seconds = 60]) {
    _resetCooldownTimer?.cancel();
    resetResendCooldown.value = seconds;
    _resetCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resetResendCooldown.value > 0) {
        resetResendCooldown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  /// Resend OTP for forgot password flow
  Future<bool> resendPasswordResetOtp() async {
    if (_resetPhone == null || _resetPhone!.isEmpty) return false;
    if (resetResendCooldown.value > 0) return false;

    isSendingResetOtp.value = true;
    final newOtp = (1000 + Random().nextInt(9000)).toString();
    _resetOtp = newOtp;

    bool success = false;
    await AuthService.sendOtp(
      phone: _resetPhone!,
      otp: newOtp,
      onSuccess: () {
        success = true;
        ConfigPreference.setPendingResetPassword(
          phone: _resetPhone!,
          otp: newOtp,
          step: 1,
        );
        _startResetCooldown();
        _showSnackbar(
          'code_sent'.tr,
          '${'enter_code_sent_to'.tr} $_resetPhone',
        );
      },
      onFailure: (err) {
        success = false;
        _showSnackbar(
          'failed_to_resend'.tr,
          err,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
    );
    isSendingResetOtp.value = false;
    return success;
  }

  /// Verify entered OTP against generated reset OTP
  bool verifyPasswordResetOtp(String otp) {
    if (_resetOtp == null || otp != _resetOtp) {
      _resetOtpVerified = false;
      _showSnackbar(
        'invalid_code'.tr,
        'invalid_code_desc'.tr,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return false;
    }

    _resetOtpVerified = true;
    _showSnackbar(
      'success'.tr,
      'phone_verified_success'.tr,
      backgroundColor: Colors.green.withValues(alpha: 0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
    return true;
  }

  /// Reset password after OTP verification
  Future<bool> resetPasswordWithOtp({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (!_resetOtpVerified || _resetPhone == null) {
      _showSnackbar(
        'error'.tr,
        'please_verify_otp_first'.tr,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return false;
    }

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackbar('error'.tr, 'fill_all_fields'.tr);
      return false;
    }

    if (newPassword.length < 4) {
      _showSnackbar('error'.tr, 'four_digit_pin'.tr);
      return false;
    }

    if (newPassword != confirmPassword) {
      _showSnackbar('error'.tr, 'passwords_dont_match'.tr);
      return false;
    }

    isResettingPassword.value = true;
    bool success = false;

    await AuthService.forgotPassword(
      phone: _resetPhone!,
      password: newPassword,
      passwordConfirmation: confirmPassword,
      onSuccess: () {
        success = true;
        clearResetPasswordState();
        _showSnackbar(
          'success'.tr,
          'password_reset_success'.tr,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      },
      onFailure: (err) {
        success = false;
        _showSnackbar(
          'error'.tr,
          err,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
    );

    isResettingPassword.value = false;
    return success;
  }

  void clearResetPasswordState() {
    _resetCooldownTimer?.cancel();
    ConfigPreference.clearPendingResetPassword();
    _resetPhone = null;
    _resetOtp = null;
    _resetOtpVerified = false;
    isSendingResetOtp.value = false;
    isResettingPassword.value = false;
    resetResendCooldown.value = 0;
  }

  @override
  void onClose() {
    _resetCooldownTimer?.cancel();
    super.onClose();
  }

  Future<void> logout() async {
    final uid = ConfigPreference.getUserId();
    if (uid != null) {
      await AuthService.customerLogout(userId: uid, onSuccess: () {}, onFailure: (_) {});
    }
    _isLoggedIn.value = false;
    await ConfigPreference.clearTokens();
    _user.value = emptyUser;

    // Disconnect real-time tracking socket
    if (Get.isRegistered<CustomerSocketService>() && !Get.isPrepared<CustomerSocketService>()) {
      CustomerSocketService.to.disconnect();
    }

    // Clear user orders
    if (Get.isRegistered<OrderController>() && !Get.isPrepared<OrderController>()) {
      Get.find<OrderController>().clear();
    }

    // Reset profile data
    if (Get.isRegistered<ProfileController>() && !Get.isPrepared<ProfileController>()) {
      Get.find<ProfileController>().clear();
    }

    // Clear cart
    if (Get.isRegistered<CartController>()) {
      final cc = Get.find<CartController>();
      cc.clearCart();
      cc.deliveryAddress.value = '';
    }

    // Clear merchant properties if loaded
    if (Get.isRegistered<MyPropertyController>() && !Get.isPrepared<MyPropertyController>()) {
      Get.find<MyPropertyController>().clear();
    }

    if (!isInTest) {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
