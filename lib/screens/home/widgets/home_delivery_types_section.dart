import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../controllers/restaurant_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/category_model.dart';
import '../../../models/special_offer.dart';
import '../../../utils/api_call_status.dart';
import '../../../utils/string_utils.dart';
import '../../../widgets/common/app_widgets.dart';
import '../../category/category_stores_screen.dart';

/// An appealing horizontal card section displaying Delivery Types that possess images,
/// placed right above the "All Nearby" restaurants section on HomeScreen.
class HomeDeliveryTypesSection extends StatelessWidget {
  const HomeDeliveryTypesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = Get.find<RestaurantController>();

    return Obx(() {
      final isLoading = controller.status.value == ApiCallStatus.loading;
      final rawTypes = controller.deliveryTypes;

      // Filter exclusively for delivery types with valid images
      final typesWithImages = rawTypes.where((type) {
        final img = type.image.trim();
        return img.isNotEmpty && img != 'null' && img != 'undefined';
      }).toList();

      // Loading shimmer state
      if (isLoading && typesWithImages.isEmpty) {
        return _buildShimmer(isDark);
      }

      // If no delivery types have images, hide completely
      if (typesWithImages.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 3.5,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'delivery_services'.tr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${typesWithImages.length} services',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Horizontal Delivery Types Carousel
          SizedBox(
            height: 112,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: typesWithImages.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final type = typesWithImages[index];
                return _DeliveryTypeCard(
                  key: ValueKey('delivery_type_${type.id}'),
                  type: type,
                  onTap: () {
                    Get.to(
                      () => CategoryStoresScreen(
                        category: CircularCategory(
                          id: type.id.toString(),
                          name: type.displayName,
                          categoryKey: type.displayName.toLowerCase(),
                          imageUrl: type.image,
                          icon: Icons.local_shipping_rounded,
                          backgroundColor: const Color(0xFFFFEDD5),
                          iconColor: AppColors.primary,
                        ),
                        isDeliveryType: true,
                      ),
                      transition: Transition.rightToLeftWithFade,
                      curve: Curves.easeOutCubic,
                      duration: const Duration(milliseconds: 360),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildShimmer(bool isDark) {
    final baseColor =
        isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerHigh;
    final highlightColor =
        isDark ? AppColors.darkSurfaceContainerHighest : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: SizedBox(
        height: 112,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) => Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: 156,
              height: 112,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryTypeCard extends StatefulWidget {
  final CategoryModel type;
  final VoidCallback onTap;

  const _DeliveryTypeCard({
    super.key,
    required this.type,
    required this.onTap,
  });

  @override
  State<_DeliveryTypeCard> createState() => _DeliveryTypeCardState();
}

class _DeliveryTypeCardState extends State<_DeliveryTypeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalizedTitle = StringUtils.normalizeCategoryTitle(widget.type.displayName);

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: Container(
          width: 156,
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Background Image with Sanitize & Cache
                AppNetworkImage(
                  imageUrl: widget.type.image,
                  fit: BoxFit.cover,
                  borderRadius: 18,
                ),

                // 2. High-contrast smooth gradient scrim
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.30),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.20, 0.58, 1.0],
                    ),
                  ),
                ),

                // 3. Normalized Title at bottom
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Text(
                    normalizedTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          offset: Offset(0, 1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
