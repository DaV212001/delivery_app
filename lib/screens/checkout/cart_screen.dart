import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/restaurant_controller.dart';
import '../../constants/pages.dart';
import '../../core/theme/app_colors.dart';
import '../../services/gebeta_location_service.dart';
import '../../utils/location_utils.dart';
import '../../widgets/common/app_widgets.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _promoController = TextEditingController();
  String? _currentLocationAddress;
  bool _isLoadingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().loadAddresses();
    }
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
                    onPressed: () => Get.offNamed(AppRoutes.mainNav),
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
                                      Text(
                                        'delivery_address'.tr,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
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
                                    '${cartItem.totalPrice.toStringAsFixed(2)} Br',
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

                    const SizedBox(height: 16),

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

                    // Payment Method Selector
                    Text(
                      'payment_method'.tr,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final isCashAllowed = cartController.isCashAllowed;
                        if (!isCashAllowed && cartController.selectedPaymentMethod.value == 'cash') {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (cartController.selectedPaymentMethod.value == 'cash') {
                              cartController.selectedPaymentMethod.value = 'chapa';
                            }
                          });
                        }

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
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
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
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: cartController.selectedPaymentMethod.value == 'chapa'
                                                ? AppColors.primary
                                                : Colors.grey.shade400,
                                            width: cartController.selectedPaymentMethod.value == 'chapa' ? 6 : 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(),

                              // 2. AMN Wallet
                              InkWell(
                                onTap: () => cartController.selectedPaymentMethod.value = 'wallet',
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
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
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: cartController.selectedPaymentMethod.value == 'wallet'
                                                ? AppColors.primary
                                                : Colors.grey.shade400,
                                            width: cartController.selectedPaymentMethod.value == 'wallet' ? 6 : 2,
                                          ),
                                        ),
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
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0),
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
                                              Row(
                                                children: [
                                                  Text(
                                                    'cash_on_delivery'.tr,
                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (!isCashAllowed) ...[
                                                    const SizedBox(width: 6),
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
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isCashAllowed && cartController.selectedPaymentMethod.value == 'cash'
                                                  ? AppColors.primary
                                                  : Colors.grey.shade400,
                                              width: isCashAllowed && cartController.selectedPaymentMethod.value == 'cash' ? 6 : 2,
                                            ),
                                          ),
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
                          _SummaryRow(label: 'subtotal'.tr, value: '${cartController.subtotal.toStringAsFixed(2)} Br'),
                          const SizedBox(height: 10),
                          _SummaryRow(
                            label: 'delivery_fee'.tr,
                            value: cartController.deliveryFee == 0
                                ? 'free'.tr
                                : '${cartController.deliveryFee.toStringAsFixed(2)} Br',
                          ),
                          const SizedBox(height: 10),
                          _SummaryRow(
                            label: 'tax_and_fees'.tr,
                            value: '${cartController.taxAndFees.toStringAsFixed(2)} Br',
                          ),
                          if (cartController.promoDiscount.value > 0) ...[
                            const SizedBox(height: 10),
                            _SummaryRow(
                              label: 'promo_discount'.tr,
                              value: '-${cartController.promoDiscount.value.toStringAsFixed(2)} Br',
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
                              Text(
                                'total'.tr,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${cartController.total.toStringAsFixed(2)} Br',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
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
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, color: AppColors.error, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${currentStore.name} ${'restaurant_is_closed_msg'.tr}',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
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
                              ? 'closed_for_ordering'.tr
                              : '${'place_order'.tr} • ${cartController.total.toStringAsFixed(2)} Br',
                          isLoading: orderController.isPlacingOrder.value,
                          onPressed: (isStoreClosed || orderController.isPlacingOrder.value)
                              ? (isStoreClosed
                                  ? () {
                                      Get.snackbar(
                                        'closed_ordering_disabled'.tr,
                                        '${currentStore.name} ${'restaurant_is_closed_msg'.tr}',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: AppColors.error,
                                        colorText: Colors.white,
                                      );
                                    }
                                  : null)
                              : () async {
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

                                  if (cartController.selectedPaymentMethod.value == 'cash' && !cartController.isCashAllowed) {
                                    Get.snackbar(
                                      'error'.tr,
                                      'cash_limit_exceeded'.tr,
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: AppColors.error,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }

                                  final fItem = cartController.items.first;
                                  final menuIds = cartController.items
                                      .map((i) => int.tryParse(i.item.id) ?? 1)
                                      .toList();
                                  final quantities =
                                      cartController.items.map((i) => i.quantity).toList();
                                  final prices =
                                      cartController.items.map((i) => i.item.price).toList();
                                  final propId = int.tryParse(fItem.item.storeId) ?? 1;

                                  final success = await orderController.placeOrder(
                                    storeName: currentStore?.name ?? fItem.item.name,
                                    storeImageUrl: currentStore?.heroImageUrl ?? fItem.item.imageUrl,
                                    subtotal: cartController.subtotal,
                                    deliveryFee: cartController.deliveryFee,
                                    taxAndFees: cartController.taxAndFees,
                                    total: cartController.total,
                                    deliveryAddress: cartController.deliveryAddress.value,
                                    paymentType: cartController.selectedPaymentMethod.value,
                                    menuIds: menuIds,
                                    quantities: quantities,
                                    prices: prices,
                                    propertyId: propId,
                                    storeLatitude: currentStore?.latitude,
                                    storeLongitude: currentStore?.longitude,
                                  );

                                  if (success) {
                                    cartController.clearCart();
                                    Get.toNamed(
                                      AppRoutes.tracking,
                                      arguments: orderController.activeOrder.value,
                                    );
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

    Get.dialog(
      AlertDialog(
        title: Text('add_address'.tr),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: 'address_name'.tr,
            hintText: 'e.g. Home, Office, Bole Medhanialem',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                await profileController.addAddress(
                  name,
                  LocationUtils.defaultLatitude,
                  LocationUtils.defaultLongitude,
                );
              }
            },
            child: Text('save'.tr),
          ),
        ],
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
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor ?? theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
