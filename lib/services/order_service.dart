import '../constants/api_endpoints.dart';
import '../models/order.dart';
import '../utils/templates/dio_template.dart';

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
    OrderModel? order;
    await DioService.dioGet(
      path: ApiEndpoints.orderDetail(orderId),
      onSuccess: (response) {
        final resData = response.data;
        if (resData is Map<String, dynamic>) {
          final itemsList = resData['data'] is List ? resData['data'] as List : [];
          final statusMap = resData['order_status'] is Map<String, dynamic>
              ? resData['order_status'] as Map<String, dynamic>
              : (itemsList.isNotEmpty && itemsList.first is Map ? itemsList.first as Map<String, dynamic> : <String, dynamic>{});

          order = OrderModel.fromOrderDetailJson(
            statusJson: statusMap,
            itemsList: itemsList,
          );
        }
      },
    );
    return order;
  }
}
