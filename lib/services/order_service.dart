import '../config/dio_config.dart';
import '../constants/api_endpoints.dart';
import '../models/corporate_model.dart';
import '../models/courier_model.dart';
import '../models/order.dart';
import '../models/property_delivery_option.dart';
import '../models/store.dart';
import '../utils/templates/dio_template.dart';
import 'gebeta_location_service.dart';
import 'property_service.dart';

class OrderService {
  /// Fetch delivery options for a property
  static Future<List<PropertyDeliveryOption>> fetchPropertyDeliveryOptions(dynamic propertyId) async {
    final list = <PropertyDeliveryOption>[];
    await DioService.dioGet(
      path: ApiEndpoints.propertyDeliveryOptions(propertyId),
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

  /// Initialize Chapa payment
  static Future<void> payOnChapa({
    required int userId,
    required double amount,
    required String date,
    int orderId = 1,
    required Function(String checkoutUrl, String message) onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioPost(
      path: ApiEndpoints.payOnChapa,
      data: {
        'user_id': userId,
        'amount': amount,
        'date': date,
        'order_id': orderId,
      },
      onSuccess: (response) {
        final checkoutUrl = findCheckoutUrl(response.data);
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

  /// Pay using AMN Wallet
  static Future<void> payOnWallet({
    required int userId,
    required double amount,
    required String date,
    int orderId = 1,
    required Function(Map<String, dynamic> data) onSuccess,
    required Function(String error) onFailure,
  }) async {
    await DioService.dioPost(
      path: ApiEndpoints.payOnWallet,
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

  /// Recursively scan any nested Map or List structure to locate checkout_url
  static String? findCheckoutUrl(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      if (data.containsKey('checkout_url') &&
          data['checkout_url'] != null &&
          data['checkout_url'].toString().isNotEmpty) {
        return data['checkout_url'].toString();
      }
      for (final entry in data.entries) {
        final key = entry.key.toString().toLowerCase();
        if ((key == 'checkout_url' || key == 'payment_url') &&
            entry.value != null &&
            entry.value.toString().isNotEmpty) {
          return entry.value.toString();
        }
        final found = findCheckoutUrl(entry.value);
        if (found != null && found.isNotEmpty) return found;
      }
    } else if (data is List) {
      for (final item in data) {
        final found = findCheckoutUrl(item);
        if (found != null && found.isNotEmpty) return found;
      }
    }
    return null;
  }

  /// Create a new order
  static Future<void> createOrder({
    required OrderCreateRequest request,
    required Function(Map<String, dynamic> responseData) onSuccess,
    required Function(String error) onFailure,
  }) async {
    final payload = request.toJson();

    // Ensure destination_friendly_location contains the reverse-geocoded name of destination coordinate
    if (!payload.containsKey('destination_friendly_location') ||
        payload['destination_friendly_location'] == null ||
        payload['destination_friendly_location'].toString().trim().isEmpty) {
      String resolved = '';
      try {
        resolved = await GebetaLocationService.reverseGeocode(
          request.customerLatitude,
          request.customerLongitude,
        );
      } catch (_) {}
      payload['destination_friendly_location'] =
          resolved.trim().isNotEmpty ? resolved.trim() : request.location;
    }

    await DioService.dioPost(
      path: ApiEndpoints.order,
      data: payload,
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
  static Future<OrderModel?> fetchOrderDetail(
    dynamic orderId, {
    OrderModel? existingOrder,
    String? orderType,
  }) async {
    final cleanId = orderId.toString().replaceAll(RegExp(r'[^0-9]'), '');
    final targetId = cleanId.isNotEmpty ? cleanId : orderId.toString();

    // Ensure properties are cached for store name & logo resolution
    await PropertyService.ensurePropertiesCached();

    OrderModel? order;
    final isCourierReq = orderType?.toLowerCase().contains('courier') == true ||
        orderType?.toLowerCase().contains('courir') == true;
    final isCorporateReq = orderType?.toLowerCase().contains('company') == true ||
        orderType?.toLowerCase().contains('corporate') == true;

    if (isCourierReq) {
      await DioService.dioGet(
        path: ApiEndpoints.courierOrderDetail(targetId),
        onSuccess: (response) {
          final resData = response.data;
          if (resData is Map<String, dynamic>) {
            final rawData = resData['data'];
            if (rawData is List && rawData.isNotEmpty && rawData.first is Map<String, dynamic>) {
              order = CourierOrderModel.fromJson(rawData.first).toOrderModel();
            } else if (rawData is Map<String, dynamic>) {
              order = CourierOrderModel.fromJson(rawData).toOrderModel();
            }
          }
        },
      );
      return order;
    }

    if (isCorporateReq) {
      await DioService.dioGet(
        path: ApiEndpoints.corporateOrderDetail(targetId),
        onSuccess: (response) {
          final resData = response.data;
          if (resData is Map<String, dynamic>) {
            final rawData = resData['data'];
            if (rawData is List && rawData.isNotEmpty && rawData.first is Map<String, dynamic>) {
              order = CompanyOrderModel.fromJson(rawData.first).toOrderModel();
            } else if (rawData is Map<String, dynamic>) {
              order = CompanyOrderModel.fromJson(rawData).toOrderModel();
            }
          }
        },
      );
      return order;
    }

    await DioService.dioGet(
      path: ApiEndpoints.orderDetail(targetId),
      onSuccess: (response) async {
        final resData = response.data;
        if (resData is Map<String, dynamic>) {
          List<dynamic> itemsList = [];
          Map<String, dynamic> statusMap = {};

          if (resData['data'] is List) {
            itemsList = resData['data'] as List;
          } else if (resData['data'] is Map<String, dynamic>) {
            final dataMap = resData['data'] as Map<String, dynamic>;
            statusMap = Map<String, dynamic>.from(dataMap);
            if (dataMap['items'] is List) {
              itemsList = dataMap['items'] as List;
            } else if (dataMap['menu_items'] is List) {
              itemsList = dataMap['menu_items'] as List;
            } else if (dataMap.containsKey('item_name') ||
                dataMap.containsKey('menu_id') ||
                dataMap.containsKey('price')) {
              itemsList = [dataMap];
            }
          }

          if (resData['order_status'] is Map<String, dynamic>) {
            statusMap = resData['order_status'] as Map<String, dynamic>;
          } else if (statusMap.isEmpty && itemsList.isNotEmpty && itemsList.first is Map) {
            statusMap = itemsList.first as Map<String, dynamic>;
          }

          final propId = statusMap['property_id']?.toString() ??
              (itemsList.isNotEmpty && itemsList.first is Map
                  ? itemsList.first['property_id']?.toString()
                  : existingOrder?.items.firstOrNull?.item.storeId);

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
            orderId: targetId,
            existingOrder: existingOrder,
          );
        }
      },
    );

    // Fallback chain for non-standard orders when orderType is unspecified and not in test mode
    if ((order == null || (order!.items.isEmpty && order!.storeName.isEmpty)) &&
        orderType == null &&
        !DioConfig.isTestMode) {
      // Try Courier endpoint: GET /courirer-order/{id}
      await DioService.dioGet(
        path: '${ApiEndpoints.courierOrder}/$targetId',
        onSuccess: (response) {
          final resData = response.data;
          if (resData is Map<String, dynamic> && resData['data'] is List && (resData['data'] as List).isNotEmpty) {
            final first = (resData['data'] as List).first;
            if (first is Map<String, dynamic>) {
              order = CourierOrderModel.fromJson(first).toOrderModel();
            }
          }
        },
      );

      if (order == null || (order!.items.isEmpty && order!.storeName.isEmpty)) {
        // Try Corporate endpoint: GET /company-order/{id}
        await DioService.dioGet(
          path: '${ApiEndpoints.companyOrder}/$targetId',
          onSuccess: (response) {
            final resData = response.data;
            if (resData is Map<String, dynamic> && resData['data'] is List && (resData['data'] as List).isNotEmpty) {
              final first = (resData['data'] as List).first;
              if (first is Map<String, dynamic>) {
                order = CompanyOrderModel.fromJson(first).toOrderModel();
              }
            }
          },
        );
      }
    }

    return order;
  }
}
