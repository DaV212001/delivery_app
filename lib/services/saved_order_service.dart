import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/dio_config.dart';
import '../config/storage_config.dart';
import '../controllers/order_controller.dart';
import '../models/order.dart';
import '../models/saved_order.dart';
import 'gebeta_location_service.dart';
import 'order_notification_retry_service.dart';
import 'order_service.dart';

class SavedOrderService {
  static const String _storageKey = 'amn_saved_orders_queue';
  static Timer? _checkTimer;
  static bool _isChecking = false;

  /// Initialize monitoring for due saved orders
  static void init() {
    if (DioConfig.isTestMode) return;
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      checkAndSubmitDueOrders();
    });
    // Check immediately on startup
    checkAndSubmitDueOrders();
  }

  /// Get all saved orders from local storage
  static List<SavedOrder> getSavedOrders() {
    try {
      final list = ConfigPreference.sharedPreferencesInstance.getStringList(_storageKey);
      if (list == null || list.isEmpty) return [];
      return list
          .map((str) {
            try {
              return SavedOrder.fromJsonString(str);
            } catch (_) {
              return null;
            }
          })
          .whereType<SavedOrder>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Save an order for later placement
  static Future<void> saveOrder(SavedOrder order) async {
    final current = getSavedOrders();
    // Remove if already exists with same ID
    current.removeWhere((o) => o.id == order.id);
    current.insert(0, order);

    final stringList = current.map((o) => o.toJsonString()).toList();
    await ConfigPreference.sharedPreferencesInstance.setStringList(_storageKey, stringList);

    // Schedule a timer specifically for this order if due within 24 hours
    final durationUntilOpen = order.scheduledOpenDateTime.difference(DateTime.now());
    if (!durationUntilOpen.isNegative && durationUntilOpen.inHours < 24) {
      Timer(durationUntilOpen, () {
        checkAndSubmitDueOrders();
      });
    }
  }

  /// Cancel a saved order
  static Future<void> cancelOrder(String orderId) async {
    final current = getSavedOrders();
    for (final o in current) {
      if (o.id == orderId) {
        o.status = 'cancelled';
      }
    }
    final stringList = current.map((o) => o.toJsonString()).toList();
    await ConfigPreference.sharedPreferencesInstance.setStringList(_storageKey, stringList);
  }

  /// Remove a saved order completely
  static Future<void> removeOrder(String orderId) async {
    final current = getSavedOrders();
    current.removeWhere((o) => o.id == orderId);
    final stringList = current.map((o) => o.toJsonString()).toList();
    await ConfigPreference.sharedPreferencesInstance.setStringList(_storageKey, stringList);
  }

  /// Check all pending orders and submit due ones automatically
  static Future<void> checkAndSubmitDueOrders() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final orders = getSavedOrders();
      final dueOrders = orders.where((o) => o.status == 'pending' && o.isDue).toList();

      for (final order in dueOrders) {
        await _submitSavedOrder(order);
      }
    } catch (_) {
      // Ignore background processing errors
    } finally {
      _isChecking = false;
    }
  }

  static Future<void> _submitSavedOrder(SavedOrder order) async {
    final uid = ConfigPreference.getUserId() ?? 1;
    final now = DateTime.now();
    final dateIso = now.toUtc().toIso8601String();

    String destinationFriendly = '';
    try {
      destinationFriendly = await GebetaLocationService.reverseGeocode(
        order.customerLatitude,
        order.customerLongitude,
      );
    } catch (_) {}
    if (destinationFriendly.trim().isEmpty) {
      destinationFriendly = order.deliveryAddress;
    }

    final request = OrderCreateRequest(
      customerId: uid,
      location: order.deliveryAddress,
      date: dateIso,
      paymentType: order.paymentType,
      totalQuantity: order.quantities.fold(0, (s, q) => s + q),
      menuIds: order.menuIds,
      quantities: order.quantities,
      prices: order.prices,
      itemTotalPrice: order.subtotal,
      totalItem: order.menuIds.length,
      propertyId: int.tryParse(order.storeId) ?? 1,
      customerLatitude: order.customerLatitude,
      customerLongitude: order.customerLongitude,
      propertyLatitude: order.propertyLatitude,
      propertyLongitude: order.propertyLongitude,
      deliveryOption: order.deliveryOption,
      kmPrice: order.kmPrice,
      totalKmPrice: order.totalKmPrice,
      destinationFriendlyLocation: destinationFriendly,
    );

    await OrderService.createOrder(
      request: request,
      onSuccess: (data) async {
        // Mark as submitted
        order.status = 'submitted';
        await saveOrder(order);

        // Track notification retry
        final rawId = (data['data'] is Map ? data['data']['id'] : null) ?? data['order_id'] ?? data['id'];
        final parsedId = rawId != null ? int.tryParse(rawId.toString()) : null;
        if (parsedId != null && parsedId > 0) {
          OrderNotificationRetryService.instance.trackNormalOrder(
            orderId: parsedId,
            amount: order.total,
            storeName: order.storeName,
            destination: destinationFriendly.isNotEmpty ? destinationFriendly : order.deliveryAddress,
            cityId: 1,
          );
        }

        // Notify user
        Get.snackbar(
          'scheduled_order_submitted_title'.tr,
          '${'scheduled_order_submitted_msg'.tr} ${order.storeName}!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
        );

        // Refresh orders if OrderController is active
        if (Get.isRegistered<OrderController>()) {
          final oc = Get.find<OrderController>();
          oc.loadOrders();
        }
      },
      onFailure: (error) {
        // If it failed because store is still reporting closed, keep pending; otherwise leave for next cycle
      },
    );
  }
}
