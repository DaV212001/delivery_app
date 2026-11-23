import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/cart_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../utils/update_enforcer.dart';
import '../../widgets/common/floating_cart_bar.dart';
import 'discover/discover_screen.dart';
import 'home/home_screen.dart';
import 'orders/order_history_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationController extends GetxController {
  final currentIndex = 0.obs;
  final visitedTabs = <int>{0}.obs;

  @override
  void onReady() {
    super.onReady();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateChecker().checkForUpdates(fromStartUp: true);
    });
  }

  bool isTabVisited(int index) => visitedTabs.contains(index);

  void changePage(int index) {
    currentIndex.value = index;
    visitedTabs.add(index);
  }
}

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.isRegistered<MainNavigationController>()
        ? Get.find<MainNavigationController>()
        : Get.put(MainNavigationController());
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            final current = nav.currentIndex.value;
            return IndexedStack(
              index: current,
              children: [
                const HomeScreen(),
                nav.isTabVisited(1) ? const DiscoverScreen() : const SizedBox.shrink(),
                nav.isTabVisited(2) ? const OrderHistoryScreen() : const SizedBox.shrink(),
                nav.isTabVisited(3) ? const ProfileScreen() : const SizedBox.shrink(),
              ],
            );
          }),
          // Floating Bottom Sticky Cart Bar right above bottom nav when cart has items
          const FloatingCartBar(bottom: 12),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final current = nav.currentIndex.value;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'home'.tr,
                    isSelected: current == 0,
                    onTap: () => nav.changePage(0),
                  ),
                  _NavItem(
                    icon: Icons.search_rounded,
                    label: 'discover'.tr,
                    isSelected: current == 1,
                    onTap: () => nav.changePage(1),
                  ),
                  _NavItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'orders'.tr,
                    isSelected: current == 2,
                    onTap: () => nav.changePage(2),
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    label: 'profile'.tr,
                    isSelected: current == 3,
                    onTap: () => nav.changePage(3),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? AppColors.primary
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
