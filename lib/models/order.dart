import 'package:get/get.dart';
import '../constants/app_assets.dart';
import 'cart_item.dart';
import 'delivery_item.dart';
import 'store.dart';

enum OrderProgressStatus {
  preparing,
  pickedUp,
  onTheWay,
  delivered,
}

class DriverInfo {
  final String name;
  final String vehicle;
  final String plateNumber;
  final double rating;
  final String photoUrl;
  final String phone;

  const DriverInfo({
    required this.name,
    required this.vehicle,
    required this.plateNumber,
    required this.rating,
    required this.photoUrl,
    required this.phone,
  });
}

class OrderCreateRequest {
  final int customerId;
  final List<int> menuIds;
  final String location;
  final String date;
  final String paymentType;
  final List<int> quantities;
  final int totalQuantity;
  final List<double> prices;
  final double totalPrice;
  final int totalItem;
  final int propertyId;
  final double latitude;
  final double longitude;

  const OrderCreateRequest({
    required this.customerId,
    required this.menuIds,
    required this.location,
    required this.date,
    this.paymentType = 'cash',
    required this.quantities,
    required this.totalQuantity,
    required this.prices,
    required this.totalPrice,
    required this.totalItem,
    required this.propertyId,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'menu_id': menuIds,
        'location': location,
        'date': date,
        'payment_type': paymentType,
        'quantity': quantities,
        'total_quantity': totalQuantity,
        'price': prices,
        'total_price': totalPrice,
        'total_item': totalItem,
        'property_id': propertyId,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class OrderModel {
  final String orderId; // e.g. "#AMN-8924"
  final String storeName;
  final String storeImageUrl;
  final DateTime orderDate;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double taxAndFees;
  final double total;
  final String deliveryAddress;
  final OrderProgressStatus status;
  final String estimatedArrival; // e.g. "12 mins"
  final DriverInfo? driver;
  final StoreType storeType;
  final double? storeLatitude;
  final double? storeLongitude;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double? driverLatitude;
  final double? driverLongitude;

  const OrderModel({
    required this.orderId,
    required this.storeName,
    required this.storeImageUrl,
    required this.orderDate,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.taxAndFees,
    required this.total,
    required this.deliveryAddress,
    required this.status,
    required this.estimatedArrival,
    this.driver,
    this.storeType = StoreType.retail,
    this.storeLatitude,
    this.storeLongitude,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.driverLatitude,
    this.driverLongitude,
  });

  OrderModel copyWith({
    String? orderId,
    String? storeName,
    String? storeImageUrl,
    DateTime? orderDate,
    List<CartItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? taxAndFees,
    double? total,
    String? deliveryAddress,
    OrderProgressStatus? status,
    String? estimatedArrival,
    DriverInfo? driver,
    StoreType? storeType,
    double? storeLatitude,
    double? storeLongitude,
    double? deliveryLatitude,
    double? deliveryLongitude,
    double? driverLatitude,
    double? driverLongitude,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      storeName: storeName ?? this.storeName,
      storeImageUrl: storeImageUrl ?? this.storeImageUrl,
      orderDate: orderDate ?? this.orderDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      taxAndFees: taxAndFees ?? this.taxAndFees,
      total: total ?? this.total,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      status: status ?? this.status,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      driver: driver ?? this.driver,
      storeType: storeType ?? this.storeType,
      storeLatitude: storeLatitude ?? this.storeLatitude,
      storeLongitude: storeLongitude ?? this.storeLongitude,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      driverLatitude: driverLatitude ?? this.driverLatitude,
      driverLongitude: driverLongitude ?? this.driverLongitude,
    );
  }

  String get statusLabel {
    switch (status) {
      case OrderProgressStatus.preparing:
        return 'preparing_order'.tr;
      case OrderProgressStatus.pickedUp:
        return 'picked_up'.tr;
      case OrderProgressStatus.onTheWay:
        return 'in_transit'.tr;
      case OrderProgressStatus.delivered:
        return 'delivered'.tr;
    }
  }


  static const Map<String, ({double lat, double lng})> _knownStoreCoords = {
    'Chanoly Noodles': (lat: 9.0054, lng: 38.7636),
    'Chanoly Olympia': (lat: 9.0054, lng: 38.7636),
    'Injoy Burger': (lat: 9.0012, lng: 38.7610),
    'TechHub Express': (lat: 9.0210, lng: 38.7850),
    'FreshMart Organics': (lat: 8.9950, lng: 38.7350),
    'CareFirst Pharmacy': (lat: 9.0150, lng: 38.7650),
    'Burger Foundry': (lat: 9.0120, lng: 38.7700),
    'Bloom & Petal Florals': (lat: 9.0080, lng: 38.7800),
    "Luigi's Italian Bistro": (lat: 9.0300, lng: 38.7500),
    'Express Courier': (lat: 9.0250, lng: 38.7600),
  };

  double get effectiveStoreLatitude {
    if (storeLatitude != null) return storeLatitude!;
    return _knownStoreCoords[storeName]?.lat ?? 9.0054;
  }

  double get effectiveStoreLongitude {
    if (storeLongitude != null) return storeLongitude!;
    return _knownStoreCoords[storeName]?.lng ?? 38.7636;
  }

  double get effectiveDeliveryLatitude {
    if (deliveryLatitude != null) return deliveryLatitude!;
    return 9.0192;
  }

  double get effectiveDeliveryLongitude {
    if (deliveryLongitude != null) return deliveryLongitude!;
    return 38.7525;
  }

  factory OrderModel.fromActiveOrderJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString() ?? '0';
    OrderProgressStatus orderStatus;
    switch (rawStatus) {
      case '1':
        orderStatus = OrderProgressStatus.pickedUp;
        break;
      case '2':
        orderStatus = OrderProgressStatus.onTheWay;
        break;
      case '3':
        orderStatus = OrderProgressStatus.delivered;
        break;
      default:
        orderStatus = OrderProgressStatus.preparing;
    }

    final id = json['id']?.toString() ?? '';
    final loc = json['location']?.toString() ?? 'Addis Ababa';
    final totalPrice = double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0;
    final totalItems = int.tryParse(json['total_item']?.toString() ?? '1') ?? 1;

    DateTime date = DateTime.now();
    if (json['date'] != null) {
      try {
        date = DateTime.parse(json['date']);
      } catch (_) {
        if (json['created_at'] != null) {
          try {
            date = DateTime.parse(json['created_at']);
          } catch (_) {}
        }
      }
    }

    return OrderModel(
      orderId: '#AMN-$id',
      storeName: json['property_name']?.toString() ?? json['property']?.toString() ?? 'Store',
      storeImageUrl: AppAssets.parcelBoxItem,
      orderDate: date,
      items: List.generate(
        totalItems,
        (index) => CartItem(
          id: 'item_$index',
          item: DeliveryItem(
            id: 'menu_$index',
            storeId: json['property_id']?.toString() ?? '1',
            name: 'Order Item ${index + 1}',
            description: '',
            price: totalPrice / totalItems,
            imageUrl: AppAssets.parcelBoxItem,
            category: 'Order',
          ),
          quantity: 1,
        ),
      ),
      subtotal: totalPrice * 0.9,
      deliveryFee: 50.0,
      taxAndFees: totalPrice * 0.1,
      total: totalPrice,
      deliveryAddress: loc,
      status: orderStatus,
      estimatedArrival: orderStatus == OrderProgressStatus.delivered ? 'Delivered' : '20 mins',
      storeType: StoreType.restaurant,
      storeLatitude: double.tryParse(json['store_latitude']?.toString() ?? ''),
      storeLongitude: double.tryParse(json['store_longitude']?.toString() ?? ''),
      deliveryLatitude: double.tryParse(json['latitude']?.toString() ?? ''),
      deliveryLongitude: double.tryParse(json['longitude']?.toString() ?? ''),
      driver: const DriverInfo(
        name: 'Alex M.',
        vehicle: 'Silver Honda Civic',
        plateNumber: 'ABC-123',
        rating: 4.9,
        photoUrl: AppAssets.driverAvatar,
        phone: '+251 911 058 179',
      ),
    );
  }

  factory OrderModel.fromOrderDetailJson({
    required Map<String, dynamic> statusJson,
    required List<dynamic> itemsList,
  }) {
    final rawStatus = statusJson['status']?.toString() ?? '0';
    OrderProgressStatus orderStatus;
    switch (rawStatus) {
      case '1':
        orderStatus = OrderProgressStatus.pickedUp;
        break;
      case '2':
        orderStatus = OrderProgressStatus.onTheWay;
        break;
      case '3':
        orderStatus = OrderProgressStatus.delivered;
        break;
      default:
        orderStatus = OrderProgressStatus.preparing;
    }

    final id = statusJson['id']?.toString() ?? '';
    final loc = statusJson['location']?.toString() ?? 'Addis Ababa';
    final totalPrice = double.tryParse(statusJson['total_price']?.toString() ?? '0') ?? 0.0;

    String storeName = statusJson['property_name']?.toString() ?? statusJson['property']?.toString() ?? 'Store';
    String storeLogo = AppAssets.parcelBoxItem;

    final parsedItems = <CartItem>[];
    for (int i = 0; i < itemsList.length; i++) {
      final raw = itemsList[i];
      if (raw is Map<String, dynamic>) {
        if (raw['property'] != null) storeName = raw['property'].toString();
        if (raw['property_logo'] != null) storeLogo = raw['property_logo'].toString();

        final itemPrice = double.tryParse(raw['item_price']?.toString() ?? '0') ?? 0.0;
        final qty = int.tryParse(raw['quantity']?.toString() ?? '1') ?? 1;

        parsedItems.add(
          CartItem(
            id: 'detail_item_$i',
            item: DeliveryItem(
              id: 'menu_$i',
              storeId: statusJson['property_id']?.toString() ?? '1',
              name: raw['item_name']?.toString() ?? 'Menu Item',
              description: '',
              price: itemPrice,
              imageUrl: raw['item_image']?.toString() ?? storeLogo,
              category: 'Menu',
            ),
            quantity: qty,
          ),
        );
      }
    }

    DateTime date = DateTime.now();
    if (statusJson['created_at'] != null) {
      try {
        date = DateTime.parse(statusJson['created_at']);
      } catch (_) {}
    }

    return OrderModel(
      orderId: '#AMN-$id',
      storeName: storeName,
      storeImageUrl: storeLogo,
      orderDate: date,
      items: parsedItems,
      subtotal: totalPrice * 0.9,
      deliveryFee: 50.0,
      taxAndFees: totalPrice * 0.1,
      total: totalPrice,
      deliveryAddress: loc,
      status: orderStatus,
      estimatedArrival: orderStatus == OrderProgressStatus.delivered ? 'Delivered' : '20 mins',
      storeType: StoreType.restaurant,
      storeLatitude: double.tryParse(statusJson['store_latitude']?.toString() ?? ''),
      storeLongitude: double.tryParse(statusJson['store_longitude']?.toString() ?? ''),
      deliveryLatitude: double.tryParse(statusJson['latitude']?.toString() ?? ''),
      deliveryLongitude: double.tryParse(statusJson['longitude']?.toString() ?? ''),
      driver: const DriverInfo(
        name: 'Alex M.',
        vehicle: 'Silver Honda Civic',
        plateNumber: 'ABC-123',
        rating: 4.9,
        photoUrl: AppAssets.driverAvatar,
        phone: '+251 911 058 179',
      ),
    );
  }

  // Backward-compatibility getters
  String get restaurantName => storeName;
  String get restaurantImageUrl => storeImageUrl;
}
