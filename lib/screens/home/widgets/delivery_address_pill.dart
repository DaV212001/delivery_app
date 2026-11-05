import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/storage_config.dart';
import '../../../constants/pages.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/profile_controller.dart';
import '../../../controllers/restaurant_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/user_location_service.dart';
import '../../../utils/location_utils.dart';
import '../../../widgets/map/property_location_picker_screen.dart';

/// Small transparent frosted glass pill placed at the top of the Home Screen.
/// Displays the user's delivery address reverse-geocoded and prettified.
/// By default, it tracks the user's live current GPS location and allows tapping
/// to refresh GPS, select an address on Gebeta Map, or pick from saved addresses.
class DeliveryAddressPill extends StatelessWidget {
  const DeliveryAddressPill({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasLocationService = Get.isRegistered<UserLocationService>();
    final hasCartController = Get.isRegistered<CartController>();

    if (!hasLocationService && !hasCartController) {
      final rawAddress = ConfigPreference.getUserAddress() ?? 'Addis Ababa';
      return _buildPillContainer(
        context: context,
        displayAddress: LocationUtils.prettifyAddressCompact(rawAddress),
        isUpdating: false,
        isDark: isDark,
      );
    }

    return Obx(() {
      final locationService =
          hasLocationService ? Get.find<UserLocationService>() : null;
      final cartController =
          hasCartController ? Get.find<CartController>() : null;

      final isUpdating = locationService?.isUpdatingLocation.value ?? false;
      final rawAddress = (cartController != null &&
              cartController.deliveryAddress.value.trim().isNotEmpty)
          ? cartController.deliveryAddress.value
          : (locationService != null &&
                  locationService.currentAddress.value.trim().isNotEmpty)
              ? locationService.currentAddress.value
              : (ConfigPreference.getUserAddress() ?? 'Addis Ababa');

      final displayAddress = LocationUtils.prettifyAddressCompact(rawAddress);

      return _buildPillContainer(
        context: context,
        displayAddress: displayAddress,
        isUpdating: isUpdating,
        isDark: isDark,
      );
    });
  }

  Widget _buildPillContainer({
    required BuildContext context,
    required String displayAddress,
    required bool isUpdating,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => _showAddressSelectionModal(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.32),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isUpdating)
                  const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                else
                  const Icon(
                    Icons.location_on_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    displayAddress.isNotEmpty ? displayAddress : 'Addis Ababa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 17,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddressSelectionModal(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(bottomSheetContext).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'delivery_address'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(bottomSheetContext).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 1. Option: Current GPS Location (Live Tracking)
              _buildOptionTile(
                context: bottomSheetContext,
                icon: Icons.my_location_rounded,
                iconColor: AppColors.primary,
                iconBg: AppColors.primary.withValues(alpha: 0.12),
                title: 'use_current_location'.tr,
                subtitleBuilder: () {
                  if (Get.isRegistered<UserLocationService>()) {
                    final svc = Get.find<UserLocationService>();
                    final addr = svc.currentAddress.value;
                    if (addr.isNotEmpty) {
                      return LocationUtils.prettifyAddress(addr);
                    }
                  }
                  return 'Addis Ababa (GPS Tracking)';
                },
                trailingBadge: 'GPS',
                onTap: () async {
                  Navigator.of(bottomSheetContext).pop();
                  if (Get.isRegistered<UserLocationService>()) {
                    final svc = Get.find<UserLocationService>();
                    await svc.updateLocation(promptIfDeniedForever: true);
                    if (Get.isRegistered<CartController>()) {
                      final cart = Get.find<CartController>();
                      cart.deliveryAddress.value = svc.currentAddress.value;
                      if (svc.currentLatitude.value != null &&
                          svc.currentLongitude.value != null) {
                        cart.customerLatitude.value = svc.currentLatitude.value;
                        cart.customerLongitude.value = svc.currentLongitude.value;
                      }
                    }
                  }
                  if (Get.isRegistered<RestaurantController>()) {
                    Get.find<RestaurantController>()
                        .requestLocationAndCalculateDistances();
                  }
                },
              ),

              const SizedBox(height: 10),

              // 2. Option: Select on Gebeta Map
              _buildOptionTile(
                context: bottomSheetContext,
                icon: Icons.map_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBg: const Color(0xFF0284C7).withValues(alpha: 0.12),
                title: 'select_on_map'.tr.isNotEmpty
                    ? 'select_on_map'.tr
                    : 'Choose on Gebeta Map',
                subtitleBuilder: () => 'Search places or drop a pin',
                onTap: () async {
                  Navigator.of(bottomSheetContext).pop();
                  double? initialLat;
                  double? initialLng;
                  if (Get.isRegistered<UserLocationService>()) {
                    final svc = Get.find<UserLocationService>();
                    initialLat = svc.currentLatitude.value;
                    initialLng = svc.currentLongitude.value;
                  }

                  final result = await Get.to<PropertyLocationResult>(
                    () => PropertyLocationPickerScreen(
                      initialLatitude: initialLat,
                      initialLongitude: initialLng,
                      title: 'delivery_address'.tr,
                    ),
                  );

                  if (result != null) {
                    final prettified =
                        LocationUtils.prettifyAddress(result.address);
                    if (Get.isRegistered<CartController>()) {
                      final cart = Get.find<CartController>();
                      cart.deliveryAddress.value = prettified;
                      cart.customerLatitude.value = result.latitude;
                      cart.customerLongitude.value = result.longitude;
                    }
                    if (Get.isRegistered<RestaurantController>()) {
                      final rc = Get.find<RestaurantController>();
                      rc.userLat.value = result.latitude;
                      rc.userLng.value = result.longitude;
                      rc.recalculateStoreDistances();
                    }
                  }
                },
              ),

              const SizedBox(height: 10),

              // 3. Option: Saved Addresses
              _buildOptionTile(
                context: bottomSheetContext,
                icon: Icons.bookmark_outline_rounded,
                iconColor: const Color(0xFF10B981),
                iconBg: const Color(0xFF10B981).withValues(alpha: 0.12),
                title: 'saved_addresses'.tr,
                subtitleBuilder: () {
                  if (Get.isRegistered<ProfileController>()) {
                    final pc = Get.find<ProfileController>();
                    if (pc.addresses.isNotEmpty) {
                      return '${pc.addresses.length} saved addresses';
                    }
                  }
                  return 'Select or manage your saved places';
                },
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                  Get.toNamed(AppRoutes.savedAddresses);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String Function() subtitleBuilder,
    String? trailingBadge,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceContainerLow
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (trailingBadge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              trailingBadge,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleBuilder(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
