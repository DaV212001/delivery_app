import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isSecondary;
  final bool isLoading;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isSecondary = false,
    this.isLoading = false,
    this.width,
    this.height = 52,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isSecondary
        ? (isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerLow)
        : AppColors.primary;
    final fgColor = isSecondary
        ? (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
        : Colors.white;

    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: (width != null && width! < 150) ? 12 : 20,
        );

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: !isSecondary && onPressed != null
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: effectivePadding,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: fgColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      icon!,
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class PillChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? leading;

  const PillChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow);
    final textColor = isSelected
        ? Colors.white
        : (isDark ? AppColors.darkOnSurface : AppColors.onSurface);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkOutlineVariant : Colors.transparent),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RatingBadge extends StatelessWidget {
  final double rating;
  final int? reviewsCount;
  final bool showStar;

  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewsCount,
    this.showStar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showStar) ...[
          const Icon(Icons.star_rounded, size: 16, color: AppColors.starGold),
          const SizedBox(width: 4),
        ],
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (reviewsCount != null) ...[
          const SizedBox(width: 2),
          Text(
            '($reviewsCount)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? errorWidget;
  final Widget? placeholder;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.errorWidget,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerHigh;
    final highlightColor = isDark ? AppColors.darkSurfaceContainerHighest : Colors.white;

    Widget fallbackWidget() {
      if (errorWidget != null) return errorWidget!;
      return Container(
        width: width,
        height: height,
        color: baseColor,
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.grey, size: 28),
        ),
      );
    }

    Widget content;
    final trimmed = sanitizeImageUrl(imageUrl);

    if (trimmed.isEmpty) {
      content = fallbackWidget();
    } else if (trimmed.startsWith('assets/')) {
      content = Image.asset(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallbackWidget(),
      );
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      content = CachedNetworkImage(
        imageUrl: trimmed,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ??
            Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                width: width,
                height: height,
                color: baseColor,
              ),
            ),
        errorWidget: (context, url, error) => fallbackWidget(),
      );
    } else {
      content = fallbackWidget();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: content,
    );
  }
}

String sanitizeImageUrl(String rawUrl) {
  var s = rawUrl.trim();
  if (s.isEmpty) return s;
  s = s.replaceAll('.ccom', '.com');
  s = s.replaceAll('/ppublic/', '/public/');
  s = s.replaceAll('/storagge/', '/storage/');

  // Upgrade HTTP to HTTPS for backend domains to avoid mobile cleartext blocks
  if (s.startsWith('http://erp.amnplc.com')) {
    s = s.replaceFirst('http://', 'https://');
  } else if (s.startsWith('http://api.amnplc.com')) {
    s = s.replaceFirst('http://', 'https://');
  }

  // Handle protocol-relative URLs
  if (s.startsWith('//')) {
    s = 'https:$s';
  }

  // Handle relative storage/public paths returned by backend
  if (!s.startsWith('http://') && !s.startsWith('https://') && !s.startsWith('assets/')) {
    if (s.startsWith('/')) {
      s = 'https://erp.amnplc.com$s';
    } else {
      s = 'https://erp.amnplc.com/$s';
    }
  }

  if (s.startsWith('http://') || s.startsWith('https://')) {
    final uri = Uri.tryParse(s);
    if (uri != null) {
      final cleanPath = uri.path.replaceAll(RegExp(r'/+'), '/');
      return uri.replace(path: cleanPath).toString();
    }
  }
  return s;
}
