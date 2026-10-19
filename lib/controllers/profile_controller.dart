import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/storage_config.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../core/theme/app_colors.dart';
import '../models/address_model.dart';
import '../models/faq_model.dart';
import '../models/wallet_model.dart';
import '../screens/wallet/payment_webview_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/info_service.dart';
import '../services/profile_service.dart';
import '../utils/api_call_status.dart';
import '../utils/location_utils.dart';

class ProfileController extends GetxController {
  final status = ApiCallStatus.holding.obs;
  final walletBalance = const WalletBalance(amount: 0.0).obs;
  final transactions = <WalletTransaction>[].obs;
  final addresses = <AddressModel>[].obs;
  final selectedAddress = Rxn<AddressModel>();
  final faqs = <FaqItem>[].obs;
  final privacyPolicy = ''.obs;
  final termsAndConditions = ''.obs;

  final isLoadingWallet = false.obs;
  final isLoadingAddresses = false.obs;
  final isSaving = false.obs;
  final isUploadingAvatar = false.obs;

  int? get customerId => ConfigPreference.getUserId();
  bool get isAuthenticated => customerId != null;

  /// Active latitude from the selected delivery address, or Addis Ababa center fallback
  double get activeLatitude =>
      selectedAddress.value?.latitude ?? LocationUtils.defaultLatitude;

  /// Active longitude from the selected delivery address, or Addis Ababa center fallback
  double get activeLongitude =>
      selectedAddress.value?.longitude ?? LocationUtils.defaultLongitude;

  @override
  void onInit() {
    super.onInit();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    status.value = ApiCallStatus.loading;
    final futures = <Future<void>>[loadInformation()];
    if (isAuthenticated) {
      futures.add(loadWallet());
      futures.add(loadAddresses());
    } else {
      walletBalance.value = const WalletBalance(amount: 0.0);
      transactions.clear();
      addresses.clear();
    }
    await Future.wait(futures);
    status.value = ApiCallStatus.success;
  }

  /// Reset all user-specific profile state (called on logout)
  void clear() {
    walletBalance.value = const WalletBalance(amount: 0.0);
    transactions.clear();
    addresses.clear();
    selectedAddress.value = null;
    status.value = ApiCallStatus.holding;
  }

  Future<void> loadWallet() async {
    final uid = customerId;
    if (uid == null) {
      walletBalance.value = const WalletBalance(amount: 0.0);
      transactions.clear();
      return;
    }
    isLoadingWallet.value = true;
    try {
      final balance = await ProfileService.fetchWalletAmount(uid);
      walletBalance.value = balance;
      final txList = await ProfileService.fetchWalletTransactions(uid);
      transactions.assignAll(txList);
    } catch (_) {
      // Do not inject fake 330.0 Br on error
      walletBalance.value = const WalletBalance(amount: 0.0);
      transactions.clear();
    } finally {
      isLoadingWallet.value = false;
    }
  }

  Future<void> loadAddresses() async {
    final uid = customerId;
    if (uid == null) {
      addresses.clear();
      selectedAddress.value = null;
      return;
    }
    isLoadingAddresses.value = true;
    try {
      final list = await ProfileService.fetchDeliveryAddresses(uid);
      addresses.assignAll(list);
      if (selectedAddress.value == null && list.isNotEmpty) {
        if (Get.isRegistered<AuthController>()) {
          final auth = Get.find<AuthController>();
          final match = list.firstWhereOrNull((a) => a.name == auth.user.defaultAddress);
          selectedAddress.value = match ?? list.first;
        } else {
          selectedAddress.value = list.first;
        }
      }
    } catch (_) {
      // Do not inject fake address on error
      addresses.clear();
    } finally {
      isLoadingAddresses.value = false;
    }
  }

  void selectAddress(AddressModel address) {
    selectedAddress.value = address;
    if (Get.isRegistered<AuthController>()) {
      try {
        final auth = Get.find<AuthController>();
        auth.user = auth.user.copyWith(defaultAddress: address.name);
      } catch (_) {}
    }
    if (Get.isRegistered<CartController>()) {
      try {
        final cart = Get.find<CartController>();
        cart.deliveryAddress.value = address.name;
      } catch (_) {}
    }
    Get.snackbar(
      'delivering_to'.tr,
      address.name,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> loadInformation() async {
    try {
      final faqList = await InfoService.fetchFaqs();
      faqs.assignAll(faqList);
      privacyPolicy.value = await InfoService.fetchPrivacyPolicy();
      termsAndConditions.value = await InfoService.fetchTermsAndConditions();
    } catch (_) {}
  }

  Future<void> topupWallet(double amount) async {
    final uid = customerId;
    if (uid == null) {
      Get.snackbar(
        'sign_in_required'.tr,
        'sign_in_prompt'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    isSaving.value = true;
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await ProfileService.topupWallet(
      userId: uid,
      amount: amount,
      date: dateStr,
      onSuccess: (checkoutUrl, message) async {
        isSaving.value = false;
        Get.back(); // Dismiss top-up input dialog

        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          // Open in-app WebView tracking receipt page redirects and refetching balance
          await Get.to(
            () => PaymentWebViewScreen(
              initialUrl: checkoutUrl,
              title: 'AMN Wallet Top-up',
              onReceiptDetected: () async {
                await loadWallet();
              },
            ),
          );

          // Once the WebView closes, refresh wallet balance to guarantee fresh data
          await loadWallet();
          return;
        }

        // Fallback for direct crediting or offline
        await loadWallet();
        Get.snackbar(
          'topup_successful'.tr,
          '${amount.toStringAsFixed(2)} ${'currency'.tr} ${'added_to_wallet'.tr}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
      onFailure: (error) {
        isSaving.value = false;
        Get.snackbar(
          'topup_failed'.tr,
          error,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
    );
  }

  Future<void> addAddress(String name, double lat, double lng) async {
    final uid = customerId;
    if (uid == null) {
      Get.snackbar(
        'sign_in_required'.tr,
        'sign_in_prompt'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    isSaving.value = true;
    final newAddress = AddressModel(
      name: name,
      latitude: lat,
      longitude: lng,
      userId: uid,
    );

    await ProfileService.addDeliveryAddress(
      address: newAddress,
      onSuccess: () async {
        isSaving.value = false;
        await loadAddresses();
        Get.back();
        selectAddress(newAddress);
      },
      onFailure: (error) {
        isSaving.value = false;
        Get.snackbar(
          'failed_to_add_address'.tr,
          error,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
    );
  }

  Future<void> deleteAddress(int addressId) async {
    final uid = customerId;
    if (uid == null) return;
    await ProfileService.deleteDeliveryAddress(
      addressId: addressId,
      onSuccess: () async {
        await loadAddresses();
        Get.snackbar(
          'address_removed'.tr,
          'address_deleted_sub'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      onFailure: (err) => Get.snackbar('error'.tr, err),
    );
  }

  /// Update customer profile (f_name, l_name, email, phone)
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    final uid = customerId;
    if (uid == null) {
      Get.snackbar(
        'sign_in_required'.tr,
        'sign_in_prompt'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    final cleanPhone = AuthController.sanitizePhone(phone);
    isSaving.value = true;
    bool success = false;

    await ProfileService.updateProfile(
      customerId: uid,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      phone: cleanPhone,
      onSuccess: (data) async {
        isSaving.value = false;
        success = true;

        final fullName = '$firstName $lastName'.trim();
        await ConfigPreference.setUserName(fullName);
        await ConfigPreference.setUserEmail(email.trim());
        await ConfigPreference.setUserPhone(cleanPhone);

        if (Get.isRegistered<AuthController>()) {
          final auth = Get.find<AuthController>();
          auth.user = auth.user.copyWith(
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            name: fullName,
            email: email.trim(),
            phone: cleanPhone,
          );
          // Sync any extra server-updated fields in the background
          auth.refreshUserProfile();
        }

        Get.snackbar(
          'success'.tr,
          'profile_updated_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      },
      onFailure: (error) {
        isSaving.value = false;
        success = false;
        Get.snackbar(
          'error'.tr,
          error,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
    );

    return success;
  }

  /// Edit existing delivery address
  Future<void> editAddress(int id, String name, double lat, double lng) async {
    final uid = customerId;
    if (uid == null) {
      Get.snackbar(
        'sign_in_required'.tr,
        'sign_in_prompt'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    isSaving.value = true;
    final updatedAddress = AddressModel(
      id: id,
      name: name,
      latitude: lat,
      longitude: lng,
      userId: uid,
    );

    await ProfileService.editDeliveryAddress(
      address: updatedAddress,
      onSuccess: () async {
        isSaving.value = false;
        await loadAddresses();
        Get.back();
        if (selectedAddress.value?.id == id) {
          selectedAddress.value = updatedAddress;
          if (Get.isRegistered<AuthController>()) {
            try {
              final auth = Get.find<AuthController>();
              auth.user = auth.user.copyWith(defaultAddress: updatedAddress.name);
            } catch (_) {}
          }
        }
        Get.snackbar(
          'success'.tr,
          'address_updated'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      },
      onFailure: (error) {
        isSaving.value = false;
        Get.snackbar(
          'error'.tr,
          error,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
    );
  }

  void _showSnackbar(
    String title,
    String message, {
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
  }) {
    if (Get.testMode) return;
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

  /// Upload profile image by local file path
  Future<bool> uploadProfileImage(String filePath) async {
    final uid = customerId;
    if (uid == null) {
      _showSnackbar(
        'sign_in_required'.tr,
        'sign_in_prompt'.tr,
      );
      return false;
    }

    isUploadingAvatar.value = true;
    bool success = false;

    await AuthService.uploadProfileImage(
      userId: uid,
      filePath: filePath,
      onSuccess: (newUrl) async {
        isUploadingAvatar.value = false;
        success = true;

        if (newUrl.isNotEmpty) {
          await ConfigPreference.setUserAvatar(newUrl);
          if (Get.isRegistered<AuthController>()) {
            final auth = Get.find<AuthController>();
            auth.user = auth.user.copyWith(avatarUrl: newUrl);
          }
        }

        _showSnackbar(
          'success'.tr,
          'photo_updated_successfully'.tr,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      },
      onFailure: (error) {
        isUploadingAvatar.value = false;
        success = false;
        _showSnackbar(
          'error'.tr,
          error,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      },
    );

    return success;
  }

  /// Pick an image from Camera or Gallery and upload
  Future<void> pickAndUploadAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        await uploadProfileImage(picked.path);
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_upload_photo'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
