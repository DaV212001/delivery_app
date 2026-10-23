import '../config/dio_config.dart';
import '../constants/api_endpoints.dart';
import '../models/courier_model.dart';
import '../models/property_delivery_option.dart';
import '../services/gebeta_location_service.dart';
import '../services/order_service.dart';
import '../utils/templates/dio_template.dart';

class CourierService {
  static int? lastCreatedOrderId;

  /// Submit a new courier delivery order: POST /courirer-order
  static Future<bool> createCourierOrder(
    CourierOrderCreateRequest request, {
    Function(Map<String, dynamic> data)? onSuccess,
    Function(String error)? onFailure,
  }) async {
    if (DioConfig.isTestMode) {
      lastCreatedOrderId = 1;
      onSuccess?.call({'message': 'Order placed successfully', 'order_id': 1, 'id': 1});
      return true;
    }

    bool success = false;
    final payload = request.toJson();

    if (!payload.containsKey('from_friendly_location') ||
        payload['from_friendly_location'] == null ||
        payload['from_friendly_location'].toString().trim().isEmpty) {
      String resolvedFrom = '';
      try {
        resolvedFrom = await GebetaLocationService.reverseGeocode(
          request.fromLatitude,
          request.fromLongitude,
        );
      } catch (_) {}
      payload['from_friendly_location'] =
          resolvedFrom.trim().isNotEmpty ? resolvedFrom.trim() : (request.fromAddress ?? '');
    }

    if (!payload.containsKey('to_friendly_location') ||
        payload['to_friendly_location'] == null ||
        payload['to_friendly_location'].toString().trim().isEmpty) {
      String resolvedTo = '';
      try {
        resolvedTo = await GebetaLocationService.reverseGeocode(
          request.toLatitude,
          request.toLongitude,
        );
      } catch (_) {}
      payload['to_friendly_location'] =
          resolvedTo.trim().isNotEmpty ? resolvedTo.trim() : (request.toAddress ?? '');
    }

    await DioService.dioPost(
      path: ApiEndpoints.courierOrder,
      data: payload,
      onSuccess: (response) {
        success = true;
        if (response.data is Map<String, dynamic>) {
          final map = response.data as Map<String, dynamic>;
          final idVal = map['order_id'] ?? map['id'] ?? (map['data'] is Map ? map['data']['id'] : null);
          if (idVal != null) {
            lastCreatedOrderId = int.tryParse(idVal.toString());
          }
          onSuccess?.call(map);
        }
      },
      onFailure: (error, response) {
        success = false;
        String msg = 'Could not place courier order';
        if (response.data is Map<String, dynamic>) {
          msg = response.data['message']?.toString() ?? msg;
        }
        onFailure?.call(msg);
      },
    );
    return success;
  }

  /// Fetch courier delivery options (vehicle types and km rates): GET /courirer_delivery_option
  static Future<List<PropertyDeliveryOption>> fetchCourierDeliveryOptions() async {
    final list = <PropertyDeliveryOption>[];
    await DioService.dioGet(
      path: ApiEndpoints.courierDeliveryOptions,
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(PropertyDeliveryOption.fromJson(item));
            }
          }
        }
      },
      onFailure: (error, response) {
        // Fallback handled by caller
      },
    );
    return list;
  }

  /// Initialize Chapa payment for courier delivery: POST /courirer-pay-on-chapa
  static Future<void> payCourierOnChapa({
    required int userId,
    required double amount,
    required String date,
    int orderId = 1,
    required Function(String checkoutUrl, String message) onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioPost(
      path: ApiEndpoints.courierPayOnChapa,
      data: {
        'user_id': userId,
        'amount': amount,
        'date': date,
        'order_id': orderId,
      },
      onSuccess: (response) {
        final checkoutUrl = OrderService.findCheckoutUrl(response.data);
        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          String msg = 'Hosted Link';
          if (response.data is Map<String, dynamic>) {
            msg = response.data['message']?.toString() ?? msg;
          }
          onSuccess(checkoutUrl, msg);
        } else {
          onFailure('No checkout URL received from payment gateway');
        }
      },
      onFailure: (error, response) {
        String msg = 'Chapa payment failed';
        if (response.data is Map<String, dynamic>) {
          msg = response.data['message']?.toString() ?? msg;
        }
        onFailure(msg);
      },
    );
  }

  /// Pay for courier delivery using AMN Wallet: POST /courirer-pay-on-wallet
  static Future<void> payCourierOnWallet({
    required int userId,
    required double amount,
    required String date,
    int orderId = 1,
    required Function(Map<String, dynamic> data) onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioPost(
      path: ApiEndpoints.courierPayOnWallet,
      data: {
        'user_id': userId,
        'amount': amount,
        'date': date,
        'order_id': orderId,
      },
      onSuccess: (response) {
        if (response.data is Map<String, dynamic>) {
          onSuccess(response.data as Map<String, dynamic>);
        } else {
          onSuccess({'message': 'Payment successful'});
        }
      },
      onFailure: (error, response) {
        String msg = 'Wallet payment failed';
        if (response.data is Map<String, dynamic>) {
          msg = response.data['message']?.toString() ?? msg;
        }
        onFailure(msg);
      },
    );
  }

  /// Fetch active courier delivery orders for a user: GET /my_active_courirer_order/{userId}
  static Future<List<CourierOrderModel>> fetchActiveOrders(dynamic userId) async {
    if (DioConfig.isTestMode) {
      return [
        const CourierOrderModel(
          id: 1,
          status: '0',
          fromLatitude: 9.02497,
          fromLongitude: 38.74689,
          toLatitude: 8.98060,
          toLongitude: 38.75780,
          fromAddress: 'Bole Medhanialem, Addis Ababa',
          toAddress: 'Sarbet, Addis Ababa',
          senderFName: 'Abel',
          senderLName: 'Seyoum',
          senderPhone: '+251944070484',
          receiverName: 'Bluye',
          receiverPhone: '+251911234567',
          carType: 'Motorbike',
          kmPrice: 35.0,
          totalKm: 5.2,
          totalPrice: 182.0,
          dateTime: '2026-10-17 03:00:00',
          description: 'Fragile package, please handle with care',
        ),
      ];
    }

    final list = <CourierOrderModel>[];
    await DioService.dioGet(
      path: ApiEndpoints.activeCourierOrders(userId),
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(CourierOrderModel.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Fetch past completed/cancelled courier orders: GET /my_past_courirer_order/{userId}
  static Future<List<CourierOrderModel>> fetchPastOrders(dynamic userId) async {
    if (DioConfig.isTestMode) {
      return [
        const CourierOrderModel(
          id: 99,
          status: '3',
          fromLatitude: 9.0104,
          fromLongitude: 38.7617,
          toLatitude: 9.0320,
          toLongitude: 38.7469,
          fromAddress: 'Kazanchis, Addis Ababa',
          toAddress: 'Piazza, Addis Ababa',
          senderFName: 'Abel',
          senderLName: 'Seyoum',
          senderPhone: '+251944070484',
          receiverName: 'Kidus',
          receiverPhone: '+251922334455',
          carType: 'Motorbike',
          kmPrice: 35.0,
          totalKm: 4.8,
          totalPrice: 168.0,
          dateTime: '2026-10-15 14:20:00',
          description: 'Official Documents',
        ),
      ];
    }

    final list = <CourierOrderModel>[];
    await DioService.dioGet(
      path: ApiEndpoints.pastCourierOrders(userId),
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(CourierOrderModel.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }
}
