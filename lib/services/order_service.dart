import 'package:get/get.dart';
import '../config/dio_config.dart';
import '../constants/api_endpoints.dart';
import '../controllers/order_controller.dart';
import '../models/corporate_model.dart';
import '../models/courier_model.dart';
import '../models/order.dart';
import '../models/property_delivery_option.dart';
import '../models/store.dart';
import '../utils/templates/dio_template.dart';
import 'city_service.dart';
import 'delivery_pricing_service.dart';
import 'gebeta_location_service.dart';
import 'property_service.dart';

class OrderService {
  /// Fetch delivery options for a property, resolving prices from the pricing endpoint
  /// GET /delivery-price-by-car-and-city-id/{vehicle_id}/{city_id}
  static Future<List<PropertyDeliveryOption>> fetchPropertyDeliveryOptions(
    dynamic propertyId, {
    dynamic cityId = CityService.defaultCityId,
  }) async {
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

    // If options were returned, resolve their prices via the delivery-price endpoint
    if (list.isNotEmpty) {
      final updatedList = <PropertyDeliveryOption>[];
      for (final opt in list) {
        final resolved = await DeliveryPricingService.resolveDeliveryOptionPrice(
          option: opt,
          cityId: cityId,
          isCourier: false,
        );
        updatedList.add(resolved);
      }
      return updatedList;
    }

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

  static final Map<String, Map<String, dynamic>> _driverProfileCache = {};

  /// Fetch driver profile from /driver-profile/{id} to enrich driver info in customer app
  static Future<Map<String, dynamic>?> fetchDriverProfile(dynamic driverId) async {
    if (driverId == null) return null;
    final cleanId = driverId.toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanId.isEmpty || cleanId == '0') return null;

    if (_driverProfileCache.containsKey(cleanId)) {
      return _driverProfileCache[cleanId];
    }

    Map<String, dynamic>? result;
    await DioService.dioGet(
      path: ApiEndpoints.driverProfile(cleanId),
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
          result = data['data'] as Map<String, dynamic>;
          _driverProfileCache[cleanId] = result!;
        }
      },
    );
    return result;
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

    // Resolve existing active order (authoritative source for live status)
    OrderModel? effectiveExisting = existingOrder;
    if (effectiveExisting == null && Get.isRegistered<OrderController>()) {
      final oc = Get.find<OrderController>();
      effectiveExisting = oc.activeOrders.firstWhereOrNull(
        (o) => o.orderId.replaceAll(RegExp(r'[^0-9]'), '') == targetId,
      ) ?? (oc.activeOrder.value?.orderId.replaceAll(RegExp(r'[^0-9]'), '') == targetId ? oc.activeOrder.value : null);
    }

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

          // /my_active_order is the live source of truth for order status in the backend.
          // If the order has an advanced active status, preserve it instead of stale order_details status.
          if (effectiveExisting != null &&
              effectiveExisting.status != OrderProgressStatus.placed &&
              OrderModel.parseStatus(statusMap['status']) == OrderProgressStatus.placed) {
            statusMap['status'] = effectiveExisting.status.code.toString();
          }

          final rawDriverId = statusMap['driver_id'] ??
              (itemsList.isNotEmpty && itemsList.first is Map ? itemsList.first['driver_id'] : null) ??
              effectiveExisting?.driver != null;
          final cleanDriverId = rawDriverId?.toString().replaceAll(RegExp(r'[^0-9]'), '');

          if (cleanDriverId != null && cleanDriverId.isNotEmpty && cleanDriverId != '0') {
            if (effectiveExisting != null && effectiveExisting.status != OrderProgressStatus.placed) {
              statusMap['status'] = effectiveExisting.status.code.toString();
            }

            // Enrich driver details from driver-profile if not already populated
            if (!DioConfig.isTestMode &&
                (!statusMap.containsKey('driver_name') || statusMap['driver_name'] == null)) {
              final driverProfile = await fetchDriverProfile(cleanDriverId);
              if (driverProfile != null) {
                final fName = driverProfile['f_name']?.toString() ?? '';
                final lName = driverProfile['l_name']?.toString() ?? '';
                final fullName = '$fName $lName'.trim();
                if (fullName.isNotEmpty) statusMap['driver_name'] = fullName;
                if (driverProfile['phone'] != null) statusMap['driver_phone'] = driverProfile['phone'].toString();
                if (driverProfile['plate_number'] != null) statusMap['driver_plate'] = driverProfile['plate_number'].toString();
                final candidates = [
                  driverProfile['profile_picture'],
                  driverProfile['profile_image'],
                  driverProfile['car_image'],
                ];
                for (final c in candidates) {
                  final s = c?.toString().trim();
                  if (s != null && s.isNotEmpty && s.toLowerCase() != 'null') {
                    statusMap['driver_image'] = s;
                    break;
                  }
                }
                final vId = driverProfile['vehicle_id']?.toString();
                if (vId != null && vId.isNotEmpty) {
                  statusMap['vehicle_id'] = vId;
                  statusMap['driver_vehicle'] = DriverInfo.resolveVehicleName(vId);
                }
              }
            }
          }

          final propId = statusMap['property_id']?.toString() ??
              (itemsList.isNotEmpty && itemsList.first is Map
                  ? itemsList.first['property_id']?.toString()
                  : effectiveExisting?.items.firstOrNull?.item.storeId);

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
            existingOrder: effectiveExisting,
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
