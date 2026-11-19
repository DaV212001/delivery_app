import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/localization_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/restaurant_controller.dart';
import '../../constants/pages.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../utils/update_enforcer.dart';
import '../../widgets/common/app_widgets.dart';
import '../home/widgets/restaurant_list_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showTopupDialog(BuildContext context, ProfileController profileController) {
    final amountController = TextEditingController(text: '100');
    Get.dialog(
      AlertDialog(
        title: Text('topup_wallet'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'enter_amount'.tr} (Br):'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                suffixText: 'Br',
                hintText: '100',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          Obx(() {
            if (profileController.isSaving.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              );
            }
            return ElevatedButton(
              onPressed: () {
                final val = double.tryParse(amountController.text.trim()) ?? 0;
                if (val <= 0) {
                  Get.snackbar('error'.tr, 'enter_amount'.tr);
                  return;
                }
                profileController.topupWallet(val);
              },
              child: Text('topup'.tr),
            );
          }),
        ],
      ),
    );
  }

  void _showFavoriteSpotsSheet(BuildContext context, RestaurantController restaurantController) {
    final theme = Theme.of(context);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'favorite_spots'.tr,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Flexible(
                child: Obx(() {
                  final favs = restaurantController.favoriteRestaurants;
                  if (favs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(alpha: 0.1),
                              ),
                              child: const Icon(
                                Icons.favorite_border_rounded,
                                size: 32,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'no_favorite_spots'.tr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'no_favorite_spots_sub'.tr,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: favs.length,
                    itemBuilder: (ctx, idx) {
                      final store = favs[idx];
                      return RestaurantListItem(store: store);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    final themeController = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : Get.put(ThemeController());
    final restaurantController = Get.isRegistered<RestaurantController>()
        ? Get.find<RestaurantController>()
        : Get.put(RestaurantController());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'profile'.tr,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => profileController.loadProfileData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Obx(() {
            final isLoggedIn = authController.isLoggedIn;

            // GUEST MODE: Show guest header, sign in button, and support/preferences
            if (!isLoggedIn) {
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_outline_rounded,
                              size: 38,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'guest_mode'.tr,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'sign_in_profile_sub'.tr,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.login_rounded, size: 20),
                            label: Text(
                              'sign_in_register'.tr,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            onPressed: () => Get.toNamed(AppRoutes.login),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Merchant Section
                  _SettingsGroup(
                    title: 'merchant_management'.tr,
                    children: [
                      _SettingsTile(
                        icon: Icons.storefront_rounded,
                        title: 'my_property'.tr,
                        subtitle: 'my_property_sub'.tr,
                        onTap: () {
                          if (!authController.isLoggedIn) {
                            Get.toNamed(AppRoutes.login);
                          } else {
                            Get.toNamed(AppRoutes.myProperty);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Preferences Section (Always accessible)
                  _buildPreferencesGroup(context, theme, themeController, profileController),
                  const SizedBox(height: 40),
                ],
              );
            }

            // AUTHENTICATED MODE: Full profile with bento card, wallet, and settings
            final user = authController.user;
            return Column(
              children: [
                // Bento Profile Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.editProfile),
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: AppNetworkImage(
                              imageUrl: user.avatarUrl,
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.name.isNotEmpty ? user.name : 'AMN Customer',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.phone.isNotEmpty
                            ? user.phone
                            : (user.email.isNotEmpty ? user.email : 'AMN Customer'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Edit Profile Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(
                          'edit_profile'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        onPressed: () => Get.toNamed(AppRoutes.editProfile),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Live Wallet Card
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Get.toNamed(AppRoutes.wallet),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'wallet_balance'.tr,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Obx(
                                    () => Text(
                                      profileController.walletBalance.value.formattedBirr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Material(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => _showTopupDialog(context, profileController),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        'topup'.tr,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Account Options Section
                _SettingsGroup(
                  title: 'account_settings'.tr,
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'edit_profile'.tr,
                      subtitle: 'edit_profile_sub'.tr,
                      onTap: () => Get.toNamed(AppRoutes.editProfile),
                    ),
                    Obx(
                      () => _SettingsTile(
                        icon: Icons.location_on_outlined,
                        title: 'saved_addresses'.tr,
                        subtitle: '${profileController.addresses.length} ${'delivery_addresses'.tr.toLowerCase()}',
                        onTap: () => Get.toNamed(AppRoutes.savedAddresses),
                      ),
                    ),
                    Obx(
                      () => _SettingsTile(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'wallet_and_payments'.tr,
                        subtitle: '${'wallet_balance'.tr} (${profileController.walletBalance.value.formattedBirr})',
                        onTap: () => Get.toNamed(AppRoutes.wallet),
                      ),
                    ),
                    Obx(
                      () => _SettingsTile(
                        icon: Icons.favorite_border_rounded,
                        title: 'favorite_spots'.tr,
                        subtitle: '${restaurantController.favoriteRestaurants.length} ${'saved_stores_sub'.tr}',
                        onTap: () => _showFavoriteSpotsSheet(context, restaurantController),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.storefront_rounded,
                      title: 'my_properties'.tr,
                      subtitle: 'my_properties_sub'.tr,
                      onTap: () => Get.toNamed(AppRoutes.myProperty),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Preferences Section
                _buildPreferencesGroup(context, theme, themeController, profileController),

                const SizedBox(height: 24),

                // iOS Account Deletion Section (Apple App Store Guideline 5.1.1(v))
                if (Platform.isIOS) ...[
                  _SettingsGroup(
                    title: 'account_management'.tr,
                    children: [
                      _SettingsTile(
                        icon: Icons.delete_forever_rounded,
                        iconColor: Colors.redAccent,
                        title: 'delete_account'.tr,
                        subtitle: 'delete_account_sub'.tr,
                        onTap: () => _requestAccountDeletion(context, authController),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Logout Button
                AppButton(
                  isSecondary: true,
                  isLoading: authController.isLoggingOut.value,
                  text: authController.isLoggingOut.value ? 'signing_out'.tr : 'sign_out'.tr,
                  icon: authController.isLoggingOut.value
                      ? null
                      : const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                  onPressed: authController.isLoggingOut.value ? null : () => authController.logout(),
                ),

                const SizedBox(height: 40),
              ],
            );
          }),
        ),
      ),
      Obx(() {
        if (!authController.isLoggingOut.value) return const SizedBox.shrink();
        return Positioned.fill(
          child: AbsorbPointer(
            absorbing: true,
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceContainerHighest : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'signing_out'.tr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    ],
  ),
),
);
  }

  Widget _buildPreferencesGroup(
    BuildContext context,
    ThemeData theme,
    ThemeController themeController,
    ProfileController profileController,
  ) {
    return _SettingsGroup(
      title: 'preferences_support'.tr,
      children: [
        Obx(
          () => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                themeController.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              'dark_mode'.tr,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              themeController.isDarkMode ? 'Warm Dark Modernism' : 'Warm Cream Light',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Switch(
              value: themeController.isDarkMode,
              activeTrackColor: AppColors.primary,
              onChanged: (_) => themeController.toggleTheme(),
            ),
          ),
        ),
        Obx(
          () => _SettingsTile(
            icon: Icons.language_rounded,
            title: 'language'.tr,
            subtitle: LocalizationController.getLanguageName(),
            onTap: () => _showLanguageSelectionSheet(context),
          ),
        ),
        _SettingsTile(
          icon: Icons.emergency_rounded,
          title: 'emergency_support'.tr,
          subtitle: 'emergency_support_sub'.tr,
          onTap: () => _showEmergencyDialog(context),
        ),
        _SettingsTile(
          icon: Icons.help_outline_rounded,
          title: 'faq'.tr,
          subtitle: 'faqs_support_sub'.tr,
          onTap: () => Get.toNamed(AppRoutes.faq),
        ),
        _SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: 'privacy_policy'.tr,
          subtitle: 'privacy_sub'.tr,
          onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
        ),
        _SettingsTile(
          icon: Icons.description_outlined,
          title: 'terms_and_conditions'.tr,
          subtitle: 'terms_sub'.tr,
          onTap: () => Get.toNamed(AppRoutes.termsAndConditions),
        ),
        _SettingsTile(
          icon: Icons.system_security_update_rounded,
          title: 'check_for_updates'.tr,
          subtitle: 'check_for_updates_sub'.tr,
          onTap: () => UpdateChecker().checkForUpdates(fromStartUp: false),
        ),
      ],
    );
  }

  void _showLanguageSelectionSheet(BuildContext context) {
    final theme = Theme.of(context);
    Get.bottomSheet(
      Material(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'select_language'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...LocalizationController.supportedLanguages.map(
                    (opt) => Obx(() {
                      final isSelected = LocalizationController.currentLanguageCode.value == opt.codeString;
                      return ListTile(
                        leading: Text(opt.flag, style: const TextStyle(fontSize: 24)),
                        title: Text(
                          opt.nativeName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        ),
                        subtitle: Text(opt.name),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                        onTap: () async {
                          Get.back();
                          await LocalizationController.changeLanguage(opt.locale);
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
      ),
    ),
    isScrollControlled: true,
  );
  }

  void _showEmergencyDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Get.bottomSheet(
      Material(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'emergency_support'.tr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'tap_to_call'.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.darkOnSurfaceVariant
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildEmergencyTile(
                    context,
                    title: 'amn_hotline'.tr,
                    number: '8896',
                    icon: Icons.headset_mic_rounded,
                    color: AppColors.primary,
                    isHighlighted: true,
                  ),
                  const SizedBox(height: 10),
                  _buildEmergencyTile(
                    context,
                    title: 'police_emergency'.tr,
                    number: '991',
                    icon: Icons.local_police_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 10),
                  _buildEmergencyTile(
                    context,
                    title: 'ambulance_emergency'.tr,
                    number: '907',
                    icon: Icons.medical_services_rounded,
                    color: const Color(0xFFDC2626),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildEmergencyTile(
    BuildContext context, {
    required String title,
    required String number,
    required IconData icon,
    required Color color,
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? color.withValues(alpha: 0.08)
            : (isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? color.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant),
          width: isHighlighted ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          number,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        trailing: FilledButton.icon(
          onPressed: () async {
            final uri = Uri.parse('tel:$number');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
          icon: const Icon(Icons.call_rounded, size: 16),
          label: Text('call'.tr.isNotEmpty ? 'call'.tr : 'Call'),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        onTap: () async {
          final uri = Uri.parse('tel:$number');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
      ),
    );
  }

  Future<void> _requestAccountDeletion(
    BuildContext context,
    AuthController authController,
  ) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'delete_account'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'delete_account_confirm'.tr,
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Get.back(result: true),
            child: Text('delete_account'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('delete_account_pending', true);
      } catch (_) {}

      await authController.logout();

      Get.snackbar(
        'request_submitted'.tr,
        'account_deletion_pending'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
      );
    }
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = iconColor ?? AppColors.primary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: effectiveColor, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}
