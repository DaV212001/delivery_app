import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/restaurant_controller.dart';
import '../../constants/pages.dart';
import '../../core/theme/app_colors.dart';
import '../../utils/api_call_status.dart';
import '../../utils/templates/loaded_widgets_template.dart';
import '../../widgets/skeletons/skeleton_loaders.dart';
import 'widgets/circular_categories_bar.dart';
import 'widgets/delivery_address_pill.dart';
import 'widgets/home_corporate_section.dart';
import 'widgets/home_courier_section.dart';
import 'widgets/home_filter_bottom_sheet.dart';
import 'widgets/promotional_carousel_section.dart';
import 'widgets/restaurant_list_item.dart';
import 'widgets/special_offers_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250) {
      if (Get.isRegistered<RestaurantController>()) {
        Get.find<RestaurantController>().loadMoreNearbyProperties();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (Get.isRegistered<RestaurantController>()) {
        Get.find<RestaurantController>().requestLocationAndCalculateDistances();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final restaurantController = Get.find<RestaurantController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await restaurantController.loadRestaurants();
              await restaurantController.requestLocationAndCalculateDistances();
            },
            child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          children: [
            // 1. Promotional Carousel Slider Section (Full-width edge-to-edge with frosted translucent header pill)
            Obx(
              () => PromotionalCarouselSection(
                promotions: restaurantController.promotions,
                isLoading:
                    restaurantController.status.value == ApiCallStatus.loading,
              ),
            ),

            // 2. Overlapping Curved Bottom Card (yenetena_mobile discover_ethiopia_optimized pattern)
            Transform.translate(
              offset: const Offset(0, -22),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.search),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainerLow
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'search_hint'.tr,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.tune_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 1. Circular Categories Row (Matching Screenshot)
                    const CircularCategoriesBar(),

                    const SizedBox(height: 22),

                    // 2. Special Offers Section (Matching Screenshot)
                    SpecialOffersSection(
                      onFilterTap: () => HomeFilterBottomSheet.show(context),
                    ),

                    // 3. Courier Delivery Banner ("Thinking of sending anything?")
                    const HomeCourierSection(),

                    // Corporate Service Card (displayed under courier service card if type is 1 and company & branch id != 0)
                    Obx(() {
                      if (!Get.isRegistered<AuthController>()) {
                        return const SizedBox.shrink();
                      }
                      final auth = Get.find<AuthController>();
                      if (!auth.user.isCorporateUser) {
                        return const SizedBox.shrink();
                      }
                      return const HomeCorporateSection();
                    }),

                    const SizedBox(height: 24),

                    // 4. "All Restaurants Nearby" Section Header (Matching Screenshot)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'all_restaurants_nearby'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 19,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => HomeFilterBottomSheet.show(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 1.3,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.tune_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'filter'.tr,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Location Services / Permission Notice Banner (if disabled or denied, with no button)
                    Obx(() {
                      final isServiceOff =
                          restaurantController.locationServiceDisabled.value;
                      final isDenied =
                          restaurantController.locationPermissionDenied.value;
                      final hasLocation =
                          restaurantController.userLat.value != null;

                      if ((isServiceOff || isDenied) && !hasLocation) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => restaurantController.openLocationFix(),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2A1517)
                                      : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF7F1D1D)
                                        : const Color(0xFFFECACA),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: isDark ? 0.2 : 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626)
                                            .withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.location_off_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isServiceOff
                                                ? 'location_services_off_title'.tr
                                                : 'location_permission_needed_title'.tr,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? const Color(0xFFFCA5A5)
                                                  : const Color(0xFF991B1B),
                                              fontSize: 13.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isServiceOff
                                                ? 'location_services_off_sub'.tr
                                                : 'location_permission_banner'.tr,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: isDark
                                                  ? const Color(0xFFE2E8F0)
                                                      .withValues(alpha: 0.8)
                                                  : const Color(0xFF7F1D1D)
                                                      .withValues(alpha: 0.85),
                                              fontSize: 11.5,
                                              height: 1.25,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 13,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    const SizedBox(height: 14),

                    // Vertical Restaurants List with Skeleton Support
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Obx(() {
                        final status = restaurantController.status.value;
                        final list = restaurantController.filteredRestaurants;

                        return LoadedWidget(
                          status: status,
                          onReload: () => restaurantController.loadRestaurants(),
                          loadingChild: Column(
                            children: List.generate(
                              4,
                              (_) => const ShimmerRestaurantCardSkeleton(),
                            ),
                          ),
                          emptyChild: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.storefront_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'no_restaurants_found'.tr,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          child: list.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 40),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.storefront_outlined,
                                          size: 48,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'no_restaurants_found'.tr,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  children: list.map((restaurant) {
                                    return RestaurantListItem(store: restaurant);
                                  }).toList(),
                                ),
                        );
                      }),
                    ),

                    // Infinite Scroll Loading Indicator
                    Obx(() {
                      if (restaurantController.isLoadingMoreNearby.value) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 3. Floating Transparent Small Pill at Top of Home Screen
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.88,
                ),
                child: const DeliveryAddressPill(),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
  }
}

