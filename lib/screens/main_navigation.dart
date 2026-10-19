import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/cart_controller.dart';
import '../../core/theme/app_colors.dart';
import 'checkout/cart_screen.dart';
import 'home/home_screen.dart';
import 'orders/order_history_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationController extends GetxController {
  final currentIndex = 0.obs;
  final visitedTabs = <int>{0}.obs;

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
    final cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Obx(() {
        final current = nav.currentIndex.value;
        return IndexedStack(
          index: current,
          children: [
            const HomeScreen(),
            nav.isTabVisited(1) ? const CartScreen() : const SizedBox.shrink(),
            nav.isTabVisited(2) ? const OrderHistoryScreen() : const SizedBox.shrink(),
            nav.isTabVisited(3) ? const ProfileScreen() : const SizedBox.shrink(),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        final current = nav.currentIndex.value;
        final cartCount = cartController.totalItemCount;

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
                    icon: Icons.shopping_bag_outlined,
                    label: 'cart'.tr,
                    isSelected: current == 1,
                    badgeCount: cartCount,
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
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
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
