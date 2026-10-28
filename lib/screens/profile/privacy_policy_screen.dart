import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/profile_controller.dart';
import '../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'privacy_policy'.tr.isNotEmpty ? 'privacy_policy'.tr : 'Privacy Policy',
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
                        Icons.shield_outlined,
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
                            'privacy_policy'.tr.isNotEmpty
                                ? 'privacy_policy'.tr
                                : 'Privacy Policy',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'privacy_sub'.tr.isNotEmpty
                                ? 'privacy_sub'.tr
                                : 'Read our data privacy policy',
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

              // Main Policy Content
              Obx(() {
                final customPolicy = profileController.privacyPolicy.value.trim();

                Widget content;
                if (customPolicy.isNotEmpty) {
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
                      customPolicy,
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
                      _buildPolicySection(
                        context,
                        isDark: isDark,
                        icon: Icons.badge_outlined,
                        title: '1. Information We Collect',
                        content:
                            'We collect personal details you provide during registration including your name, verified phone number, email address, and profile photo. When you place orders, we collect delivery addresses, order preferences, and transaction records.',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        context,
                        isDark: isDark,
                        icon: Icons.location_on_outlined,
                        title: '2. Location & Tracking Data',
                        content:
                            'To calculate delivery fees accurately and route delivery riders efficiently, AMN Delivery requests your precise GPS coordinates when browsing restaurants or setting delivery addresses. Location is accessed solely for service delivery and order tracking.',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        context,
                        isDark: isDark,
                        icon: Icons.delivery_dining_outlined,
                        title: '3. How We Use Information',
                        content:
                            'Your information is used strictly to process orders, dispatch couriers, provide customer support, detect fraud, and send order status notifications. We never sell or lease your personal information to third parties.',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        context,
                        isDark: isDark,
                        icon: Icons.lock_outline_rounded,
                        title: '4. Data Protection & Security',
                        content:
                            'We employ industry-standard encryption protocols (SSL/TLS) for data in transit and secure server storage. Payment details are processed through compliant payment providers (Telebirr and Chapa); AMN Delivery does not store banking PINs or raw card secrets.',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        context,
                        isDark: isDark,
                        icon: Icons.share_outlined,
                        title: '5. Sharing With Partners',
                        content:
                            'We share only necessary fulfillment details (recipient name, delivery destination, and contact phone) with the assigned merchant and courier to successfully prepare and deliver your items.',
                      ),
                      const SizedBox(height: 16),
                      _buildPolicySection(
                        context,
                        isDark: isDark,
                        icon: Icons.manage_accounts_outlined,
                        title: '6. Your Rights & Choices',
                        content:
                            'You can review, modify, or update your personal information and saved addresses anytime directly from the Profile tab. You may also contact our support team to request permanent account closure or data deletion.',
                      ),
                    ],
                  );
                }

                return content;
              }),

              const SizedBox(height: 24),

              // Contact & Support Footer Card
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
                    Icon(
                      Icons.contact_support_outlined,
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.onSurfaceVariant,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Questions regarding our privacy practices? Contact us at support@amnplc.com',
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

  Widget _buildPolicySection(
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
