import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/profile_controller.dart';
import '../../../controllers/restaurant_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/store.dart';
import '../../../widgets/common/app_widgets.dart';
import '../../restaurant/restaurant_detail_screen.dart';

class RestaurantListItem extends StatelessWidget {
  final Store store;

  const RestaurantListItem({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : null;
    final restaurantController = Get.isRegistered<RestaurantController>()
        ? Get.find<RestaurantController>()
        : null;

    return InkWell(
      onTap: () => Get.to(() => RestaurantDetailScreen(restaurant: store)),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 80x80 Square Store Logo / Thumbnail
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: AppNetworkImage(
                      imageUrl: store.heroImageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Store Information Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store Name with Star Rating
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              store.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                store.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Outlined Chips (Distance & Time)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Obx(() {
                            // Prioritize user's live current GPS location, then selected address
                            final curLat = restaurantController?.userLat.value ??
                                profileController?.selectedAddress.value?.latitude;
                            final curLng = restaurantController?.userLng.value ??
                                profileController?.selectedAddress.value?.longitude;

                            final distBadge = store.formattedDistanceBadgeTo(
                              userLat: curLat,
                              userLng: curLng,
                            );
                            if (distBadge.isEmpty) return const SizedBox.shrink();
                            return _InfoBadgeChip(label: distBadge);
                          }),
                          _InfoBadgeChip(label: store.formattedTimeBadge),
                        ],
                      ),

                      // Property friendly location
                      if (store.branch != null && store.branch!.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                store.branch!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Operating / Schedule status
                      if (store.openStatusText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: store.isPastClosingTime
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                store.openStatusText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: store.isPastClosingTime
                                      ? const Color(0xFFDC2626)
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: store.isPastClosingTime ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Subtle divider between list items
            Divider(
              height: 1,
              thickness: 0.8,
              color: isDark
                  ? AppColors.darkOutlineVariant.withValues(alpha: 0.5)
                  : const Color(0xFFF1F5F9),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBadgeChip extends StatelessWidget {
  final String label;

  const _InfoBadgeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.primaryFixedDim : AppColors.primary,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? AppColors.primaryFixed : AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
