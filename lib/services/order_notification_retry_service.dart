import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../config/storage_config.dart';
import '../constants/api_endpoints.dart';
import 'corporate_service.dart';
import 'courier_service.dart';
import 'order_service.dart';

enum OrderNotificationType {
  normal,
  corporate,
  courier,
}

class _OrderTracker {
  final int orderId;
  final OrderNotificationType type;
  final int? userId;
  final String title;
  final String payment;
  final String from;
  final String to;
  final dynamic cityId;
  int retriesPerformed = 0;
  Timer? timer;

  _OrderTracker({
    required this.orderId,
    required this.type,
    this.userId,
    required this.title,
    required this.payment,
    required this.from,
    required this.to,
    required this.cityId,
  });
}

/// Service that monitors new orders and sends retry push notifications if status has not changed to 1
/// (accepted by driver/rider) within 2 minutes. Retries at most 2 times.
class OrderNotificationRetryService {
  OrderNotificationRetryService._();
  static final OrderNotificationRetryService instance = OrderNotificationRetryService._();

  final Logger _logger = Logger();
  final Map<int, _OrderTracker> _trackers = {};

  Duration checkInterval = const Duration(minutes: 2);
  int maxRetries = 2;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  Dio? _customDio;
  Dio get _dioClient => _customDio ?? _dio;

  @visibleForTesting
  set dioClient(Dio? client) => _customDio = client;

  @visibleForTesting
  Future<bool> Function(OrderNotificationType type, int orderId, int? userId)? statusCheckOverride;

  @visibleForTesting
  int get activeTrackersCount => _trackers.length;

  @visibleForTesting
  bool isTracking(int orderId) => _trackers.containsKey(orderId);

  @visibleForTesting
  int getRetryCount(int orderId) => _trackers[orderId]?.retriesPerformed ?? 0;

  @visibleForTesting
  void clearAllTrackers() {
    for (final tracker in _trackers.values) {
      tracker.timer?.cancel();
    }
    _trackers.clear();
  }

  static String formatPayment(double amount) {
    if (amount.truncateToDouble() == amount) {
      return '${amount.toInt()} Birr';
    }
    return '${amount.toStringAsFixed(2)} Birr';
  }

  /// Start monitoring a newly placed normal store/food order
  void trackNormalOrder({
    required int orderId,
    required double amount,
    required String storeName,
    required String destination,
    dynamic cityId = 1,
    int? userId,
    String title = 'New Order Received',
  }) {
    if (orderId <= 0) return;
    _scheduleTracker(
      _OrderTracker(
        orderId: orderId,
        type: OrderNotificationType.normal,
        userId: userId ?? ConfigPreference.getUserId(),
        title: title,
        payment: formatPayment(amount),
        from: storeName.trim().isNotEmpty ? storeName.trim() : 'Store',
        to: destination.trim().isNotEmpty ? destination.trim() : 'Addis Ababa',
        cityId: cityId ?? 1,
      ),
    );
  }

  /// Start monitoring a newly placed corporate delivery order
  void trackCorporateOrder({
    required int orderId,
    required int userId,
    required double amount,
    required String fromBranch,
    required String toBranch,
    dynamic cityId = 1,
    String title = 'New Corporate Order',
  }) {
    if (orderId <= 0) return;
    _scheduleTracker(
      _OrderTracker(
        orderId: orderId,
        type: OrderNotificationType.corporate,
        userId: userId,
        title: title,
        payment: formatPayment(amount),
        from: fromBranch.trim().isNotEmpty ? fromBranch.trim() : 'Sender Branch',
        to: toBranch.trim().isNotEmpty ? toBranch.trim() : 'Receiver Branch',
        cityId: cityId ?? 1,
      ),
    );
  }

  /// Start monitoring a newly placed courier delivery order
  void trackCourierOrder({
    required int orderId,
    required int userId,
    required double amount,
    required String fromAddress,
    required String toAddress,
    dynamic cityId = 1,
    String title = 'New Courirre Order',
  }) {
    if (orderId <= 0) return;
    _scheduleTracker(
      _OrderTracker(
        orderId: orderId,
        type: OrderNotificationType.courier,
        userId: userId,
        title: title,
        payment: formatPayment(amount),
        from: fromAddress.trim().isNotEmpty ? fromAddress.trim() : 'Pickup Address',
        to: toAddress.trim().isNotEmpty ? toAddress.trim() : 'Dropoff Address',
        cityId: cityId ?? 1,
      ),
    );
  }

  /// Cancel retry tracking for an order (e.g. status already updated or order cancelled)
  void cancelTracking(int orderId) {
    final existing = _trackers.remove(orderId);
    if (existing != null) {
      existing.timer?.cancel();
      _logger.d('🛑 Cancelled notification retry tracker for order $orderId');
    }
  }

  void _scheduleTracker(_OrderTracker tracker) {
    // If a tracker for this order already exists, cancel it first
    cancelTracking(tracker.orderId);

    _logger.i('⏱️ Started notification retry tracker for ${tracker.type.name} order ${tracker.orderId}. Next check in ${checkInterval.inSeconds}s (max $maxRetries retries).');
    tracker.timer = Timer(checkInterval, () => _handleRetryStep(tracker.orderId));
    _trackers[tracker.orderId] = tracker;
  }

  Future<void> _handleRetryStep(int orderId) async {
    final tracker = _trackers[orderId];
    if (tracker == null) return;

    _logger.i('🔍 Checking status for ${tracker.type.name} order $orderId (Retry attempt #${tracker.retriesPerformed + 1} of $maxRetries)...');

    bool isAcceptedOrFinished = false;
    try {
      isAcceptedOrFinished = await isStatusChangedTo1(
        tracker.type,
        tracker.orderId,
        tracker.userId,
      );
    } catch (e) {
      _logger.w('⚠️ Error checking order status for $orderId: $e');
    }

    if (isAcceptedOrFinished) {
      _logger.i('✅ Order $orderId status has changed to 1 (accepted/assigned/finished). Skipping notification and stopping retry tracker.');
      cancelTracking(orderId);
      return;
    }

    // Status has NOT changed to 1, send notification retry
    tracker.retriesPerformed++;
    _logger.i('📢 Order $orderId status is still pending (not 1). Sending push notification retry #${tracker.retriesPerformed}...');

    await _sendNotification(tracker);

    // If remaining retries exist, schedule next check
    if (tracker.retriesPerformed < maxRetries) {
      _logger.i('⏱️ Scheduling retry #${tracker.retriesPerformed + 1} for order $orderId in ${checkInterval.inSeconds}s...');
      tracker.timer = Timer(checkInterval, () => _handleRetryStep(orderId));
    } else {
      _logger.i('🏁 Order $orderId reached maximum notification retries ($maxRetries). Stopping tracker.');
      cancelTracking(orderId);
    }
  }

  Future<void> _sendNotification(_OrderTracker tracker) async {
    String endpoint;
    Map<String, dynamic> payload;

    switch (tracker.type) {
      case OrderNotificationType.normal:
        endpoint = ApiEndpoints.pushNewOrder;
        payload = {
          'order_id': tracker.orderId,
          'title': tracker.title,
          'payment': tracker.payment,
          'from': tracker.from,
          'to': tracker.to,
          'city_id': tracker.cityId is int
              ? tracker.cityId
              : int.tryParse(tracker.cityId?.toString() ?? '1') ?? 1,
        };
        break;

      case OrderNotificationType.corporate:
        endpoint = ApiEndpoints.pushCorporateOrder;
        payload = {
          'order_id': tracker.orderId,
          'title': tracker.title,
          'city_id': tracker.cityId is int
              ? tracker.cityId
              : int.tryParse(tracker.cityId?.toString() ?? '1') ?? 1,
          'payment': tracker.payment,
          'from': tracker.from,
          'to': tracker.to,
        };
        break;

      case OrderNotificationType.courier:
        endpoint = ApiEndpoints.pushCourierOrder;
        payload = {
          'order_id': tracker.orderId,
          'title': tracker.title,
          'payment': tracker.payment,
          'from': tracker.from,
          'city_id': tracker.cityId.toString(),
          'to': tracker.to,
        };
        break;
    }

    try {
      _logger.i('📤 Sending notification retry to $endpoint for order ${tracker.orderId}: $payload');
      final response = await _dioClient.post(
        endpoint,
        data: payload,
      );
      _logger.i('📬 Notification endpoint response [HTTP ${response.statusCode}]: ${response.data}');
    } catch (e) {
      // "Currently, the API will say it skiped it because of duplication but this will be fixed, ignore it."
      _logger.w('ℹ️ Notification API response for order ${tracker.orderId} (ignoring duplicate skip/warning): $e');
    }
  }

  /// Checks if the order status has moved to 1 (accepted/assigned) or beyond (delivered/finished)
  Future<bool> isStatusChangedTo1(
    OrderNotificationType type,
    int orderId,
    int? userId,
  ) async {
    if (statusCheckOverride != null) {
      return await statusCheckOverride!(type, orderId, userId);
    }

    switch (type) {
      case OrderNotificationType.normal:
        try {
          final order = await OrderService.fetchOrderDetail(orderId);
          if (order != null) {
            // Status code 0 is placed/pending. Code >= 1 is accepted or beyond.
            return order.status.code >= 1 || order.driver != null;
          }
        } catch (e) {
          _logger.w('Failed checking normal order status: $e');
        }
        return false;

      case OrderNotificationType.corporate:
        final uid = userId ?? ConfigPreference.getUserId() ?? 0;
        if (uid <= 0) return false;

        try {
          final pending = await CorporateService.fetchPendingOrders(uid);
          final match = pending.where((o) => o.id == orderId).firstOrNull;
          if (match != null) {
            // Status != '0' or driver assigned means status is 1 or beyond
            return match.status != '0' || match.hasDriver;
          }

          // If not in pending, check finished
          final finished = await CorporateService.fetchFinishedOrders(uid);
          if (finished.any((o) => o.id == orderId)) {
            return true;
          }
        } catch (e) {
          _logger.w('Failed checking corporate order status: $e');
        }
        return false;

      case OrderNotificationType.courier:
        final uid = userId ?? ConfigPreference.getUserId() ?? 0;
        if (uid <= 0) return false;

        try {
          final active = await CourierService.fetchActiveOrders(uid);
          final match = active.where((o) => o.id == orderId).firstOrNull;
          if (match != null) {
            // Status != '0' or rider assigned means status is 1 or beyond
            return match.status != '0' || match.hasDriverAssigned;
          }

          // If not in active, check past orders
          final past = await CourierService.fetchPastOrders(uid);
          if (past.any((o) => o.id == orderId)) {
            return true;
          }
        } catch (e) {
          _logger.w('Failed checking courier order status: $e');
        }
        return false;
    }
  }
}
