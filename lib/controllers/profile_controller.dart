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
  final isLoadingInfo = false.obs;

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
    isLoadingInfo.value = true;
    try {
      final faqList = await InfoService.fetchFaqs();
      faqs.assignAll(faqList);
      privacyPolicy.value = await InfoService.fetchPrivacyPolicy();
      termsAndConditions.value = await InfoService.fetchTermsAndConditions();
    } catch (_) {
    } finally {
      isLoadingInfo.value = false;
    }
  }

  /// Universal Top-Up Dialog for Wallet
  static void showTopUpDialog(BuildContext context, {double? suggestedAmount}) {
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    final initialVal = suggestedAmount != null && suggestedAmount > 0
        ? suggestedAmount.ceil().toString()
        : '100';

    final amountController = TextEditingController(text: initialVal);
    final quickAmounts = [100.0, 250.0, 500.0, 1000.0];

    Get.dialog(
      StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'topup_wallet'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'topup_prompt'.tr,
                    style: TextStyle(
                      color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickAmounts.map((amt) {
                      final isSelected = amountController.text == amt.toStringAsFixed(0);
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            amountController.text = amt.toStringAsFixed(0);
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkSurfaceContainerLow
                                    : AppColors.surfaceContainerLow),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            '+${amt.toStringAsFixed(0)} Br',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.darkOnSurface
                                      : AppColors.onSurface),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'custom_amount'.tr,
                      suffixText: 'Br',
                      prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkInputBg : AppColors.inputBg,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'secured_chapa'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('cancel'.tr),
              ),
              Obx(() {
                if (profileController.isSaving.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  );
                }
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: () {
                    final val = double.tryParse(amountController.text.trim()) ?? 0;
                    if (val <= 0) {
                      Get.snackbar(
                        'invalid_amount'.tr,
                        'enter_valid_amount'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    profileController.topupWallet(val);
                  },
                  child: Text(
                    'proceed_to_pay'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
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
          try {
            PaintingBinding.instance.imageCache.clear();
            PaintingBinding.instance.imageCache.clearLiveImages();
          } catch (_) {}
          await ConfigPreference.setUserAvatar(newUrl);
          if (Get.isRegistered<AuthController>()) {
            final auth = Get.find<AuthController>();
            auth.user = auth.user.copyWith(avatarUrl: newUrl);
            await auth.refreshUserProfile();
          }
        } else {
          if (Get.isRegistered<AuthController>()) {
            await Get.find<AuthController>().refreshUserProfile();
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
