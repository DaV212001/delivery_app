import '../constants/api_endpoints.dart';
import '../models/order.dart';
import '../models/store.dart';
import '../utils/templates/dio_template.dart';
import 'property_service.dart';

class OrderService {
  /// Create a new order
  static Future<void> createOrder({
    required OrderCreateRequest request,
    required Function(Map<String, dynamic> responseData) onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioPost(
      path: ApiEndpoints.order,
      data: request.toJson(),
      onSuccess: (response) {
        if (response.data is Map<String, dynamic>) {
          onSuccess(response.data as Map<String, dynamic>);
        } else {
          onSuccess({'message': 'Order placed successfully'});
        }
      },
      onFailure: (error, response) {
        String msg = 'Failed to place order';
        if (response.data is Map<String, dynamic>) {
          msg = response.data['message']?.toString() ?? msg;
        }
        onFailure(msg);
      },
    );
  }

  /// Fetch active orders for a customer
  static Future<List<OrderModel>> fetchActiveOrders(dynamic customerId) async {
    final list = <OrderModel>[];
    await PropertyService.ensurePropertiesCached();
    await DioService.dioGet(
      path: ApiEndpoints.activeOrders(customerId),
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(OrderModel.fromActiveOrderJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Fetch past orders for a customer
  static Future<List<OrderModel>> fetchPastOrders(dynamic customerId) async {
    final list = <OrderModel>[];
    await PropertyService.ensurePropertiesCached();
    await DioService.dioGet(
      path: ApiEndpoints.pastOrders(customerId),
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(OrderModel.fromActiveOrderJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Fetch full order details
  static Future<OrderModel?> fetchOrderDetail(dynamic orderId) async {
    final cleanId = orderId.toString().replaceAll(RegExp(r'[^0-9]'), '');
    final targetId = cleanId.isNotEmpty ? cleanId : orderId.toString();

    OrderModel? order;
    await DioService.dioGet(
      path: ApiEndpoints.orderDetail(targetId),
      onSuccess: (response) async {
        final resData = response.data;
        if (resData is Map<String, dynamic>) {
          final itemsList = resData['data'] is List ? resData['data'] as List : [];
          final statusMap = resData['order_status'] is Map<String, dynamic>
              ? resData['order_status'] as Map<String, dynamic>
              : (itemsList.isNotEmpty && itemsList.first is Map ? itemsList.first as Map<String, dynamic> : <String, dynamic>{});

          final propId = statusMap['property_id']?.toString() ??
              (itemsList.isNotEmpty && itemsList.first is Map ? itemsList.first['property_id']?.toString() : null);

          Store? store;
          if (propId != null && propId.isNotEmpty) {
            store = PropertyService.getCachedProperty(propId);
            if (store == null) {
              try {
                store = await PropertyService.resolveProperty(propId);
              } catch (_) {}
            }
          }

          order = OrderModel.fromOrderDetailJson(
            statusJson: statusMap,
            itemsList: itemsList,
            fallbackStore: store,
          );
        }
      },
    );
    return order;
  }
}
