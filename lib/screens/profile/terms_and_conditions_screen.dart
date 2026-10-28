import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/profile_controller.dart';
import '../../core/theme/app_colors.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'terms_and_conditions'.tr.isNotEmpty
              ? 'terms_and_conditions'.tr
              : 'Terms & Conditions',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => profileController.loadInformation(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.darkSurfaceContainerLow,
                            AppColors.darkSurface,
                          ]
                        : [
                            AppColors.primaryContainer.withValues(alpha: 0.6),
                            AppColors.surface,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkOutline.withValues(alpha: 0.3)
                        : AppColors.primaryFixed.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'terms_and_conditions'.tr.isNotEmpty
                                ? 'terms_and_conditions'.tr
                                : 'Terms & Conditions',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'terms_sub'.tr.isNotEmpty
                                ? 'terms_sub'.tr
                                : 'Terms and conditions of service',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkOnSurfaceVariant
                                  : AppColors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Main Terms Content
              Obx(() {
                final customTerms = profileController.termsAndConditions.value.trim();

                Widget content;
                if (customTerms.isNotEmpty) {
                  content = Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkOutlineVariant
                            : AppColors.outlineVariant,
                      ),
                    ),
                    child: SelectableText(
                      customTerms,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark
                            ? AppColors.darkOnSurface
                            : AppColors.onSurface,
                      ),
                    ),
                  );
                } else {
                  content = Column(
                    children: [
                      _buildTermsSection(
                        context,
                        isDark: isDark,
                        icon: Icons.handshake_outlined,
                        title: '1. Acceptance of Terms',
                        content:
                            'By installing, accessing, or placing orders via AMN Delivery, you enter into a binding agreement to adhere to these Terms and Conditions and our Privacy Policy. If you do not agree, please discontinue using the service.',
                      ),
                      const SizedBox(height: 16),
                      _buildTermsSection(
                        context,
                        isDark: isDark,
                        icon: Icons.person_outline_rounded,
                        title: '2. User Accounts & Registration',
                        content:
                            'You must be at least 18 years old or possess legal guardian consent to register. You agree to provide accurate phone verification and take full responsibility for all activities conducted under your registered credentials.',
                      ),
                      const SizedBox(height: 16),
                      _buildTermsSection(
                        context,
                        isDark: isDark,
                        icon: Icons.storefront_outlined,
                        title: '3. Orders & Merchant Availability',
                        content:
                            'All orders placed are subject to merchant confirmation, item availability, and operating schedules. In the event an item is out of stock, merchant staff or support may contact you to suggest replacements or cancel the line item.',
                      ),
                      const SizedBox(height: 16),
                      _buildTermsSection(
                        context,
                        isDark: isDark,
                        icon: Icons.account_balance_wallet_outlined,
                        title: '4. Payments, Pricing & Wallet',
                        content:
                            'Prices listed are in Ethiopian Birr (ETB) and include applicable taxes unless specified otherwise. Payment can be settled via in-app AMN Wallet, Telebirr, Chapa, or Cash on Delivery. Delivery fees vary based on distance and route conditions.',
                      ),
                      const SizedBox(height: 16),
                      _buildTermsSection(
                        context,
                        isDark: isDark,
                        icon: Icons.cancel_outlined,
                        title: '5. Cancellations & Refund Policy',
                        content:
                            'Orders may be cancelled free of charge before the merchant starts meal preparation or packaging. Eligible refunds approved by customer support for missing or damaged orders are credited back directly to your AMN In-App Wallet.',
                      ),
                      const SizedBox(height: 16),
                      _buildTermsSection(
                        context,
                        isDark: isDark,
                        icon: Icons.moped_outlined,
                        title: '6. Delivery & Address Accuracy',
                        content:
                            'Customers must provide accurate GPS pins, building details, and contact numbers. Drivers will wait up to 10 minutes at the dropoff location. Unreachable recipients may result in forfeited orders without refund.',
                      ),
                      const SizedBox(height: 16),
                      _buildTermsSection(
                        context,
                        isDark: isDark,
                        icon: Icons.gavel_outlined,
                        title: '7. Limitation of Liability & Law',
                        content:
                            'AMN Delivery provides digital logistics matchmaking connecting customers with third-party vendors and independent couriers. These terms are governed under the laws of Ethiopia.',
                      ),
                    ],
                  );
                }

                return content;
              }),

              const SizedBox(height: 24),

              // Agreement Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerLow
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'By using AMN Delivery, you acknowledge and agree to these terms and conditions.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkOutlineVariant : AppColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13.5,
              height: 1.5,
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
