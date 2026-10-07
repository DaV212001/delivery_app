import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/restaurant_controller.dart';
import '../../../core/theme/app_colors.dart';

class HomeFilterBottomSheet extends StatelessWidget {
  const HomeFilterBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HomeFilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = Get.find<RestaurantController>();

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'filter_and_sort'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              TextButton(
                onPressed: () {
                  controller.sortBy.value = 'recommended';
                  controller.filterRating45.value = false;
                  controller.filterUnder30Min.value = false;
                  controller.filterOffers.value = false;
                  controller.selectedCircularCategory.value = '';
                },
                child: Text(
                  'reset'.tr,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Sort Options
          Text(
            'sort_by'.tr,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          Obx(() {
            final currentSort = controller.sortBy.value;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterOptionChip(
                  label: 'recommended'.tr,
                  isSelected: currentSort == 'recommended',
                  onTap: () => controller.sortBy.value = 'recommended',
                ),
                _FilterOptionChip(
                  label: 'top_rated'.tr,
                  isSelected: currentSort == 'rating',
                  onTap: () => controller.sortBy.value = 'rating',
                ),
                _FilterOptionChip(
                  label: 'fastest_delivery'.tr,
                  isSelected: currentSort == 'fastest',
                  onTap: () {
                    controller.sortBy.value = 'fastest';
                    if (controller.userLat.value == null) {
                      controller.requestLocationAndCalculateDistances(promptIfDeniedForever: true);
                    }
                  },
                ),
                _FilterOptionChip(
                  label: 'lowest_price'.tr,
                  isSelected: currentSort == 'price',
                  onTap: () => controller.sortBy.value = 'price',
                ),
              ],
            );
          }),

          const SizedBox(height: 18),

          // Quick Filter Toggles
          Text(
            'preferences'.tr,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          Obx(() {
            return Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('rating_45_plus'.tr, style: const TextStyle(fontSize: 14)),
                  value: controller.filterRating45.value,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) => controller.filterRating45.value = val,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('fast_delivery_under_30'.tr, style: const TextStyle(fontSize: 14)),
                  value: controller.filterUnder30Min.value,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) => controller.filterUnder30Min.value = val,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('special_offers_deals'.tr, style: const TextStyle(fontSize: 14)),
                  value: controller.filterOffers.value,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) => controller.filterOffers.value = val,
                ),
              ],
            );
          }),

          const SizedBox(height: 16),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'apply_filters'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
