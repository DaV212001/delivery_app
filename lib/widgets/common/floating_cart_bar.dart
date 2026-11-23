import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/pages.dart';
import '../../controllers/cart_controller.dart';
import '../../core/theme/app_colors.dart';

/// Reusable floating bottom cart bar.
/// Matches the sticky floater on restaurant detail screens.
/// If [bottom] is supplied, it positions itself at that exact offset in a [Stack].
/// Otherwise, it defaults to `MediaQuery.of(context).padding.bottom + 16`.
class FloatingCartBar extends StatelessWidget {
  final double? bottom;
  final VoidCallback? onTap;

  const FloatingCartBar({
    super.key,
    this.bottom,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CartController>()) return const SizedBox.shrink();
    final cartController = Get.find<CartController>();

    return Obx(() {
      final cartCount = cartController.totalItemCount;
      if (cartCount == 0) return const SizedBox.shrink();

      final effectiveBottom = bottom ?? (MediaQuery.of(context).padding.bottom + 16);

      final bar = GestureDetector(
        onTap: onTap ?? () => Get.toNamed(AppRoutes.cart),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.38),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$cartCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'view_cart'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${cartController.total.toStringAsFixed(2)} ${cartController.displayCurrency}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      );

      return Positioned(
        left: 20,
        right: 20,
        bottom: effectiveBottom,
        child: bar,
      );
    });
  }
}
