import 'package:get/get.dart';
import '../constants/app_assets.dart';
import '../services/property_service.dart';
import 'cart_item.dart';
import 'delivery_item.dart';
import 'store.dart';

enum OrderProgressStatus {
  accepted,      // 1: Accepted
  driverToShop,  // 2: Driver on the way to shop
  driverToYou,   // 3: Driver on the way to you
  delivered,     // 4: Deliverd
  cancelled;     // 5: Cancelled

  /// Backward-compatibility aliases
  static const OrderProgressStatus preparing = OrderProgressStatus.accepted;
  static const OrderProgressStatus pickedUp = OrderProgressStatus.driverToShop;
  static const OrderProgressStatus onTheWay = OrderProgressStatus.driverToYou;

  /// Numeric status code
  int get code {
    switch (this) {
      case OrderProgressStatus.accepted:
        return 1;
      case OrderProgressStatus.driverToShop:
        return 2;
      case OrderProgressStatus.driverToYou:
        return 3;
      case OrderProgressStatus.delivered:
        return 4;
      case OrderProgressStatus.cancelled:
        return 5;
    }
  }

  bool get isActive =>
      this == OrderProgressStatus.accepted ||
      this == OrderProgressStatus.driverToShop ||
      this == OrderProgressStatus.driverToYou;

  bool get isDelivered => this == OrderProgressStatus.delivered;
  bool get isCancelled => this == OrderProgressStatus.cancelled;
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
  final String location;
  final String date;
  final String paymentType;
  final int totalQuantity;
  final List<int> menuIds;
  final List<int> quantities;
  final List<double> prices;
  final double itemTotalPrice;
  final int totalItem;
  final int propertyId;
  final double customerLatitude;
  final double customerLongitude;
  final double propertyLatitude;
  final double propertyLongitude;
  final dynamic deliveryOption;
  final num kmPrice;
  final num totalKmPrice;
  final String? destinationFriendlyLocation;

  const OrderCreateRequest({
    required this.customerId,
    required this.location,
    required this.date,
    this.paymentType = '0',
    required this.totalQuantity,
    required this.menuIds,
    required this.quantities,
    required this.prices,
    required this.itemTotalPrice,
    required this.totalItem,
    required this.propertyId,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.propertyLatitude,
    required this.propertyLongitude,
    this.deliveryOption = 1,
    this.kmPrice = 13,
    required this.totalKmPrice,
    this.destinationFriendlyLocation,
  });

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'location': location,
        'date': date,
        'payment_type': paymentType,
        'total_quantity': totalQuantity,
        'menu_id': menuIds,
        'quantity': quantities,
        'price': prices,
        'item_total_price': itemTotalPrice,
        'total_item': totalItem,
        'property_id': propertyId,
        'customer_latitude': customerLatitude,
        'customer_longitude': customerLongitude,
        'property_latitude': propertyLatitude,
        'property_longitude': propertyLongitude,
        'delivery_option': deliveryOption,
        'km_price': kmPrice,
        'total_km_price': totalKmPrice,
        'destination_friendly_location': (destinationFriendlyLocation != null &&
                destinationFriendlyLocation!.trim().isNotEmpty)
            ? destinationFriendlyLocation!.trim()
            : location,
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
  final String? destinationFriendlyLocation;
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
    this.destinationFriendlyLocation,
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
    String? destinationFriendlyLocation,
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
      destinationFriendlyLocation: destinationFriendlyLocation ?? this.destinationFriendlyLocation,
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
      case OrderProgressStatus.accepted:
        return 'order_accepted'.tr.isNotEmpty && 'order_accepted'.tr != 'order_accepted'
            ? 'order_accepted'.tr
            : 'Accepted';
      case OrderProgressStatus.driverToShop:
        return 'driver_to_shop'.tr.isNotEmpty && 'driver_to_shop'.tr != 'driver_to_shop'
            ? 'driver_to_shop'.tr
            : 'Driver on the way to shop';
      case OrderProgressStatus.driverToYou:
        return 'driver_to_you'.tr.isNotEmpty && 'driver_to_you'.tr != 'driver_to_you'
            ? 'driver_to_you'.tr
            : 'Driver on the way to you';
      case OrderProgressStatus.delivered:
        return 'delivered'.tr.isNotEmpty && 'delivered'.tr != 'delivered'
            ? 'delivered'.tr
            : 'Delivered';
      case OrderProgressStatus.cancelled:
        return 'cancelled'.tr.isNotEmpty && 'cancelled'.tr != 'cancelled'
            ? 'cancelled'.tr
            : 'Cancelled';
    }
  }

  /// Parses status codes from API / Socket:
  /// 1: Accepted
  /// 2: Driver on the way to shop
  /// 3: Driver on the way to you
  /// 4: Delivered
  /// 5: Cancelled
  static OrderProgressStatus parseStatus(dynamic raw) {
    if (raw == null) return OrderProgressStatus.accepted;
    final s = raw.toString().trim().toLowerCase();
    switch (s) {
      case '1':
      case 'accepted':
      case 'order_accepted':
      case 'preparing':
      case 'placed':
        return OrderProgressStatus.accepted;
      case '2':
      case 'driver_to_shop':
      case 'heading_to_store':
      case 'at_store':
      case 'picked_up':
      case 'driver on the way to shop':
        return OrderProgressStatus.driverToShop;
      case '3':
      case 'driver_to_you':
      case 'heading_to_customer':
      case 'in_transit':
      case 'on_the_way':
      case 'out_for_delivery':
      case 'driver on the way to you':
        return OrderProgressStatus.driverToYou;
      case '4':
      case 'delivered':
      case 'deliverd':
      case 'completed':
        return OrderProgressStatus.delivered;
      case '5':
      case '-1':
      case 'cancelled':
      case 'canceled':
        return OrderProgressStatus.cancelled;
      default:
        return OrderProgressStatus.accepted;
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
    final orderStatus = parseStatus(json['status']);

    final id = json['id']?.toString() ?? '';
    final friendlyDest = json['destination_friendly_location']?.toString();
    final loc = (friendlyDest != null && friendlyDest.trim().isNotEmpty)
        ? friendlyDest.trim()
        : (json['location']?.toString() ?? 'Addis Ababa');
    final totalPrice = double.tryParse(json['payment_amount']?.toString() ?? json['total_price']?.toString() ?? '0') ?? 0.0;
    final totalItems = int.tryParse(json['total_item']?.toString() ?? '1') ?? 1;
    final itemTotal = double.tryParse(json['item_total_price']?.toString() ?? '');
    final kmTotal = double.tryParse(json['total_km_price']?.toString() ?? '');

    final propId = json['property_id']?.toString();
    final cachedStore = PropertyService.getCachedProperty(propId);

    String rawStoreName = json['property_name']?.toString() ?? json['property']?.toString() ?? '';
    if (rawStoreName.trim().isEmpty || rawStoreName.toLowerCase() == 'null' || rawStoreName.toLowerCase() == 'store') {
      rawStoreName = cachedStore?.name ?? 'Store';
    }

    String rawStoreLogo = json['property_logo']?.toString() ?? '';
    if (rawStoreLogo.trim().isEmpty || rawStoreLogo.toLowerCase() == 'null') {
      rawStoreLogo = cachedStore?.logoUrl ?? cachedStore?.heroImageUrl ?? AppAssets.parcelBoxItem;
    }

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
      storeName: rawStoreName,
      storeImageUrl: rawStoreLogo,
      orderDate: date,
      items: List.generate(
        totalItems,
        (index) => CartItem(
          id: 'item_$index',
          item: DeliveryItem(
            id: 'menu_$index',
            storeId: propId ?? '1',
            name: rawStoreName != 'Store' ? '$rawStoreName Item ${index + 1}' : 'Order Item ${index + 1}',
            description: '',
            price: totalItems > 0 ? (totalPrice / totalItems) : totalPrice,
            imageUrl: rawStoreLogo,
            category: 'Order',
          ),
          quantity: 1,
        ),
      ),
      subtotal: itemTotal ?? (totalPrice * 0.9),
      deliveryFee: kmTotal ?? 50.0,
      taxAndFees: totalPrice > ((itemTotal ?? (totalPrice * 0.9)) + (kmTotal ?? 50.0))
          ? totalPrice - ((itemTotal ?? (totalPrice * 0.9)) + (kmTotal ?? 50.0))
          : 0.0,
      total: totalPrice,
      deliveryAddress: loc,
      destinationFriendlyLocation: friendlyDest,
      status: orderStatus,
      estimatedArrival: orderStatus == OrderProgressStatus.delivered
          ? 'Delivered'
          : (orderStatus == OrderProgressStatus.cancelled
              ? 'Cancelled'
              : (orderStatus == OrderProgressStatus.accepted ? '25 mins' : '15 mins')),
      storeType: cachedStore?.type ?? StoreType.restaurant,
      storeLatitude: double.tryParse(json['store_latitude']?.toString() ?? '') ?? cachedStore?.latitude,
      storeLongitude: double.tryParse(json['store_longitude']?.toString() ?? '') ?? cachedStore?.longitude,
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
    Store? fallbackStore,
  }) {
    final orderStatus = parseStatus(statusJson['status']);

    final id = statusJson['id']?.toString() ?? '';
    final friendlyDest = statusJson['destination_friendly_location']?.toString();
    final loc = (friendlyDest != null && friendlyDest.trim().isNotEmpty)
        ? friendlyDest.trim()
        : (statusJson['location']?.toString() ?? 'Addis Ababa');
    final totalPrice = double.tryParse(statusJson['payment_amount']?.toString() ?? statusJson['total_price']?.toString() ?? '0') ?? 0.0;
    final propId = statusJson['property_id']?.toString();
    final cachedStore = fallbackStore ?? PropertyService.getCachedProperty(propId);

    String storeName = '';
    String storeLogo = '';

    // 1. Scan itemsList: each item in /my_order_detail/{id} has "property" and "property_logo"
    for (final raw in itemsList) {
      if (raw is Map<String, dynamic>) {
        final p = raw['property']?.toString().trim();
        if (p != null && p.isNotEmpty && p.toLowerCase() != 'null') {
          storeName = p;
        }
        final logo = raw['property_logo']?.toString().trim();
        if (logo != null && logo.isNotEmpty && logo.toLowerCase() != 'null') {
          storeLogo = logo;
        }
      }
    }

    // 2. Next check statusJson
    if (storeName.isEmpty) {
      final pStatus = (statusJson['property_name'] ?? statusJson['property'] ?? statusJson['store_name'])?.toString().trim();
      if (pStatus != null && pStatus.isNotEmpty && pStatus.toLowerCase() != 'null') {
        storeName = pStatus;
      }
    }

    // 3. Fallback to cachedStore
    if (storeName.isEmpty && cachedStore != null && cachedStore.name.isNotEmpty) {
      storeName = cachedStore.name;
    }
    if (storeName.isEmpty) {
      storeName = 'Store';
    }

    if (storeLogo.isEmpty) {
      storeLogo = cachedStore?.logoUrl ?? cachedStore?.heroImageUrl ?? AppAssets.parcelBoxItem;
    }

    final parsedItems = <CartItem>[];
    double calculatedItemsSum = 0.0;

    for (int i = 0; i < itemsList.length; i++) {
      final raw = itemsList[i];
      if (raw is Map<String, dynamic>) {
        // Name resolution: check item_name, name, menu_name, product_name, title
        String rawName = (raw['item_name'] ?? raw['name'] ?? raw['menu_name'] ?? raw['product_name'] ?? raw['title'])?.toString().trim() ?? '';
        if (rawName.isEmpty || rawName.toLowerCase() == 'null') {
          rawName = storeName != 'Store' ? '$storeName Item ${i + 1}' : 'Order Item ${i + 1}';
        }

        // Image resolution: check item_image, image, menu_image
        String rawImage = (raw['item_image'] ?? raw['image'] ?? raw['menu_image'])?.toString().trim() ?? '';
        if (rawImage.isEmpty || rawImage.toLowerCase() == 'null') {
          rawImage = storeLogo.isNotEmpty ? storeLogo : AppAssets.parcelBoxItem;
        }

        final itemPrice = double.tryParse(raw['item_price']?.toString() ?? raw['price']?.toString() ?? '0') ?? 0.0;
        final qty = int.tryParse(raw['quantity']?.toString() ?? raw['qty']?.toString() ?? '1') ?? 1;

        calculatedItemsSum += itemPrice * qty;

        parsedItems.add(
          CartItem(
            id: raw['id']?.toString() ?? 'detail_item_$i',
            item: DeliveryItem(
              id: raw['menu_id']?.toString() ?? 'menu_$i',
              storeId: propId ?? '1',
              name: rawName,
              description: raw['description']?.toString() ?? '',
              price: itemPrice,
              imageUrl: rawImage,
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
    } else if (itemsList.isNotEmpty && itemsList.first is Map && itemsList.first['order_date'] != null) {
      try {
        date = DateTime.parse(itemsList.first['order_date']);
      } catch (_) {}
    }

    final itemTotal = double.tryParse(statusJson['item_total_price']?.toString() ?? '');
    final kmTotal = double.tryParse(statusJson['total_km_price']?.toString() ?? '');
    final subtotal = calculatedItemsSum > 0 ? calculatedItemsSum : (itemTotal ?? (totalPrice * 0.9));
    final deliveryFee = kmTotal ?? ((totalPrice > subtotal) ? (totalPrice - subtotal) : 50.0);
    final taxAndFees = (totalPrice - subtotal - deliveryFee) > 0 ? (totalPrice - subtotal - deliveryFee) : 0.0;

    DriverInfo? driverInfo;
    final driverId = statusJson['driver_id']?.toString();
    if (driverId != null && driverId.isNotEmpty && driverId != '0' && driverId.toLowerCase() != 'null') {
      final driverName = (statusJson['driver_name'] ?? statusJson['driver']?['name'])?.toString() ?? 'Alex M.';
      final driverPhone = (statusJson['driver_phone'] ?? statusJson['driver']?['phone'])?.toString() ?? '+251 911 058 179';
      driverInfo = DriverInfo(
        name: driverName,
        vehicle: statusJson['driver_vehicle']?.toString() ?? 'Delivery Motorcycle',
        plateNumber: statusJson['driver_plate']?.toString() ?? 'AA-2-12345',
        rating: 4.9,
        photoUrl: AppAssets.driverAvatar,
        phone: driverPhone,
      );
    }

    return OrderModel(
      orderId: '#AMN-$id',
      storeName: storeName,
      storeImageUrl: storeLogo,
      orderDate: date,
      items: parsedItems,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      taxAndFees: taxAndFees,
      total: totalPrice,
      deliveryAddress: loc,
      destinationFriendlyLocation: friendlyDest,
      status: orderStatus,
      estimatedArrival: orderStatus == OrderProgressStatus.delivered
          ? 'Delivered'
          : (orderStatus == OrderProgressStatus.cancelled
              ? 'Cancelled'
              : (orderStatus == OrderProgressStatus.accepted ? '25 mins' : '15 mins')),
      storeType: cachedStore?.type ?? StoreType.restaurant,
      storeLatitude: double.tryParse(statusJson['store_latitude']?.toString() ?? statusJson['restaurant_latitude']?.toString() ?? '') ?? cachedStore?.latitude,
      storeLongitude: double.tryParse(statusJson['store_longitude']?.toString() ?? statusJson['restaurant_longitude']?.toString() ?? '') ?? cachedStore?.longitude,
      deliveryLatitude: double.tryParse(statusJson['latitude']?.toString() ?? ''),
      deliveryLongitude: double.tryParse(statusJson['longitude']?.toString() ?? ''),
      driver: driverInfo,
    );
  }

  // Backward-compatibility getters
  String get restaurantName => storeName;
  String get restaurantImageUrl => storeImageUrl;
}
