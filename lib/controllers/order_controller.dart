import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/dio_config.dart';
import '../config/storage_config.dart';
import '../constants/app_assets.dart';
import '../data/mock_data.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/store.dart';
import '../screens/wallet/payment_webview_screen.dart';
import '../services/gebeta_location_service.dart';
import '../services/order_notification_retry_service.dart';
import '../services/order_service.dart';
import '../utils/api_call_status.dart';
import 'cart_controller.dart';
import 'profile_controller.dart';

class OrderController extends GetxController {
  final status = ApiCallStatus.loading.obs;
  final Rx<OrderModel?> activeOrder = Rx<OrderModel?>(null);
  final activeOrders = <OrderModel>[].obs;
  final pastOrders = <OrderModel>[].obs;
  final isPlacingOrder = false.obs;
  Timer? _progressTimer;

  int? get currentCustomerId => ConfigPreference.getUserId();
  bool get isAuthenticated => currentCustomerId != null;

  @override
  void onInit() {
    super.onInit();
    if (DioConfig.isTestMode) {
      activeOrders.assignAll([MockData.activeOrder]);
      activeOrder.value = MockData.activeOrder;
      pastOrders.assignAll(MockData.pastOrders);
      status.value = ApiCallStatus.success;
    } else {
      loadOrders();
    }
  }

  @override
  void onClose() {
    _progressTimer?.cancel();
    super.onClose();
  }

  Future<void> loadOrders() async {
    final uid = currentCustomerId;
    if (uid == null) {
      activeOrders.clear();
      activeOrder.value = null;
      pastOrders.clear();
      status.value = ApiCallStatus.success;
      return;
    }

    status.value = ApiCallStatus.loading;
    try {
      final activeList = await OrderService.fetchActiveOrders(uid);
      activeOrders.assignAll(activeList);
      activeOrder.value = activeList.isNotEmpty ? activeList.first : null;
      for (final order in activeList) {
        fetchDetail(order.orderId);
      }

      final pastList = await OrderService.fetchPastOrders(uid);
      if (pastList.isNotEmpty) {
        pastOrders.assignAll(pastList);
      } else {
        pastOrders.clear();
      }

      status.value = ApiCallStatus.success;
    } catch (_) {
      if (DioConfig.isTestMode) {
        if (activeOrders.isEmpty && activeOrder.value == null) {
          activeOrders.assignAll([MockData.activeOrder]);
          activeOrder.value = MockData.activeOrder;
        }
        pastOrders.assignAll(MockData.pastOrders);
        status.value = ApiCallStatus.success;
      } else {
        activeOrders.clear();
        activeOrder.value = null;
        pastOrders.clear();
        status.value = ApiCallStatus.error;
      }
    }
  }

  Future<bool> placeOrder({
    String? storeName,
    String? storeImageUrl,
    String? restaurantName,
    String? restaurantImageUrl,
    required double subtotal,
    required double deliveryFee,
    double taxAndFees = 0.0,
    required double total,
    required String deliveryAddress,
    StoreType storeType = StoreType.retail,
    String paymentType = '0',
    List<int>? menuIds,
    List<int>? quantities,
    List<double>? prices,
    int propertyId = 1,
    double customerLatitude = 9.0320,
    double customerLongitude = 38.7469,
    double propertyLatitude = 9.0320,
    double propertyLongitude = 38.7469,
    dynamic deliveryOption = 1,
    num kmPrice = 13,
    num? totalKmPrice,
    double? latitude,
    double? longitude,
    double? storeLatitude,
    double? storeLongitude,
    String? destinationFriendlyLocation,
    String? currency,
  }) async {
    final uid = currentCustomerId;
    if (uid == null) {
      Get.snackbar(
        'sign_in_required'.tr,
        'sign_in_to_order'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    isPlacingOrder.value = true;
    bool success = false;

    try {
      final effectiveName = storeName ?? restaurantName ?? 'Store';
      final effectiveImage = storeImageUrl ?? restaurantImageUrl ?? AppAssets.parcelBoxItem;

      final dateIso = DateTime.now().toUtc().toIso8601String();

      final effectiveCustLat = latitude ?? customerLatitude;
      final effectiveCustLng = longitude ?? customerLongitude;
      final effectivePropLat = storeLatitude ?? propertyLatitude;
      final effectivePropLng = storeLongitude ?? propertyLongitude;
      final effectiveTotalKmPrice = totalKmPrice ?? deliveryFee;

      // Reverse geocode destination coordinates (effectiveCustLat, effectiveCustLng)
      String resolvedDestinationFriendly =
          (destinationFriendlyLocation != null && destinationFriendlyLocation.trim().isNotEmpty)
              ? destinationFriendlyLocation.trim()
              : '';

      if (resolvedDestinationFriendly.isEmpty) {
        try {
          resolvedDestinationFriendly = await GebetaLocationService.reverseGeocode(
            effectiveCustLat,
            effectiveCustLng,
          );
        } catch (_) {}
      }

      if (resolvedDestinationFriendly.isEmpty) {
        resolvedDestinationFriendly = deliveryAddress.trim().isNotEmpty
            ? deliveryAddress
            : 'Addis Ababa';
      }

      String normalizedPaymentType = paymentType;
      if (paymentType == 'cash') normalizedPaymentType = '0';
      if (paymentType == 'chapa') normalizedPaymentType = '1';
      if (paymentType == 'wallet') normalizedPaymentType = '2';

      final effectiveMenuIds = (menuIds != null && menuIds.isNotEmpty) ? menuIds : [1];
      final effectiveQuantities = (quantities != null && quantities.isNotEmpty) ? quantities : [1];
      final effectivePrices = (prices != null && prices.isNotEmpty) ? prices : [subtotal];

      String? resolvedCurrency = (currency != null && currency.trim().isNotEmpty)
          ? currency.trim()
          : null;
      if (resolvedCurrency == null && Get.isRegistered<CartController>()) {
        final cart = Get.find<CartController>();
        if (cart.items.isNotEmpty) {
          resolvedCurrency = cart.displayCurrency;
        }
      }
      resolvedCurrency ??= ConfigPreference.getPropertyCurrency(propertyId) ?? 'ETB';

      final request = OrderCreateRequest(
        customerId: uid,
        location: deliveryAddress,
        date: dateIso,
        paymentType: normalizedPaymentType,
        totalQuantity: effectiveQuantities.fold(0, (s, q) => s + q),
        menuIds: effectiveMenuIds,
        quantities: effectiveQuantities,
        prices: effectivePrices,
        itemTotalPrice: subtotal,
        totalItem: effectiveMenuIds.length,
        propertyId: propertyId,
        customerLatitude: effectiveCustLat,
        customerLongitude: effectiveCustLng,
        propertyLatitude: effectivePropLat,
        propertyLongitude: effectivePropLng,
        deliveryOption: deliveryOption,
        kmPrice: kmPrice,
        totalKmPrice: effectiveTotalKmPrice,
        destinationFriendlyLocation: resolvedDestinationFriendly,
        currency: resolvedCurrency,
      );

      await OrderService.createOrder(
        request: request,
        onSuccess: (data) async {
          success = true;

          final resData = data['data'];
          final orderIdNum = (resData is Map ? resData['id'] : null)?.toString() ??
              '${1000 + DateTime.now().millisecond * 7}';

          final cartItems = Get.isRegistered<CartController>()
              ? List<CartItem>.from(Get.find<CartController>().items)
              : <CartItem>[];

          final newOrder = OrderModel(
            orderId: '#AMN-$orderIdNum',
            storeName: effectiveName,
            storeImageUrl: effectiveImage,
            orderDate: DateTime.now(),
            items: cartItems,
            subtotal: subtotal,
            deliveryFee: effectiveTotalKmPrice.toDouble(),
            taxAndFees: taxAndFees,
            total: total,
            deliveryAddress: deliveryAddress,
            destinationFriendlyLocation: resolvedDestinationFriendly,
            status: OrderProgressStatus.placed,
            estimatedArrival: 'Finding Driver',
            storeType: storeType,
            storeLatitude: effectivePropLat,
            storeLongitude: effectivePropLng,
            deliveryLatitude: effectiveCustLat,
            deliveryLongitude: effectiveCustLng,
            driver: null,
            currency: resolvedCurrency,
          );

          activeOrder.value = newOrder;
          activeOrders.removeWhere((o) => o.orderId == newOrder.orderId);
          activeOrders.insert(0, newOrder);

          // Track order notification retry: check if status changes to 1 in 2 minutes (up to 2 retries)
          final parsedId = int.tryParse(orderIdNum);
          if (parsedId != null && parsedId > 0) {
            OrderNotificationRetryService.instance.trackNormalOrder(
              orderId: parsedId,
              amount: total,
              storeName: effectiveName,
              destination: resolvedDestinationFriendly.isNotEmpty
                  ? resolvedDestinationFriendly
                  : deliveryAddress,
              cityId: 1,
            );
          }

          // If payment gateway returned a checkout URL fallback
          String? checkoutUrl = OrderService.findCheckoutUrl(data);
          if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
            await Get.to(
              () => PaymentWebViewScreen(
                initialUrl: checkoutUrl,
                title: 'Order Payment',
                onReceiptDetected: () async {
                  final profileController = Get.isRegistered<ProfileController>()
                      ? Get.find<ProfileController>()
                      : Get.put(ProfileController());
                  await profileController.loadWallet();
                },
              ),
            );
            if (Get.isRegistered<ProfileController>()) {
              await Get.find<ProfileController>().loadWallet();
            }
          }

          Get.snackbar(
            'order_placed'.tr,
            'order_sent_to_store'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withValues(alpha: 0.8),
            colorText: Colors.white,
          );
        },
        onFailure: (error) {
          if (DioConfig.isTestMode) {
            success = true;
            // Still create local order so checkout doesn't get blocked in offline tests
            final newOrder = OrderModel(
              orderId: '#AMN-${1000 + DateTime.now().millisecond * 7}',
              storeName: effectiveName,
              storeImageUrl: effectiveImage,
              orderDate: DateTime.now(),
              items: [],
              subtotal: subtotal,
              deliveryFee: deliveryFee,
              taxAndFees: taxAndFees,
              total: total,
              deliveryAddress: deliveryAddress,
              destinationFriendlyLocation: resolvedDestinationFriendly,
              status: OrderProgressStatus.placed,
              estimatedArrival: 'Finding Driver',
              storeType: storeType,
            );
            activeOrder.value = newOrder;
            activeOrders.removeWhere((o) => o.orderId == newOrder.orderId);
            activeOrders.insert(0, newOrder);
          } else {
            success = false;
            Get.snackbar(
              'order_failed'.tr,
              error,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.withValues(alpha: 0.8),
              colorText: Colors.white,
            );
          }
        },
      );
    } catch (e) {
      if (DioConfig.isTestMode) {
        success = true;
      } else {
        success = false;
        Get.snackbar(
          'order_failed'.tr,
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } finally {
      isPlacingOrder.value = false;
    }

    return success;
  }

  Future<void> fetchDetail(dynamic orderId) async {
    final cleanId = orderId.toString().replaceAll(RegExp(r'[^0-9]'), '');
    final targetId = cleanId.isNotEmpty ? cleanId : orderId.toString();
    final existing = activeOrders.firstWhereOrNull(
      (o) => o.orderId.replaceAll(RegExp(r'[^0-9]'), '') == targetId,
    ) ?? (activeOrder.value?.orderId.replaceAll(RegExp(r'[^0-9]'), '') == targetId ? activeOrder.value : null);

    final detail = await OrderService.fetchOrderDetail(targetId, existingOrder: existing);
    if (detail != null) {
      final effectiveDetail = (existing != null &&
              existing.status != OrderProgressStatus.placed &&
              detail.status == OrderProgressStatus.placed)
          ? detail.copyWith(
              status: existing.status,
              driver: detail.driver ?? existing.driver,
            )
          : detail;

      final index = activeOrders.indexWhere(
        (o) => o.orderId.replaceAll(RegExp(r'[^0-9]'), '') == targetId,
      );
      if (index != -1) {
        activeOrders[index] = effectiveDetail;
      }
      if (activeOrder.value == null ||
          activeOrder.value!.orderId.replaceAll(RegExp(r'[^0-9]'), '') == targetId) {
        activeOrder.value = effectiveDetail;
        activeOrder.refresh();
      }
    }
  }

  void updateActiveOrderStatus(OrderProgressStatus newStatus, {String? orderId, bool refetch = false}) {
    if (orderId != null) {
      final clean = orderId.replaceAll(RegExp(r'[^0-9]'), '');
      final idx = activeOrders.indexWhere(
        (o) => o.orderId.replaceAll(RegExp(r'[^0-9]'), '') == clean,
      );
      if (idx != -1) {
        activeOrders[idx] = activeOrders[idx].copyWith(status: newStatus);
      }
    } else if (activeOrders.isNotEmpty) {
      activeOrders[0] = activeOrders[0].copyWith(status: newStatus);
    }
    if (activeOrder.value != null) {
      activeOrder.value = activeOrder.value!.copyWith(status: newStatus);
      activeOrder.refresh();
    }
    if (refetch) {
      final targetId = orderId ?? activeOrder.value?.orderId;
      if (targetId != null && targetId.isNotEmpty) {
        fetchDetail(targetId);
      }
    }
  }

  void updateActiveOrderLocation({
    required double latitude,
    required double longitude,
    String? orderId,
  }) {
    if (orderId != null) {
      final clean = orderId.replaceAll(RegExp(r'[^0-9]'), '');
      final idx = activeOrders.indexWhere(
        (o) => o.orderId.replaceAll(RegExp(r'[^0-9]'), '') == clean,
      );
      if (idx != -1) {
        activeOrders[idx] = activeOrders[idx].copyWith(
          driverLatitude: latitude,
          driverLongitude: longitude,
        );
      }
    } else if (activeOrders.isNotEmpty) {
      activeOrders[0] = activeOrders[0].copyWith(
        driverLatitude: latitude,
        driverLongitude: longitude,
      );
    }
    if (activeOrder.value != null) {
      activeOrder.value = activeOrder.value!.copyWith(
        driverLatitude: latitude,
        driverLongitude: longitude,
      );
      activeOrder.refresh();
    }
  }

  void cancelOrder({String? orderId}) {
    if (orderId != null) {
      final clean = orderId.replaceAll(RegExp(r'[^0-9]'), '');
      activeOrders.removeWhere(
        (o) => o.orderId.replaceAll(RegExp(r'[^0-9]'), '') == clean,
      );
      if (activeOrder.value?.orderId.replaceAll(RegExp(r'[^0-9]'), '') == clean) {
        activeOrder.value = activeOrders.isNotEmpty ? activeOrders.first : null;
      }
    } else {
      activeOrders.clear();
      activeOrder.value = null;
    }
  }

  /// Reset all order state (called on logout)
  void clear() {
    activeOrders.clear();
    activeOrder.value = null;
    pastOrders.clear();
    status.value = ApiCallStatus.success;
  }
}

