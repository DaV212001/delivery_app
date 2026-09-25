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
  });

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
      storeName: 'AMN Restaurant',
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

    String storeName = 'AMN Restaurant';
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
