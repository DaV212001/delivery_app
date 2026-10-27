import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/restaurant_controller.dart';
import '../../config/storage_config.dart';
import '../../constants/pages.dart';
import '../../core/theme/app_colors.dart';
import '../../services/gebeta_location_service.dart';
import '../../services/order_service.dart';
import '../../services/user_location_service.dart';
import '../../utils/location_utils.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/map/locked_map_preview.dart';
import '../../widgets/map/property_location_picker_screen.dart';
import '../../models/saved_order.dart';
import '../../services/saved_order_service.dart';
import 'widgets/closed_store_order_modal.dart';
import '../main_navigation.dart';
import '../wallet/payment_webview_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _promoController = TextEditingController();
  String? _currentLocationAddress;
  bool _isLoadingCurrentLocation = false;
  final GlobalKey _walletCardKey = GlobalKey();
  final RxBool _isTopUpHighlighted = false.obs;
  Timer? _highlightTimer;

  void _scrollToWalletCard() {
    if (_walletCardKey.currentContext != null) {
      Scrollable.ensureVisible(
        _walletCardKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        alignment: 0.1,
      );
    }
  }

  void _highlightTopUpButton() {
    _isTopUpHighlighted.value = true;
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        _isTopUpHighlighted.value = false;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final cached = ConfigPreference.getUserAddress();
    if (cached != null && cached.isNotEmpty) {
      _currentLocationAddress = cached;
      if (Get.isRegistered<CartController>()) {
        final cart = Get.find<CartController>();
        if (cart.deliveryAddress.value.isEmpty) {
          cart.deliveryAddress.value = cached;
        }
      }
    }
    _fetchCurrentLocation();
    final profileCtrl = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    profileCtrl.loadAddresses();
    profileCtrl.loadWallet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLocationsAndDeliveryOptions();
    });
  }

  void _syncLocationsAndDeliveryOptions() {
    if (!Get.isRegistered<CartController>()) return;
    final cartController = Get.find<CartController>();
    if (cartController.items.isEmpty) return;

    final rc = Get.isRegistered<RestaurantController>()
        ? Get.find<RestaurantController>()
        : Get.put(RestaurantController());
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    final firstItem = cartController.items.first;
    final storeId = firstItem.item.storeId;
    final store = rc.restaurants.firstWhereOrNull((s) => s.id == storeId);

    final propLat = store?.latitude ?? LocationUtils.defaultLatitude;
    final propLng = store?.longitude ?? LocationUtils.defaultLongitude;
    cartController.propertyLatitude.value = propLat;
    cartController.propertyLongitude.value = propLng;

    double custLat = LocationUtils.defaultLatitude;
    double custLng = LocationUtils.defaultLongitude;
    if (profileController.selectedAddress.value != null) {
      custLat = profileController.selectedAddress.value!.latitude;
      custLng = profileController.selectedAddress.value!.longitude;
    } else if (ConfigPreference.getUserLatitude() != null) {
      custLat = ConfigPreference.getUserLatitude()!;
      custLng = ConfigPreference.getUserLongitude()!;
    } else if (Get.isRegistered<UserLocationService>()) {
      final uLat = UserLocationService.to.currentLatitude.value;
      final uLng = UserLocationService.to.currentLongitude.value;
      if (uLat != null && uLat > 0 && uLng != null) {
        custLat = uLat;
        custLng = uLng;
      }
    }
    cartController.customerLatitude.value = custLat;
    cartController.customerLongitude.value = custLng;

    cartController.loadDeliveryOptionsForProperty(storeId, propLat: propLat, propLng: propLng);
  }

  Future<void> _fetchCurrentLocation({bool autoSelect = false}) async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });
    try {
      final addr = await GebetaLocationService.fetchCurrentLocationAddress(
        promptIfDeniedForever: true,
      );
      if (addr != null && addr.isNotEmpty && mounted) {
        setState(() {
          _currentLocationAddress = addr;
        });
        final cartController = Get.find<CartController>();
        if (cartController.deliveryAddress.value.isEmpty || autoSelect) {
          cartController.deliveryAddress.value = addr;
        }
        _syncLocationsAndDeliveryOptions();
        if (autoSelect && Get.isBottomSheetOpen == true) {
          Get.back();
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCurrentLocation = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartController = Get.find<CartController>();
    final orderController = Get.isRegistered<OrderController>()
        ? Get.find<OrderController>()
        : Get.put(OrderController());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'your_cart'.tr,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          Obx(() {
            if (cartController.items.isEmpty) return const SizedBox.shrink();
            return TextButton(
              onPressed: () => cartController.clearCart(),
              child: Text('clear'.tr, style: const TextStyle(color: AppColors.error)),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (cartController.items.isEmpty) {
          if (cartController.savedBatches.isNotEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 28,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'cart_empty'.tr,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'You have saved batches below ready to resume',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSavedBatchesSection(context, theme, isDark, cartController, isStandalone: true),
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: AppButton(
                        isSecondary: true,
                        text: 'start_shopping'.tr,
                        onPressed: () {
                          if (Get.isRegistered<MainNavigationController>()) {
                            Get.find<MainNavigationController>().changePage(0);
                          }
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Get.offAllNamed(AppRoutes.mainNav);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 72,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'cart_empty'.tr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'cart_empty_sub'.tr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  child: AppButton(
                    text: 'start_shopping'.tr,
                    onPressed: () {
                      if (Get.isRegistered<MainNavigationController>()) {
                        Get.find<MainNavigationController>().changePage(0);
                      }
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Get.offAllNamed(AppRoutes.mainNav);
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Batch & Store Info Header
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'active_batch'.tr,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cartController.activePropertyName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.bookmark_add_outlined, size: 20, color: AppColors.primary),
                            tooltip: 'save_for_later'.tr,
                            onPressed: () {
                              cartController.saveCurrentBatch();
                              Get.snackbar(
                                'batch_saved'.tr,
                                'previous_batch_saved'.tr,
                                backgroundColor: AppColors.primary,
                                colorText: Colors.white,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Delivery Address Card (Tappable to pick from Gebeta current location or saved locations)
                    InkWell(
                      onTap: () => _showLocationSelectionSheet(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 20,
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
                                          'delivery_address'.tr,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'change'.tr,
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 16,
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cartController.deliveryAddress.value.isNotEmpty
                                        ? cartController.deliveryAddress.value
                                        : (_isLoadingCurrentLocation
                                            ? 'loading'.tr
                                            : (_currentLocationAddress ?? 'no_address_set'.tr)),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Order Items
                    Text(
                      '${'items_in_order'.tr} (${cartController.totalItemCount})',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),

                    ...cartController.items.map((cartItem) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AppNetworkImage(
                                imageUrl: cartItem.item.imageUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartItem.item.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (cartItem.customizationSummary.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      cartItem.customizationSummary,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    '${cartItem.totalPrice.toStringAsFixed(2)} ${cartItem.displayCurrency}',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Stepper
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => cartController.decrementQuantity(cartItem.id),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurfaceContainerLow
                                          : AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.remove, size: 16),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                  child: Text(
                                    '${cartItem.quantity}',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => cartController.incrementQuantity(cartItem.id),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurfaceContainerLow
                                          : AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.add, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    // Delivery Options Selector
                    Obx(() {
                      final options = cartController.propertyDeliveryOptions;
                      if (options.isEmpty && !cartController.isLoadingDeliveryOptions.value) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'delivery_options'.tr,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (cartController.distanceInKm > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    LocationUtils.formatDistanceKm(cartController.distanceInKm),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (cartController.isLoadingDeliveryOptions.value)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  for (int i = 0; i < options.length; i++) ...[
                                    if (i > 0) const Divider(height: 16),
                                    Obx(() {
                                      final opt = options[i];
                                      final isSelected = cartController.selectedDeliveryOption.value?.name == opt.name ||
                                          (cartController.selectedDeliveryOption.value == null && i == 0);
                                      final dist = cartController.distanceInKm > 0 ? cartController.distanceInKm : 1.0;
                                      final optTotal = double.parse((opt.kmPrice * dist).toStringAsFixed(2));

                                      return InkWell(
                                        onTap: () {
                                          cartController.selectedDeliveryOption.value = opt;
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.0),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: opt.image.isNotEmpty
                                                    ? Image.network(
                                                        opt.image,
                                                        fit: BoxFit.contain,
                                                        errorBuilder: (ctx, err, stack) => const Icon(
                                                          Icons.two_wheeler_rounded,
                                                          color: AppColors.primary,
                                                          size: 22,
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons.two_wheeler_rounded,
                                                        color: AppColors.primary,
                                                        size: 22,
                                                      ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      opt.name,
                                                      style: theme.textTheme.bodyMedium?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${opt.kmPrice.toStringAsFixed(0)} ${cartController.displayCurrency}/km',
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color: theme.colorScheme.onSurfaceVariant,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '${optTotal.toStringAsFixed(2)} ${cartController.displayCurrency}',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                width: 22,
                                                height: 22,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? AppColors.primary
                                                        : Colors.grey.shade400,
                                                    width: isSelected ? 2 : 1.5,
                                                  ),
                                                ),
                                                child: isSelected
                                                    ? Center(
                                                        child: Container(
                                                          width: 12,
                                                          height: 12,
                                                          decoration: const BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            color: AppColors.primary,
                                                          ),
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),

                    // Saved Batches Section (if user has saved other store batches)
                    Obx(() => _buildSavedBatchesSection(context, theme, isDark, cartController)),

                    // Promo Code Input
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promoController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'enter_promo_code'.tr,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              cartController.applyPromo(_promoController.text);
                            },
                            child: Text('apply'.tr, style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Wallet Balance Card (visible when AMN Wallet is selected)
                    Obx(() {
                      if (cartController.selectedPaymentMethod.value != 'wallet') {
                        return const SizedBox.shrink();
                      }
                      final profileController = Get.isRegistered<ProfileController>()
                          ? Get.find<ProfileController>()
                          : Get.put(ProfileController());
                      final walletBalance = profileController.walletBalance.value.amount;
                      final orderTotal = cartController.total;
                      final isInsufficient = walletBalance < orderTotal;
                      final diff = orderTotal - walletBalance;

                      return Container(
                        key: _walletCardKey,
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isInsufficient
                                ? AppColors.error.withValues(alpha: 0.5)
                                : AppColors.primary.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isInsufficient ? AppColors.error : AppColors.primary)
                                  .withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isInsufficient ? AppColors.error : AppColors.primary)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: isInsufficient ? AppColors.error : AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'wallet_balance'.tr,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isInsufficient
                                            ? '${'insufficient_wallet_balance'.tr} (-${diff.toStringAsFixed(2)} Br)'
                                            : 'ready_to_pay'.tr,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isInsufficient
                                              ? AppColors.error
                                              : Colors.green.shade600,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (profileController.isLoadingWallet.value)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else
                                  Text(
                                    '${walletBalance.toStringAsFixed(2)} Br',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: isInsufficient ? AppColors.error : AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Divider(
                              height: 1,
                              color: isDark ? AppColors.darkOutline.withValues(alpha: 0.3) : Colors.grey.shade200,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    isInsufficient
                                        ? 'please_topup_wallet'.tr
                                        : 'wallet_subtitle'.tr,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Obx(() {
                                  final isHighlighted = _isTopUpHighlighted.value;
                                  return AnimatedScale(
                                    scale: isHighlighted ? 1.08 : 1.0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOutBack,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: isHighlighted
                                            ? [
                                                BoxShadow(
                                                  color: (isInsufficient ? AppColors.error : AppColors.primary)
                                                      .withValues(alpha: 0.7),
                                                  blurRadius: 16,
                                                  spreadRadius: 3,
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: ElevatedButton.icon(
                                        key: const ValueKey('wallet_top_up_button'),
                                        onPressed: () {
                                          ProfileController.showTopUpDialog(
                                            context,
                                            suggestedAmount: isInsufficient ? diff : null,
                                          );
                                        },
                                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                                        label: Text(
                                          'topup'.tr,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isInsufficient ? AppColors.error : AppColors.primary,
                                          foregroundColor: Colors.white,
                                          side: isHighlighted
                                              ? const BorderSide(color: Colors.white, width: 2)
                                              : null,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          elevation: isHighlighted ? 8 : 1,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    // Payment Method Selector
                    Text(
                      'payment_method'.tr,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () {
                        final isCashAllowed = cartController.isCashAllowed;
                        final selectedMethod = cartController.selectedPaymentMethod.value;
                        if (!isCashAllowed && selectedMethod == 'cash') {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (cartController.selectedPaymentMethod.value == 'cash') {
                              cartController.selectedPaymentMethod.value = 'chapa';
                            }
                          });
                        }

                        final isChapa = selectedMethod == 'chapa';
                        final isWallet = selectedMethod == 'wallet';
                        final isCash = isCashAllowed && selectedMethod == 'cash';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // 1. Chapa
                              InkWell(
                                onTap: () => cartController.selectedPaymentMethod.value = 'chapa',
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.0),
                                  decoration: BoxDecoration(
                                    color: isChapa
                                        ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00A859).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Image.asset(
                                          'assets/images/chapa_logo.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.payment_rounded,
                                            color: Color(0xFF00A859),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Chapa',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'chapa_subtitle'.tr,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isChapa
                                                ? AppColors.primary
                                                : Colors.grey.shade400,
                                            width: isChapa ? 2 : 1.5,
                                          ),
                                        ),
                                        child: isChapa
                                            ? Center(
                                                child: Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(),

                              // 2. AMN Wallet
                              InkWell(
                                onTap: () {
                                  cartController.selectedPaymentMethod.value = 'wallet';
                                  if (Get.isRegistered<ProfileController>()) {
                                    Get.find<ProfileController>().loadWallet();
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.0),
                                  decoration: BoxDecoration(
                                    color: isWallet
                                        ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_wallet_rounded,
                                          color: AppColors.secondary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'wallet_balance'.tr,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'wallet_subtitle'.tr,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isWallet
                                                ? AppColors.primary
                                                : Colors.grey.shade400,
                                            width: isWallet ? 2 : 1.5,
                                          ),
                                        ),
                                        child: isWallet
                                            ? Center(
                                                child: Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(),

                              // 3. Cash on Delivery
                              InkWell(
                                onTap: isCashAllowed
                                    ? () => cartController.selectedPaymentMethod.value = 'cash'
                                    : () {
                                        Get.snackbar(
                                          'cash_on_delivery'.tr,
                                          'cash_limit_exceeded'.tr,
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: AppColors.error,
                                          colorText: Colors.white,
                                        );
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: Opacity(
                                  opacity: isCashAllowed ? 1.0 : 0.45,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.0),
                                    decoration: BoxDecoration(
                                      color: isCash
                                          ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade700.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.payments_rounded,
                                            color: Colors.amber.shade800,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 6,
                                                runSpacing: 2,
                                                children: [
                                                  Text(
                                                    'cash_on_delivery'.tr,
                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (!isCashAllowed)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.error.withValues(alpha: 0.12),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Text(
                                                        '> 2000 ETB',
                                                        style: TextStyle(
                                                          color: AppColors.error,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              Text(
                                                isCashAllowed
                                                    ? 'cash_subtitle'.tr
                                                    : 'cash_limit_exceeded'.tr,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: isCashAllowed
                                                      ? theme.colorScheme.onSurfaceVariant
                                                      : AppColors.error,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isCash
                                                  ? AppColors.primary
                                                  : Colors.grey.shade400,
                                              width: isCash ? 2 : 1.5,
                                            ),
                                          ),
                                          child: isCash
                                              ? Center(
                                                  child: Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Summary Breakdown Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _SummaryRow(
                            label: 'subtotal'.tr,
                            value: '${cartController.subtotal.toStringAsFixed(2)} ${cartController.displayCurrency}',
                          ),
                          const SizedBox(height: 10),
                          _SummaryRow(
                            label: 'delivery_fee'.tr,
                            value: '${cartController.deliveryFee.toStringAsFixed(2)} ${cartController.displayCurrency}',
                          ),
                          if (cartController.taxAndFees > 0) ...[
                            const SizedBox(height: 10),
                            _SummaryRow(
                              label: 'tax_and_fees'.tr,
                              value: '${cartController.taxAndFees.toStringAsFixed(2)} ${cartController.displayCurrency}',
                            ),
                          ],
                          if (cartController.promoDiscount.value > 0) ...[
                            const SizedBox(height: 10),
                            _SummaryRow(
                              label: 'promo_discount'.tr,
                              value: '-${cartController.promoDiscount.value.toStringAsFixed(2)} ${cartController.displayCurrency}',
                              textColor: AppColors.primary,
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'total'.tr,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${cartController.total.toStringAsFixed(2)} ${cartController.displayCurrency}',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Checkout Button
            Builder(
              builder: (context) {
                final restaurantController = Get.isRegistered<RestaurantController>()
                    ? Get.find<RestaurantController>()
                    : Get.put(RestaurantController());
                final firstItem = cartController.items.isNotEmpty ? cartController.items.first : null;
                final currentStore = firstItem != null
                    ? restaurantController.restaurants.firstWhereOrNull((s) => s.id == firstItem.item.storeId)
                    : null;
                final isStoreClosed = currentStore != null && currentStore.isPastClosingTime;

                return Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    14,
                    20,
                    MediaQuery.of(context).padding.bottom + 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isStoreClosed) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFCD34D)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule_rounded, color: Color(0xFFB45309), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${currentStore.name} • ${'store_closed_opens_at'.tr} ${currentStore.formattedNextOpenTime}',
                                  style: const TextStyle(
                                    color: Color(0xFF92400E),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Obx(
                        () => AppButton(
                          text: isStoreClosed
                              ? 'save_order_for_later'.tr
                              : '${'place_order'.tr} • ${cartController.total.toStringAsFixed(2)} ${cartController.displayCurrency}',
                          isLoading: orderController.isPlacingOrder.value,
                          onPressed: (orderController.isPlacingOrder.value)
                              ? null
                              : () async {
                                  if (isStoreClosed) {
                                    await ClosedStoreOrderModal.show(
                                      context,
                                      store: currentStore,
                                      totalAmount: cartController.total,
                                      itemCount: cartController.totalItemCount,
                                      onSaveForLater: () async {
                                        final fItem = cartController.items.first;
                                        final propId = int.tryParse(fItem.item.storeId) ?? 1;
                                        final menuIds = cartController.items
                                            .map((i) => int.tryParse(i.item.id) ?? 1)
                                            .toList();
                                        final quantities =
                                            cartController.items.map((i) => i.quantity).toList();
                                        final prices =
                                            cartController.items.map((i) => i.item.price).toList();
                                        final itemNames =
                                            cartController.items.map((i) => i.item.name).toList();

                                        final option = cartController.selectedDeliveryOption.value;
                                        final deliveryOptionId = option?.id ?? 1;
                                        final kmPrice = option?.kmPrice ?? 13.0;
                                        final totalKmPrice = cartController.totalKmPrice;
                                        final itemTotalPrice = cartController.subtotal;
                                        final totalAmount = cartController.total;

                                        final custLat = cartController.customerLatitude.value ?? LocationUtils.defaultLatitude;
                                        final custLng = cartController.customerLongitude.value ?? LocationUtils.defaultLongitude;
                                        final propLat = cartController.propertyLatitude.value ?? currentStore.latitude ?? LocationUtils.defaultLatitude;
                                        final propLng = cartController.propertyLongitude.value ?? currentStore.longitude ?? LocationUtils.defaultLongitude;

                                        final deliveryAddress = cartController.deliveryAddress.value.isNotEmpty
                                            ? cartController.deliveryAddress.value
                                            : (_currentLocationAddress ?? 'Addis Ababa');

                                        final paymentMethod = cartController.selectedPaymentMethod.value;
                                        String pType = '0';
                                        if (paymentMethod == 'chapa') pType = '1';
                                        if (paymentMethod == 'wallet') pType = '2';

                                        final savedOrder = SavedOrder(
                                          id: 'saved_${DateTime.now().millisecondsSinceEpoch}',
                                          storeId: propId.toString(),
                                          storeName: currentStore.name,
                                          storeImageUrl: currentStore.heroImageUrl,
                                          openTime: currentStore.openingTime,
                                          scheduledOpenDateTime: currentStore.nextOpenDateTime,
                                          createdAt: DateTime.now(),
                                          deliveryAddress: deliveryAddress,
                                          paymentType: pType,
                                          menuIds: menuIds,
                                          quantities: quantities,
                                          prices: prices,
                                          subtotal: itemTotalPrice,
                                          totalKmPrice: totalKmPrice,
                                          total: totalAmount,
                                          deliveryOption: deliveryOptionId,
                                          kmPrice: kmPrice,
                                          customerLatitude: custLat,
                                          customerLongitude: custLng,
                                          propertyLatitude: propLat,
                                          propertyLongitude: propLng,
                                          itemNames: itemNames,
                                        );

                                        await SavedOrderService.saveOrder(savedOrder);
                                        cartController.clearCart();

                                        Get.snackbar(
                                          'save_order_success'.tr,
                                          '${'save_order_auto_submit_msg'.tr} ${currentStore.name} (${savedOrder.formattedScheduledTime})',
                                          snackPosition: SnackPosition.TOP,
                                          backgroundColor: Colors.green.shade700,
                                          colorText: Colors.white,
                                          duration: const Duration(seconds: 4),
                                          icon: const Icon(Icons.alarm_on_rounded, color: Colors.white),
                                        );
                                      },
                                    );
                                    return;
                                  }

                                  final authController = Get.isRegistered<AuthController>()
                                      ? Get.find<AuthController>()
                                      : Get.put(AuthController());
                                  if (!authController.isLoggedIn) {
                                    Get.dialog(
                                      AlertDialog(
                                        title: Text('sign_in_required'.tr),
                                        content: Text('sign_in_to_order'.tr),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Get.back(),
                                            child: Text('cancel'.tr),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Get.back();
                                              Get.toNamed(AppRoutes.login);
                                            },
                                            child: Text('sign_in_register'.tr),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }

                                  final fItem = cartController.items.first;
                                  final propId = int.tryParse(fItem.item.storeId) ?? 1;
                                  final menuIds = cartController.items
                                      .map((i) => int.tryParse(i.item.id) ?? 1)
                                      .toList();
                                  final quantities =
                                      cartController.items.map((i) => i.quantity).toList();
                                  final prices =
                                      cartController.items.map((i) => i.item.price).toList();

                                  final option = cartController.selectedDeliveryOption.value;
                                  final deliveryOptionId = option?.id ?? 1;
                                  final kmPrice = option?.kmPrice ?? 13.0;
                                  final totalKmPrice = cartController.totalKmPrice;
                                  final itemTotalPrice = cartController.subtotal;
                                  final totalAmount = cartController.total;

                                  final custLat = cartController.customerLatitude.value ?? LocationUtils.defaultLatitude;
                                  final custLng = cartController.customerLongitude.value ?? LocationUtils.defaultLongitude;
                                  final propLat = cartController.propertyLatitude.value ?? currentStore?.latitude ?? LocationUtils.defaultLatitude;
                                  final propLng = cartController.propertyLongitude.value ?? currentStore?.longitude ?? LocationUtils.defaultLongitude;

                                  final deliveryAddress = cartController.deliveryAddress.value.isNotEmpty
                                      ? cartController.deliveryAddress.value
                                      : (_currentLocationAddress ?? 'Addis Ababa');

                                  final paymentMethod = cartController.selectedPaymentMethod.value; // 'cash', 'chapa', 'wallet'

                                  if (paymentMethod == 'wallet') {
                                    final profileController = Get.isRegistered<ProfileController>()
                                        ? Get.find<ProfileController>()
                                        : Get.put(ProfileController());
                                    if (profileController.walletBalance.value.amount < totalAmount) {
                                      _scrollToWalletCard();
                                      Get.snackbar(
                                        'insufficient_wallet_balance'.tr,
                                        'wallet_insufficient_msg'.tr,
                                        snackPosition: SnackPosition.TOP,
                                        backgroundColor: AppColors.error,
                                        colorText: Colors.white,
                                        duration: const Duration(seconds: 4),
                                        icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                                      );
                                      _highlightTopUpButton();
                                      return;
                                    }
                                  }

                                  final uid = ConfigPreference.getUserId() ?? 1;
                                  final now = DateTime.now();
                                  final ymdDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

                                  Future<bool> executeCreateOrder(String pType) async {
                                    return await orderController.placeOrder(
                                      storeName: currentStore?.name ?? fItem.item.name,
                                      storeImageUrl: currentStore?.heroImageUrl ?? fItem.item.imageUrl,
                                      subtotal: itemTotalPrice,
                                      deliveryFee: totalKmPrice,
                                      total: totalAmount,
                                      deliveryAddress: deliveryAddress,
                                      paymentType: pType,
                                      menuIds: menuIds,
                                      quantities: quantities,
                                      prices: prices,
                                      propertyId: propId,
                                      customerLatitude: custLat,
                                      customerLongitude: custLng,
                                      propertyLatitude: propLat,
                                      propertyLongitude: propLng,
                                      deliveryOption: deliveryOptionId,
                                      kmPrice: kmPrice,
                                      totalKmPrice: totalKmPrice,
                                      destinationFriendlyLocation: _currentLocationAddress,
                                    );
                                  }

                                  // 1. CASH PAYMENT FLOW
                                  if (paymentMethod == 'cash') {
                                    if (!cartController.isCashAllowed) {
                                      Get.snackbar(
                                        'cash_on_delivery'.tr,
                                        'cash_under_2k'.tr,
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: AppColors.error,
                                        colorText: Colors.white,
                                      );
                                      return;
                                    }

                                    final success = await executeCreateOrder('0');
                                    if (success) {
                                      cartController.clearCart();
                                      Get.toNamed(
                                        AppRoutes.tracking,
                                        arguments: orderController.activeOrder.value,
                                      );
                                    }
                                    return;
                                  }

                                  // 2. CHAPA PAYMENT FLOW
                                  if (paymentMethod == 'chapa') {
                                    orderController.isPlacingOrder.value = true;
                                    String? checkoutUrl;

                                    await OrderService.payOnChapa(
                                      userId: uid,
                                      amount: totalAmount,
                                      date: ymdDate,
                                      orderId: 1,
                                      onSuccess: (url, msg) {
                                        checkoutUrl = url;
                                      },
                                      onFailure: (err) {
                                        Get.snackbar(
                                          'payment_failed'.tr,
                                          err,
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: AppColors.error,
                                          colorText: Colors.white,
                                        );
                                      },
                                    );
                                    orderController.isPlacingOrder.value = false;

                                    if (checkoutUrl != null && checkoutUrl!.isNotEmpty) {
                                      final bool? receiptVerified = await Get.to<bool>(
                                        () => PaymentWebViewScreen(
                                          initialUrl: checkoutUrl!,
                                          title: 'Chapa Checkout',
                                        ),
                                      );

                                      if (receiptVerified == true) {
                                        final success = await executeCreateOrder('1');
                                        if (success) {
                                          cartController.clearCart();
                                          Get.toNamed(
                                            AppRoutes.tracking,
                                            arguments: orderController.activeOrder.value,
                                          );
                                        }
                                      } else {
                                        Get.snackbar(
                                          'payment_not_completed'.tr,
                                          'payment_pending_receipt'.tr,
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      }
                                    }
                                    return;
                                  }

                                  // 3. WALLET PAYMENT FLOW
                                  if (paymentMethod == 'wallet') {
                                    final profileController = Get.isRegistered<ProfileController>()
                                        ? Get.find<ProfileController>()
                                        : Get.put(ProfileController());

                                    await profileController.loadWallet();
                                    final currentBalance = profileController.walletBalance.value.amount;

                                    if (currentBalance < totalAmount) {
                                      _scrollToWalletCard();
                                      Get.snackbar(
                                        'insufficient_wallet_balance'.tr,
                                        'wallet_insufficient_msg'.tr,
                                        snackPosition: SnackPosition.TOP,
                                        backgroundColor: AppColors.error,
                                        colorText: Colors.white,
                                        duration: const Duration(seconds: 4),
                                        icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                                      );
                                      _highlightTopUpButton();
                                      return;
                                    }

                                    orderController.isPlacingOrder.value = true;
                                    bool walletPaid = false;

                                    await OrderService.payOnWallet(
                                      userId: uid,
                                      amount: totalAmount,
                                      date: ymdDate,
                                      orderId: 1,
                                      onSuccess: (data) {
                                        walletPaid = true;
                                      },
                                      onFailure: (err) {
                                        _scrollToWalletCard();
                                        Get.snackbar(
                                          'insufficient_wallet_balance'.tr,
                                          err.isNotEmpty ? err : 'wallet_insufficient_msg'.tr,
                                          snackPosition: SnackPosition.TOP,
                                          backgroundColor: AppColors.error,
                                          colorText: Colors.white,
                                          duration: const Duration(seconds: 4),
                                          icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                                        );
                                        _highlightTopUpButton();
                                      },
                                    );
                                    orderController.isPlacingOrder.value = false;

                                    if (walletPaid) {
                                      final success = await executeCreateOrder('2');
                                      if (success) {
                                        await profileController.loadWallet();
                                        cartController.clearCart();
                                        Get.toNamed(
                                          AppRoutes.tracking,
                                          arguments: orderController.activeOrder.value,
                                        );
                                      }
                                    }
                                    return;
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSavedBatchesSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    CartController cartController, {
    bool isStandalone = false,
  }) {
    if (cartController.savedBatches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.layers_outlined,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '${'saved_batches'.tr} (${cartController.savedBatches.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...cartController.savedBatches.map((batch) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceContainerLowest : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            batch.propertyName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${batch.totalQuantity} items • ${batch.subtotal.toStringAsFixed(2)} ${batch.items.isNotEmpty ? batch.items.first.displayCurrency : cartController.displayCurrency}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                      tooltip: 'delete_batch'.tr,
                      onPressed: () {
                        cartController.deleteSavedBatch(batch.propertyId);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: batch.items.take(3).map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}x ${item.item.name}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    height: 38,
                    isSecondary: true,
                    icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                    text: isStandalone ? 'resume_batch'.tr : 'switch_to_batch'.tr,
                    onPressed: () {
                      cartController.restoreBatch(batch);
                      _syncLocationsAndDeliveryOptions();
                      Get.snackbar(
                        'active_batch'.tr,
                        '${batch.propertyName} is now your active cart',
                        backgroundColor: AppColors.primary,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.TOP,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showLocationSelectionSheet(BuildContext context) {
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    final cartController = Get.find<CartController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'select_delivery_location'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current GPS Location (Gebeta Maps)
                      Text(
                        'use_current_location'.tr,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          if (_currentLocationAddress != null && _currentLocationAddress!.isNotEmpty) {
                            cartController.deliveryAddress.value = _currentLocationAddress!;
                            _syncLocationsAndDeliveryOptions();
                            Get.back();
                          } else {
                            _fetchCurrentLocation(autoSelect: true);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'use_current_location'.tr,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isLoadingCurrentLocation
                                          ? 'loading'.tr
                                          : (_currentLocationAddress ?? 'no_address_set'.tr),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (_isLoadingCurrentLocation)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                IconButton(
                                  icon: const Icon(Icons.refresh_rounded, size: 20),
                                  onPressed: () => _fetchCurrentLocation(autoSelect: true),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Saved Locations
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'saved_addresses'.tr,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Get.back();
                              _showAddAddressDialog(context);
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: Text('add_address'.tr),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Obx(() {
                        if (profileController.isLoadingAddresses.value) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (profileController.addresses.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceContainerLow
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.location_off_outlined,
                                  size: 32,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'no_saved_addresses'.tr,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: profileController.addresses.map((address) {
                            final isSelected = cartController.deliveryAddress.value == address.name;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceContainerLowest
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.withValues(alpha: 0.2),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.1)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: isSelected ? AppColors.primary : Colors.grey.shade600,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  address.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  '${address.latitude.toStringAsFixed(4)}, ${address.longitude.toStringAsFixed(4)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                                    : null,
                                onTap: () {
                                  profileController.selectAddress(address);
                                  cartController.deliveryAddress.value = address.name;
                                  cartController.customerLatitude.value = address.latitude;
                                  cartController.customerLongitude.value = address.longitude;
                                  Get.back();
                                },
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showAddAddressDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: _currentLocationAddress ?? '');
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    double selectedLat = LocationUtils.defaultLatitude;
    double selectedLng = LocationUtils.defaultLongitude;
    String locationLabel = 'Bole, Addis Ababa';

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.add_location_alt_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('add_address'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'address_name'.tr,
                      hintText: 'e.g. Home, Office, Bole Medhanialem',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LockedLocationPickerCard(
                    latitude: selectedLat,
                    longitude: selectedLng,
                    address: locationLabel,
                    buttonLabel: 'select_location_on_map'.tr,
                    onPickOnMap: () async {
                      final result = await Get.to<PropertyLocationResult>(
                        () => PropertyLocationPickerScreen(
                          title: 'Pin Delivery Address',
                          initialLatitude: selectedLat,
                          initialLongitude: selectedLng,
                          initialAddress: nameCtrl.text.trim().isNotEmpty
                              ? nameCtrl.text.trim()
                              : locationLabel,
                        ),
                      );
                      if (result != null) {
                        setDialogState(() {
                          selectedLat = result.latitude;
                          selectedLng = result.longitude;
                          if (result.address.isNotEmpty) {
                            locationLabel = result.address;
                            if (nameCtrl.text.trim().isEmpty) {
                              nameCtrl.text = result.address;
                            }
                          }
                        });
                      }
                    },
                    onAddressResolved: (resolved) {
                      setDialogState(() {
                        locationLabel = resolved;
                        if (nameCtrl.text.trim().isEmpty) {
                          nameCtrl.text = resolved;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('cancel'.tr),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isNotEmpty) {
                    await profileController.addAddress(
                      name,
                      selectedLat,
                      selectedLng,
                    );
                  } else {
                    Get.snackbar('error'.tr, 'Please enter an address label');
                  }
                },
                child: Text('save'.tr),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? textColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor ?? theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
