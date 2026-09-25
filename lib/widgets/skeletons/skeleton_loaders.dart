import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerHigh;
    final highlightColor = isDark ? AppColors.darkSurfaceContainerHighest : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          shape: shape,
          borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerRestaurantCardSkeleton extends StatelessWidget {
  const ShimmerRestaurantCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const ShimmerBox(width: 90, height: 90, borderRadius: 16),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: double.infinity, height: 18, borderRadius: 6),
                const SizedBox(height: 8),
                const FractionallySizedBox(
                  widthFactor: 0.7,
                  child: ShimmerBox(height: 14, borderRadius: 6),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: const [
                      ShimmerBox(width: 48, height: 14, borderRadius: 4),
                      SizedBox(width: 12),
                      ShimmerBox(width: 70, height: 14, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerBentoCardSkeleton extends StatelessWidget {
  const ShimmerBentoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: const ShimmerBox(
        width: double.infinity,
        height: 220,
        borderRadius: 24,
      ),
    );
  }
}

class ShimmerMenuItemSkeleton extends StatelessWidget {
  const ShimmerMenuItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: ShimmerBox(height: 18, borderRadius: 6),
                ),
                SizedBox(height: 8),
                ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
                SizedBox(height: 4),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: ShimmerBox(height: 14, borderRadius: 4),
                ),
                SizedBox(height: 12),
                ShimmerBox(width: 60, height: 18, borderRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const ShimmerBox(width: 80, height: 80, borderRadius: 16),
        ],
      ),
    );
  }
}

class ShimmerOrderCardSkeleton extends StatelessWidget {
  const ShimmerOrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              ShimmerBox(width: 50, height: 50, borderRadius: 12),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(height: 16, borderRadius: 4),
                    SizedBox(height: 6),
                    FractionallySizedBox(
                      widthFactor: 0.6,
                      child: ShimmerBox(height: 12, borderRadius: 4),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              ShimmerBox(width: 60, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: ShimmerBox(height: 16, borderRadius: 4),
              ),
              SizedBox(width: 12),
              ShimmerBox(width: 80, height: 36, borderRadius: 12),
            ],
          ),
        ],
      ),
    );
  }
}

// Backwards compatibility alias
typedef ShimmerStoreCardSkeleton = ShimmerRestaurantCardSkeleton;

class ShimmerSpecialOfferCardSkeleton extends StatelessWidget {
  const ShimmerSpecialOfferCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 168,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkOutlineVariant : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Discount Badge skeleton
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: const ShimmerBox(
                  width: 168,
                  height: 110,
                  borderRadius: 0,
                ),
              ),
              const Positioned(
                top: 8,
                left: 8,
                child: ShimmerBox(
                  width: 38,
                  height: 18,
                  borderRadius: 6,
                ),
              ),
            ],
          ),

          // Card Content
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 115, height: 14, borderRadius: 4),
                SizedBox(height: 5),
                ShimmerBox(width: 80, height: 11, borderRadius: 4),
                SizedBox(height: 10),
                Row(
                  children: [
                    ShimmerBox(width: 52, height: 14, borderRadius: 4),
                    SizedBox(width: 6),
                    ShimmerBox(width: 40, height: 11, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerCircularCategorySkeleton extends StatelessWidget {
  const ShimmerCircularCategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          ShimmerBox(
            width: 60,
            height: 60,
            shape: BoxShape.circle,
          ),
          SizedBox(height: 6),
          ShimmerBox(width: 50, height: 11, borderRadius: 4),
        ],
      ),
    );
  }
}

