import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/dio_config.dart';
import '../config/storage_config.dart';
import '../constants/app_assets.dart';
import '../data/mock_data.dart';
import '../models/order.dart';
import '../models/store.dart';
import '../screens/wallet/payment_webview_screen.dart';
import '../services/order_service.dart';
import '../utils/api_call_status.dart';
import 'profile_controller.dart';

class OrderController extends GetxController {
  final status = ApiCallStatus.success.obs;
  final Rx<OrderModel?> activeOrder = Rx<OrderModel?>(null);
  final pastOrders = <OrderModel>[].obs;
  final isPlacingOrder = false.obs;
  Timer? _progressTimer;

  int? get currentCustomerId => ConfigPreference.getUserId();
  bool get isAuthenticated => currentCustomerId != null;

  @override
  void onInit() {
    super.onInit();
    if (DioConfig.isTestMode) {
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
      activeOrder.value = null;
      pastOrders.clear();
      status.value = ApiCallStatus.success;
      return;
    }

    status.value = ApiCallStatus.loading;
    try {
      final activeList = await OrderService.fetchActiveOrders(uid);
      if (activeList.isNotEmpty) {
        activeOrder.value = activeList.first;
      } else {
        activeOrder.value = null;
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
        if (activeOrder.value == null) {
          activeOrder.value = MockData.activeOrder;
        }
        pastOrders.assignAll(MockData.pastOrders);
        status.value = ApiCallStatus.success;
      } else {
        activeOrder.value = null;
        pastOrders.clear();
        status.value = ApiCallStatus.error;
      }
    }
  }

  Future<void> placeOrder({
    String? storeName,
    String? storeImageUrl,
    String? restaurantName,
    String? restaurantImageUrl,
    required double subtotal,
    required double deliveryFee,
    required double taxAndFees,
    required double total,
    required String deliveryAddress,
    StoreType storeType = StoreType.retail,
    String paymentType = 'cash',
    List<int>? menuIds,
    List<int>? quantities,
    List<double>? prices,
    int propertyId = 1,
    double latitude = 9.0320,
    double longitude = 38.7469,
  }) async {
    final uid = currentCustomerId;
    if (uid == null) {
      Get.snackbar(
        'sign_in_required'.tr,
        'sign_in_to_order'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isPlacingOrder.value = true;

    final effectiveName = storeName ?? restaurantName ?? 'AMN Restaurant';
    final effectiveImage = storeImageUrl ?? restaurantImageUrl ?? AppAssets.parcelBoxItem;

    // Current date formatted YYYY-MM-DD
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final effectiveMenuIds = (menuIds != null && menuIds.isNotEmpty) ? menuIds : [1];
    final effectiveQuantities = (quantities != null && quantities.isNotEmpty) ? quantities : [1];
    final effectivePrices = (prices != null && prices.isNotEmpty) ? prices : [total];

    final request = OrderCreateRequest(
      customerId: uid,
      menuIds: effectiveMenuIds,
      location: deliveryAddress,
      date: dateStr,
      paymentType: paymentType,
      quantities: effectiveQuantities,
      totalQuantity: effectiveQuantities.fold(0, (s, q) => s + q),
      prices: effectivePrices,
      totalPrice: total,
      totalItem: effectiveMenuIds.length,
      propertyId: propertyId,
      latitude: latitude,
      longitude: longitude,
    );

    await OrderService.createOrder(
      request: request,
      onSuccess: (data) async {
        isPlacingOrder.value = false;

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
          status: OrderProgressStatus.preparing,
          estimatedArrival: '25 mins',
          storeType: storeType,
          driver: const DriverInfo(
            name: 'Alex M.',
            vehicle: 'Silver Honda Civic',
            plateNumber: 'ABC-123',
            rating: 4.9,
            photoUrl: AppAssets.driverAvatar,
            phone: '+251 911 058 179',
          ),
        );

        activeOrder.value = newOrder;

        // If payment gateway returned a checkout URL (e.g. Chapa hosted checkout), navigate user to it
        String? checkoutUrl;
        if (data['data'] is Map<String, dynamic>) {
          final inner = data['data'] as Map<String, dynamic>;
          checkoutUrl = inner['checkout_url']?.toString() ??
              inner['payment_url']?.toString() ??
              inner['url']?.toString();
        }
        checkoutUrl ??= data['checkout_url']?.toString() ??
            data['payment_url']?.toString() ??
            data['url']?.toString();

        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          await Get.to(
            () => PaymentWebViewScreen(
              initialUrl: checkoutUrl!,
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
        isPlacingOrder.value = false;
        if (DioConfig.isTestMode) {
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
            status: OrderProgressStatus.preparing,
            estimatedArrival: '25 mins',
            storeType: storeType,
          );
          activeOrder.value = newOrder;
        } else {
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
  }

  Future<void> fetchDetail(dynamic orderId) async {
    final detail = await OrderService.fetchOrderDetail(orderId);
    if (detail != null) {
      activeOrder.value = detail;
    }
  }

  void cancelOrder() {
    activeOrder.value = null;
  }
}
