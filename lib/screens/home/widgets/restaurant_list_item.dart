import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/profile_controller.dart';
import '../../../controllers/restaurant_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/store.dart';
import '../../../utils/location_utils.dart';
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

    final themeColor = isDark ? AppColors.primaryFixedDim : AppColors.primary;

    final rawLocation = (store.friendlyLocation != null && store.friendlyLocation!.isNotEmpty)
        ? store.friendlyLocation
        : store.branch;
    final normalizedLocation = LocationUtils.prettifyAddress(rawLocation);
    final subtitleText = normalizedLocation.isNotEmpty ? normalizedLocation : store.categoryDescription;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22.0),
      child: InkWell(
        onTap: () => Get.to(() => RestaurantDetailScreen(restaurant: store)),
        borderRadius: BorderRadius.circular(18),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero / Cover Image Banner with Floating Favorite Button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AppNetworkImage(
                    imageUrl: store.heroImageUrl.isNotEmpty
                        ? store.heroImageUrl
                        : (store.logoUrl ?? ''),
                    height: 185,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                // Floating Favorite Heart Button (Top Right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Obx(() {
                    final isFav = restaurantController?.isFavorite(store.id) ?? false;
                    return Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => restaurantController?.toggleFavorite(store.id),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainerLow.withValues(alpha: 0.92)
                                : Colors.white.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 20,
                            color: isFav
                                ? AppColors.secondary
                                : (isDark ? Colors.white70 : const Color(0xFF374151)),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                // Closed Badge Indicator (Top Left if closed)
                if (store.isPastClosingTime)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: Color(0xFFFBBF24),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'closed'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // 2. Store Info Section (Logo + Name/Rating + Friendly Location + Metadata)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circular Store Logo
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: AppNetworkImage(
                      imageUrl: (store.logoUrl != null && store.logoUrl!.isNotEmpty)
                          ? store.logoUrl!
                          : store.heroImageUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Name, Rating, Friendly Location & Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store Name & Star Rating
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              store.displayNameWithBranch,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: AppColors.starGold,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                store.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Normalized Friendly Location Subtitle
                      if (subtitleText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],

                      const SizedBox(height: 6),

                      // Single-Line Metadata Row: Distance, Time, and Operating Status (Guaranteed single line on all screen sizes)
                      Obx(() {
                        final curLat = restaurantController?.userLat.value ??
                            profileController?.selectedAddress.value?.latitude;
                        final curLng = restaurantController?.userLng.value ??
                            profileController?.selectedAddress.value?.longitude;

                        final dist = store.calculateDistanceTo(userLat: curLat, userLng: curLng) ??
                            store.distanceKm;
                        final distText = LocationUtils.formatDistanceKm(dist).toUpperCase();

                        final timeText = store.deliveryTime.contains('min')
                            ? store.deliveryTime
                            : '${store.deliveryTime} mins';

                        final isOpen = store.isOpen;
                        final statusLabel = isOpen ? 'open_now'.tr : 'closed'.tr;
                        final statusColor = isOpen
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626);

                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _MetadataItem(
                                icon: Icons.route_outlined,
                                iconColor: themeColor,
                                label: distText,
                              ),
                              const SizedBox(width: 14),
                              _MetadataItem(
                                icon: Icons.schedule_rounded,
                                iconColor: themeColor,
                                label: timeText,
                              ),
                              const SizedBox(width: 14),
                              _MetadataItem(
                                icon: Icons.circle,
                                iconSize: 7,
                                iconColor: statusColor,
                                label: statusLabel,
                                labelColor: statusColor,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final double? iconSize;
  final Color iconColor;
  final String label;
  final Color? labelColor;

  const _MetadataItem({
    required this.icon,
    this.iconSize,
    required this.iconColor,
    required this.label,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize ?? 13,
          color: iconColor,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: labelColor ??
                (isDark
                    ? AppColors.darkOnSurfaceVariant
                    : const Color(0xFF4B5563)),
          ),
        ),
      ],
    );
  }
}
