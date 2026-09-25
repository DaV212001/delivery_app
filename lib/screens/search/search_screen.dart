import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/restaurant_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/restaurant.dart';
import '../../utils/templates/loaded_widgets_template.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/skeletons/skeleton_loaders.dart';
import '../restaurant/restaurant_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final restaurantController = Get.find<RestaurantController>();

  @override
  void initState() {
    super.initState();
    _searchController.text = restaurantController.searchQuery.value;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'search'.tr,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  onChanged: (val) => restaurantController.searchQuery.value = val,
                  decoration: InputDecoration(
                    hintText: 'search_hint'.tr,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: Obx(() {
                      if (restaurantController.searchQuery.value.isNotEmpty) {
                        return IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            restaurantController.searchQuery.value = '';
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
            ),

            // Filter Pills Row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Obx(
                  () => Row(
                    children: [
                      PillChip(
                        label: '⭐ ${'rating_45_plus'.tr}',
                        isSelected: restaurantController.filterRating45.value,
                        onTap: () {
                          restaurantController.filterRating45.value =
                              !restaurantController.filterRating45.value;
                        },
                      ),
                      const SizedBox(width: 8),
                      PillChip(
                        label: '⏱ ${'fast_delivery_under_30'.tr}',
                        isSelected: restaurantController.filterUnder30Min.value,
                        onTap: () {
                          restaurantController.filterUnder30Min.value =
                              !restaurantController.filterUnder30Min.value;
                        },
                      ),
                      const SizedBox(width: 8),
                      PillChip(
                        label: '🎁 ${'free_delivery'.tr}',
                        isSelected: restaurantController.filterOffers.value,
                        onTap: () {
                          restaurantController.filterOffers.value =
                              !restaurantController.filterOffers.value;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Results Count & List
            Expanded(
              child: Obx(() {
                final status = restaurantController.status.value;
                final results = restaurantController.filteredRestaurants;

                return LoadedWidget(
                  status: status,
                  loadingChild: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 4,
                    itemBuilder: (context, index) => const ShimmerRestaurantCardSkeleton(),
                  ),
                  emptyChild: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'no_stores_items_found'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'try_searching_different'.tr,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  child: results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'no_matching_results'.tr,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'try_searching_different'.tr,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final r = results[index];
                            return _SearchResultTile(restaurant: r);
                          },
                        ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Restaurant restaurant;

  const _SearchResultTile({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : null;

    return GestureDetector(
      onTap: () => Get.to(() => RestaurantDetailScreen(restaurant: restaurant)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AppNetworkImage(
                imageUrl: restaurant.heroImageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      RatingBadge(rating: restaurant.rating),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.cuisine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          restaurant.deliveryTime,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (profileController != null)
                        Obx(() {
                          final userLat = profileController.selectedAddress.value?.latitude;
                          final userLng = profileController.selectedAddress.value?.longitude;
                          final distBadge = restaurant.formattedDistanceBadgeTo(
                            userLat: userLat,
                            userLng: userLng,
                          );
                          if (distBadge.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                distBadge,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                  if (restaurant.branch != null && restaurant.branch!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            restaurant.branch!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}
