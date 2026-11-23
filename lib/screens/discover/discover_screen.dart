import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_assets.dart';
import '../../controllers/restaurant_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/restaurant.dart';
import '../../models/special_offer.dart';
import '../../utils/string_utils.dart';
import '../../widgets/common/app_widgets.dart';
import '../category/category_stores_screen.dart';
import '../home/widgets/restaurant_list_item.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Pre-configured rich discovery categories matching the Discover screenshot
  static final List<CircularCategory> _defaultDiscoveryCategories = [
    const CircularCategory(
      id: 'cat_ethiopost',
      name: 'Ethiopost',
      categoryKey: 'courier',
      icon: Icons.local_post_office_rounded,
      backgroundColor: Color(0xFF0284C7),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_books',
      name: 'Books',
      categoryKey: 'books',
      imageUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=300&q=80',
      icon: Icons.menu_book_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_burger',
      name: 'Burger',
      categoryKey: 'burger',
      imageUrl: AppAssets.burgerFeatured,
      icon: Icons.lunch_dining_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_pizza',
      name: 'Pizza',
      categoryKey: 'pizza',
      imageUrl: AppAssets.pizzaFeatured,
      icon: Icons.local_pizza_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_chinese',
      name: 'Chinese cuisine',
      categoryKey: 'chinese',
      imageUrl: AppAssets.ramenSearch3,
      icon: Icons.ramen_dining_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_mart',
      name: 'Mart',
      categoryKey: 'grocery',
      imageUrl: AppAssets.groceryHero,
      icon: Icons.shopping_cart_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_chicken',
      name: 'Chicken',
      categoryKey: 'chicken',
      imageUrl: 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=300&q=80',
      icon: Icons.kebab_dining_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_sandwich',
      name: 'Sandwich',
      categoryKey: 'sandwich',
      imageUrl: AppAssets.sourdoughItem,
      icon: Icons.bakery_dining_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_shakes',
      name: 'Shakes and smoothies',
      categoryKey: 'beverages',
      imageUrl: AppAssets.juiceItem,
      icon: Icons.local_drink_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_arabian',
      name: 'Arabian',
      categoryKey: 'arabian',
      imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=300&q=80',
      icon: Icons.dinner_dining_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_italian',
      name: 'Italian',
      categoryKey: 'italian',
      imageUrl: 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?auto=format&fit=crop&w=300&q=80',
      icon: Icons.set_meal_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_seafood',
      name: 'Seafood',
      categoryKey: 'seafood',
      imageUrl: AppAssets.pokeSearch2,
      icon: Icons.water_drop_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_bakery',
      name: 'Bakery.',
      categoryKey: 'bakery',
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=300&q=80',
      icon: Icons.breakfast_dining_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_alcohol',
      name: 'Alcohol',
      categoryKey: 'alcohol',
      imageUrl: 'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&w=300&q=80',
      icon: Icons.wine_bar_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_healthy',
      name: 'Healthy Choice',
      categoryKey: 'healthy',
      imageUrl: AppAssets.saladBowl,
      icon: Icons.eco_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_pharmacy',
      name: 'Pharmacy',
      categoryKey: 'pharmacy',
      imageUrl: AppAssets.pharmacyHero,
      icon: Icons.medication_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_gifts',
      name: 'Gifts & Presents',
      categoryKey: 'gifts',
      imageUrl: AppAssets.flowersHero,
      icon: Icons.card_giftcard_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_desserts',
      name: 'Cakes & Desserts',
      categoryKey: 'desserts',
      imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=300&q=80',
      icon: Icons.cake_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_fruits',
      name: 'Fresh Fruits',
      categoryKey: 'fruits',
      imageUrl: AppAssets.strawberryItem,
      icon: Icons.apple_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
    const CircularCategory(
      id: 'cat_beauty',
      name: 'Beauty & Care',
      categoryKey: 'beauty',
      imageUrl: AppAssets.handCreamItem,
      icon: Icons.spa_rounded,
      backgroundColor: Color(0xFFFF8A65),
      iconColor: Colors.white,
    ),
  ];

  List<CircularCategory> _getCombinedCategories(RestaurantController controller) {
    if (controller.circularCategories.isNotEmpty) {
      // Map API categories, and append any discovery categories not present in API
      final existingKeys = controller.circularCategories
          .map((c) => c.categoryKey.toLowerCase())
          .toSet();

      final list = <CircularCategory>[...controller.circularCategories];
      for (final cat in _defaultDiscoveryCategories) {
        if (!existingKeys.contains(cat.categoryKey.toLowerCase())) {
          list.add(cat);
        }
      }
      return list;
    }
    return _defaultDiscoveryCategories;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final restaurantController = Get.isRegistered<RestaurantController>()
        ? Get.find<RestaurantController>()
        : Get.put(RestaurantController());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Obx(() {
          final query = _searchQuery.value.trim().toLowerCase();
          final isSearching = query.isNotEmpty;
          final categories = _getCombinedCategories(restaurantController);

          List<Store> matchingStores = [];
          if (isSearching) {
            matchingStores = restaurantController.restaurants.where((r) {
              final inName = r.name.toLowerCase().contains(query);
              final inCuisine = r.cuisine.toLowerCase().contains(query);
              final inCategory = r.categoryDescription.toLowerCase().contains(query);
              final inBranch = (r.branch ?? '').toLowerCase().contains(query);
              final inMenu = r.menuItems.any((m) => m.name.toLowerCase().contains(query));
              return inName || inCuisine || inCategory || inBranch || inMenu;
            }).toList();
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Discover Title Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text(
                    'discover'.tr,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      letterSpacing: -0.4,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),

              // 2. Search Input Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Container(
                    height: 50,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainerLow
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkOutlineVariant
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => _searchQuery.value = val,
                      textAlignVertical: TextAlignVertical.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        fillColor: Colors.transparent,
                        hintText: 'search_restaurants_foods'.tr,
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          size: 22,
                        ),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchQuery.value = '';
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ),
              ),

              // If active searching, show matching live search results
              if (isSearching) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: Text(
                      '${matchingStores.length} ${matchingStores.length == 1 ? 'store_nearby'.tr : 'stores_nearby'.tr}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (matchingStores.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 56,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'no_stores_items_found'.tr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'try_searching_different'.tr,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final store = matchingStores[index];
                          return RestaurantListItem(store: store);
                        },
                        childCount: matchingStores.length,
                      ),
                    ),
                  ),
              ] else ...[
                // 3. Section Title: "What are you looking for today"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Text(
                      'what_are_you_looking_for_today'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),

                // 4. 4-Column Category Grid with generous breathing room
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.65,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cat = categories[index];
                        return _DiscoverCategoryCard(
                          category: cat,
                          onTap: () {
                            Get.to(
                              () => CategoryStoresScreen(category: cat),
                              transition: Transition.rightToLeftWithFade,
                              curve: Curves.easeOutCubic,
                              duration: const Duration(milliseconds: 320),
                            );
                          },
                        );
                      },
                      childCount: categories.length,
                    ),
                  ),
                ),
              ],

              // Bottom clearance so floating cart bar and bottom nav don't block content
              const SliverToBoxAdapter(
                child: SizedBox(height: 84),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _DiscoverCategoryCard extends StatefulWidget {
  final CircularCategory category;
  final VoidCallback onTap;

  const _DiscoverCategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  State<_DiscoverCategoryCard> createState() => _DiscoverCategoryCardState();
}

class _DiscoverCategoryCardState extends State<_DiscoverCategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cat = widget.category;
    final hasImage = cat.imageUrl != null && cat.imageUrl!.trim().isNotEmpty;

    // Use warm coral/orange gradient matching the Discover design, with special treatment for brand items
    final isCourier = cat.categoryKey == 'courier';
    final circleGradient = isCourier
        ? const LinearGradient(
            colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final cleanTitle = StringUtils.normalizeCategoryTitle(cat.name);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Category Badge (Clean, flat gradient without glowing shadow)
            Hero(
              tag: 'discover_category_${cat.id}',
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: circleGradient,
                  ),
                  child: ClipOval(
                    child: hasImage
                        ? AppNetworkImage(
                            imageUrl: cat.imageUrl!,
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                            errorWidget: Center(
                              child: Icon(
                                cat.icon ?? Icons.category_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              cat.icon ?? Icons.category_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),

            // Category Title with Flexible constraint to prevent any RenderFlex overflow
            Flexible(
              child: Text(
                cleanTitle,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.normal,
                  height: 1.15,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
