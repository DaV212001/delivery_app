import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../controllers/restaurant_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/promotion.dart';
import '../../../widgets/common/app_widgets.dart';
import '../../restaurant/restaurant_detail_screen.dart';

class PromotionalCarouselSection extends StatefulWidget {
  final List<Promotion> promotions;
  final bool isLoading;

  const PromotionalCarouselSection({
    super.key,
    required this.promotions,
    this.isLoading = false,
  });

  @override
  State<PromotionalCarouselSection> createState() =>
      _PromotionalCarouselSectionState();
}

class _PromotionalCarouselSectionState
    extends State<PromotionalCarouselSection> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const _PromotionalCarouselSkeleton();
    }

    final restaurantController = Get.find<RestaurantController>();

    if (widget.promotions.isEmpty) {
      return const SizedBox(
        height: 180,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 290,
      width: double.infinity,
      child: Stack(
        children: [
          // 1. Edge-to-edge Carousel Slider
          CarouselSlider.builder(
            itemCount: widget.promotions.length,
            itemBuilder: (context, index, realIndex) {
              final promo = widget.promotions[index];
              return GestureDetector(
                onTap: () {
                  if (promo.storeId != null) {
                    final store = restaurantController.restaurants
                        .firstWhereOrNull((s) => s.id == promo.storeId);
                    if (store != null) {
                      Get.to(() => RestaurantDetailScreen(restaurant: store));
                    }
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Slide Hero Background Image
                    AppNetworkImage(
                      imageUrl: promo.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 0,
                    ),

                    // Layered Gradient Overlay for Text and Top Pill Contrast
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.65),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.85),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Promotional Copy (Badge, Title, Subtitle)
                    Positioned(
                      left: 20,
                      right: 90,
                      bottom: 42,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (promo.badge != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                promo.badge!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            promo.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            promo.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              shadows: const [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            options: CarouselOptions(
              height: 290,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 700),
              autoPlayCurve: Curves.easeInOutCubic,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),

          // 2. Bottom-Right Animated Pill Dots Indicator (yenetena_mobile pattern)
          Positioned(
            bottom: 38,
            right: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: widget.promotions.asMap().entries.map((entry) {
                final isActive = _currentIndex == entry.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: isActive ? 22.0 : 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionalCarouselSkeleton extends StatelessWidget {
  const _PromotionalCarouselSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 290,
      width: double.infinity,
      child: Shimmer.fromColors(
        baseColor: isDark ? AppColors.darkSurfaceContainer : const Color(0xFFE2E8F0),
        highlightColor:
            isDark ? AppColors.darkSurfaceContainerHigh : const Color(0xFFF1F5F9),
        child: Container(
          color: isDark ? AppColors.darkSurface : Colors.white,
        ),
      ),
    );
  }
}
