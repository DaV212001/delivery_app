import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/delivery_item.dart';
import '../../../widgets/common/app_widgets.dart';

class DifferentPropertyBatchSheet extends StatelessWidget {
  final String currentStoreName;
  final String newStoreName;
  final DeliveryItem newItem;
  final VoidCallback onFinishCurrentBatch;
  final VoidCallback onSaveForNextBatch;

  const DifferentPropertyBatchSheet({
    super.key,
    required this.currentStoreName,
    required this.newStoreName,
    required this.newItem,
    required this.onFinishCurrentBatch,
    required this.onSaveForNextBatch,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentStoreName,
    required String newStoreName,
    required DeliveryItem newItem,
    required VoidCallback onFinishCurrentBatch,
    required VoidCallback onSaveForNextBatch,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DifferentPropertyBatchSheet(
        currentStoreName: currentStoreName,
        newStoreName: newStoreName,
        newItem: newItem,
        onFinishCurrentBatch: onFinishCurrentBatch,
        onSaveForNextBatch: onSaveForNextBatch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayCurrentStore = currentStoreName.isNotEmpty ? currentStoreName : 'Current Store';
    final displayNewStore = newStoreName.isNotEmpty ? newStoreName : 'New Store';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Store icon badge
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'different_store_title'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),

          // Explanation
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
              children: [
                const TextSpan(text: 'You already have items in your cart from '),
                TextSpan(
                  text: displayCurrentStore,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const TextSpan(
                  text: '.\nEach order batch must be from a single store. Finish the current batch first, or save it for the next batch to add items from ',
                ),
                TextSpan(
                  text: displayNewStore,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Primary choice: Save it for the next batch
          AppButton(
            text: 'save_for_next_batch'.tr,
            icon: const Icon(Icons.bookmark_add_outlined, color: Colors.white),
            onPressed: onSaveForNextBatch,
          ),
          const SizedBox(height: 12),

          // Secondary choice: Finish current batch first
          AppButton(
            text: 'finish_current_batch'.tr,
            isSecondary: true,
            icon: const Icon(Icons.shopping_cart_checkout_rounded, color: AppColors.primary),
            onPressed: onFinishCurrentBatch,
          ),
          const SizedBox(height: 10),

          // Cancel option
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'cancel'.tr,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
