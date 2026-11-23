import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/restaurant_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/special_offer.dart';
import '../../../utils/api_call_status.dart';
import '../../../utils/string_utils.dart';
import '../../../widgets/common/app_widgets.dart';
import '../../../widgets/skeletons/skeleton_loaders.dart';
import '../../category/category_stores_screen.dart';

class CircularCategoriesBar extends StatelessWidget {
  const CircularCategoriesBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RestaurantController>();

    return Obx(() {
      final isLoading = controller.status.value == ApiCallStatus.loading;
      final categories = controller.circularCategories;

      if (isLoading) {
        return SizedBox(
          height: 106,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) => const ShimmerCircularCategorySkeleton(),
          ),
        );
      }

      if (categories.isEmpty) {
        return const SizedBox.shrink();
      }

      return SizedBox(
        height: 106,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final cat = categories[index];

            return _CircularCategoryItem(
              category: cat,
              isSelected: false,
              onTap: () {
                Get.to(
                  () => CategoryStoresScreen(category: cat),
                  transition: Transition.rightToLeftWithFade,
                  curve: Curves.easeOutCubic,
                  duration: const Duration(milliseconds: 360),
                );
              },
            );
          },
        ),
      );
    });
  }
}

class _CircularCategoryItem extends StatefulWidget {
  final CircularCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CircularCategoryItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CircularCategoryItem> createState() => _CircularCategoryItemState();
}

class _CircularCategoryItemState extends State<_CircularCategoryItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = widget.category.imageUrl != null &&
        widget.category.imageUrl!.trim().isNotEmpty;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Hero(
                tag: 'category_icon_${widget.category.id}',
                child: Material(
                  type: MaterialType.transparency,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: widget.category.backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2.2,
                      ),
                      boxShadow: widget.isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: hasImage
                          ? AppNetworkImage(
                              imageUrl: widget.category.imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorWidget: Center(
                                child: Icon(
                                  widget.category.icon ?? Icons.category_rounded,
                                  color: widget.category.iconColor,
                                  size: 28,
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                widget.category.icon ?? Icons.category_rounded,
                                color: widget.category.iconColor,
                                size: 28,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                StringUtils.normalizeCategoryTitle(widget.category.name),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                  height: 1.15,
                  color: widget.isSelected
                      ? AppColors.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
