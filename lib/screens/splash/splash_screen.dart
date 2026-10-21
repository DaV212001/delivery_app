import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_assets.dart';
import '../../constants/pages.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../utils/update_enforcer.dart';
import '../../widgets/common/app_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateChecker().checkForUpdates(fromStartUp: true);
    });
  }

  void _checkAuth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        if (authController.isLoggedIn) {
          Get.offAllNamed(AppRoutes.mainNav);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Section: Brand & Headline
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo row
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          AppAssets.appLogo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'app_name'.tr,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Headline (Quicksand display)
                  Text(
                    'splash_headline'.tr,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'splash_subheadline'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Hero Food Image with curved top
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AppNetworkImage(
                        imageUrl: AppAssets.splashHero,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Gradient subtle overlay for smooth transition
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sticky Bottom Action Area
            Container(
              color: theme.cardColor,
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    text: 'get_started'.tr,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                    onPressed: () => Get.toNamed(AppRoutes.login),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'already_have_account_prompt'.tr,
                        style: theme.textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.login),
                        child: Text(
                          'log_in'.tr,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
