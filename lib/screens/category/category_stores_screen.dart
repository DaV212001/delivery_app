import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/restaurant_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/special_offer.dart';
import '../../models/store.dart';
import '../../services/property_service.dart';
import '../../utils/string_utils.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/floating_cart_bar.dart';
import '../home/widgets/home_filter_bottom_sheet.dart';
import '../home/widgets/restaurant_list_item.dart';

class CategoryStoresScreen extends StatefulWidget {
  final CircularCategory category;
  final bool isDeliveryType;

  const CategoryStoresScreen({
    super.key,
    required this.category,
    this.isDeliveryType = false,
  });

  @override
  State<CategoryStoresScreen> createState() => _CategoryStoresScreenState();
}

class _CategoryStoresScreenState extends State<CategoryStoresScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final RxString _localSearchQuery = ''.obs;
  final RxBool _isLoadingCategoryStores = false.obs;
  final RxList<Store> _categoryStores = <Store>[].obs;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
    _entranceController.forward();

    // Fetch stores specifically associated with this category or delivery type from the API
    final catId = int.tryParse(widget.category.id);
    if (catId != null && catId > 0) {
      _isLoadingCategoryStores.value = true;
      final future = widget.isDeliveryType
          ? PropertyService.fetchStoresByDeliveryType(catId)
          : PropertyService.fetchStoresByCategory(catId);
      future.then((fetched) {
        if (mounted && fetched.isNotEmpty) {
          _categoryStores.assignAll(fetched);
        }
      }).whenComplete(() {
        if (mounted) _isLoadingCategoryStores.value = false;
      });
    }
  }

  List<Store> _getEffectiveStores(RestaurantController controller, String query) {
    if (_categoryStores.isNotEmpty) {
      var list = _categoryStores.toList();
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        list = list.where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.categoryDescription.toLowerCase().contains(q) ||
            (s.branch?.toLowerCase().contains(q) ?? false)).toList();
      }
      if (controller.filterRating45.value) {
        list = list.where((s) => s.rating >= 4.5).toList();
      }
      if (controller.filterUnder30Min.value) {
        list = list.where((s) {
          final isFast = s.deliveryTime.contains('10') ||
              s.deliveryTime.contains('15') ||
              s.deliveryTime.contains('20') ||
              s.deliveryTime.contains('25') ||
              s.deliveryTime.contains('30');
          return isFast;
        }).toList();
      }
      if (controller.filterOffers.value) {
        list = list.where((s) => s.deliveryFee.toLowerCase().contains('free')).toList();
      }
      if (controller.sortBy.value == 'rating') {
        list.sort((a, b) => b.rating.compareTo(a.rating));
      } else if (controller.sortBy.value == 'fastest') {
        final uLat = controller.userLat.value;
        final uLng = controller.userLng.value;
        list.sort((a, b) {
          final distA = a.calculateDistanceTo(userLat: uLat, userLng: uLng) ?? a.distanceKm;
          final distB = b.calculateDistanceTo(userLat: uLat, userLng: uLng) ?? b.distanceKm;
          return distA.compareTo(distB);
        });
      } else if (controller.sortBy.value == 'price') {
        list.sort((a, b) => (a.avgPricePerPerson ?? 0).compareTo(b.avgPricePerPerson ?? 0));
      }
      return list;
    }
    return controller.getStoresForCategory(widget.category.categoryKey, query: query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = Get.find<RestaurantController>();
    final cleanCategoryTitle = StringUtils.normalizeCategoryTitle(widget.category.name);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Hero(
              tag: 'category_icon_${widget.category.id}',
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.category.backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: (widget.category.imageUrl != null &&
                            widget.category.imageUrl!.trim().isNotEmpty)
                        ? AppNetworkImage(
                            imageUrl: widget.category.imageUrl!,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorWidget: Center(
                              child: Icon(
                                widget.category.icon ?? Icons.category_rounded,
                                color: widget.category.iconColor,
                                size: 20,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              widget.category.icon ?? Icons.category_rounded,
                              color: widget.category.iconColor,
                              size: 20,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cleanCategoryTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16.5,
                    ),
                  ),
                  Obx(() {
                    final query = _localSearchQuery.value;
                    final stores = _getEffectiveStores(controller, query);
                    final count = stores.length;
                    return Text(
                      count == 1 ? '1 ${'store_nearby'.tr}' : '$count ${'stores_nearby'.tr}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            tooltip: 'Filter stores',
            onPressed: () => HomeFilterBottomSheet.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // In-Category Search Field
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLow
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => _localSearchQuery.value = val,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search in $cleanCategoryTitle...',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                          fontSize: 13.5,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Obx(() {
                    if (_localSearchQuery.value.isNotEmpty) {
                      return GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _localSearchQuery.value = '';
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Quick Filter Pills Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(() {
                final rating45 = controller.filterRating45.value;
                final under30 = controller.filterUnder30Min.value;
                final offers = controller.filterOffers.value;

                return Row(
                  children: [
                    PillChip(
                      label: '⭐ ${'rating_45_plus'.tr}',
                      isSelected: rating45,
                      onTap: () =>
                          controller.filterRating45.value = !rating45,
                    ),
                    const SizedBox(width: 8),
                    PillChip(
                      label: '⚡ ${'fast_delivery_under_30'.tr}',
                      isSelected: under30,
                      onTap: () =>
                          controller.filterUnder30Min.value = !under30,
                    ),
                    const SizedBox(width: 8),
                    PillChip(
                      label: '🏷️ ${'special_offers_deals'.tr}',
                      isSelected: offers,
                      onTap: () =>
                          controller.filterOffers.value = !offers,
                    ),
                  ],
                );
              }),
            ),

            const SizedBox(height: 16),

            // Stores List
            Obx(() {
              final query = _localSearchQuery.value;
              final stores = _getEffectiveStores(controller, query);

              if (stores.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront_outlined,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'no_stores_found'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          query.isNotEmpty
                              ? 'try_searching_different'.tr
                              : 'no_stores_found'.tr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (query.isNotEmpty ||
                            controller.filterRating45.value ||
                            controller.filterUnder30Min.value ||
                            controller.filterOffers.value) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              _localSearchQuery.value = '';
                              controller.filterRating45.value = false;
                              controller.filterUnder30Min.value = false;
                              controller.filterOffers.value = false;
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text('reset'.tr),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: stores.map((store) {
                  return RestaurantListItem(store: store);
                }).toList(),
              );
            }),

            const SizedBox(height: 80),
          ],
        ),
      ),
    ),
  ),
  const FloatingCartBar(),
],
),
);
  }
}
