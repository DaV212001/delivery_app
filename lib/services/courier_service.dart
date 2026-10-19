import '../config/dio_config.dart';
import '../constants/api_endpoints.dart';
import '../models/courier_model.dart';
import '../utils/templates/dio_template.dart';

class CourierService {
  /// Submit a new courier delivery order: POST /courirer-order
  static Future<bool> createCourierOrder(CourierOrderCreateRequest request) async {
    if (DioConfig.isTestMode) {
      return true;
    }

    bool success = false;
    await DioService.dioPost(
      path: ApiEndpoints.courierOrder,
      data: request.toJson(),
      onSuccess: (response) {
        success = true;
      },
      onFailure: (error, response) {
        success = false;
      },
    );
    return success;
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
