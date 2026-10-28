import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_assets.dart';
import '../models/cart_item.dart';
import '../models/delivery_item.dart';
import '../models/order.dart';
import '../models/store.dart';
import '../utils/currency_utils.dart';

class PropertyOrderItemModel {
  final String? menuId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;

  const PropertyOrderItemModel({
    this.menuId,
    required this.name,
    this.imageUrl = '',
    required this.price,
    required this.quantity,
  });

  factory PropertyOrderItemModel.fromJson(Map<String, dynamic> json) {
    return PropertyOrderItemModel(
      menuId: json['menu_id']?.toString(),
      name: json['item_name']?.toString() ??
          json['name']?.toString() ??
          'Menu Item',
      imageUrl: json['item_image']?.toString() ??
          json['image']?.toString() ??
          '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'menu_id': menuId,
        'item_name': name,
        'item_image': imageUrl,
        'price': price,
        'quantity': quantity,
      };
}

class PropertyOrderModel {
  final int id;
  final int propertyId;
  final String? dateOnly;
  final String customerId;
  final String location;
  final DateTime date;
  final OrderProgressStatus status;
  final String rawStatus;
  final String paymentType;
  final String paymentStatus;
  final int totalQuantity;
  final double itemTotalPrice;
  final String? deliveryOptionId;
  final double kmPrice;
  final double totalKmPrice;
  final double paymentAmount;
  final int totalItem;
  final String? reason;
  final double? customerLatitude;
  final double? customerLongitude;
  final double? propertyLatitude;
  final double? propertyLongitude;
  final String? driverId;
  final String? orderType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Enriched fields from order detail
  final String? customerFirstName;
  final String? customerLastName;
  final String? customerPhone;
  final List<PropertyOrderItemModel> items;

  const PropertyOrderModel({
    required this.id,
    required this.propertyId,
    this.dateOnly,
    required this.customerId,
    required this.location,
    required this.date,
    required this.status,
    required this.rawStatus,
    required this.paymentType,
    required this.paymentStatus,
    required this.totalQuantity,
    required this.itemTotalPrice,
    this.deliveryOptionId,
    required this.kmPrice,
    required this.totalKmPrice,
    required this.paymentAmount,
    required this.totalItem,
    this.reason,
    this.customerLatitude,
    this.customerLongitude,
    this.propertyLatitude,
    this.propertyLongitude,
    this.driverId,
    this.orderType,
    this.createdAt,
    this.updatedAt,
    this.customerFirstName,
    this.customerLastName,
    this.customerPhone,
    this.items = const [],
  });

  factory PropertyOrderModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString() ?? '0';
    final parsedStatus = OrderModel.parseStatus(rawStatus);

    DateTime parsedDate = DateTime.now();
    if (json['date'] != null && json['date'].toString().isNotEmpty) {
      try {
        parsedDate = DateTime.parse(json['date'].toString());
      } catch (_) {}
    } else if (json['created_at'] != null && json['created_at'].toString().isNotEmpty) {
      try {
        parsedDate = DateTime.parse(json['created_at'].toString());
      } catch (_) {}
    }

    DateTime? parsedCreatedAt;
    if (json['created_at'] != null && json['created_at'].toString().isNotEmpty) {
      try {
        parsedCreatedAt = DateTime.parse(json['created_at'].toString());
      } catch (_) {}
    }

    DateTime? parsedUpdatedAt;
    if (json['updated_at'] != null && json['updated_at'].toString().isNotEmpty) {
      try {
        parsedUpdatedAt = DateTime.parse(json['updated_at'].toString());
      } catch (_) {}
    }

    // Check if items list was provided
    final itemsList = <PropertyOrderItemModel>[];
    if (json['items'] is List) {
      for (final it in json['items']) {
        if (it is Map<String, dynamic>) {
          itemsList.add(PropertyOrderItemModel.fromJson(it));
        }
      }
    } else if (json['item_name'] != null && json['item_name'].toString().isNotEmpty) {
      itemsList.add(PropertyOrderItemModel.fromJson(json));
    }

    return PropertyOrderModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      propertyId: int.tryParse(json['property_id']?.toString() ?? '0') ?? 0,
      dateOnly: json['date_only']?.toString(),
      customerId: json['customer_id']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      date: parsedDate,
      status: parsedStatus,
      rawStatus: rawStatus,
      paymentType: json['payment_type']?.toString() ?? '0',
      paymentStatus: json['payment_status']?.toString() ?? '0',
      totalQuantity: int.tryParse(json['total_quantity']?.toString() ?? '1') ?? 1,
      itemTotalPrice: double.tryParse(json['item_total_price']?.toString() ?? '0') ?? 0.0,
      deliveryOptionId: json['delivery_option_id']?.toString(),
      kmPrice: double.tryParse(json['km_price']?.toString() ?? '0') ?? 0.0,
      totalKmPrice: double.tryParse(json['total_km_price']?.toString() ?? '0') ?? 0.0,
      paymentAmount: double.tryParse(json['payment_amount']?.toString() ?? '0') ?? 0.0,
      totalItem: int.tryParse(json['total_item']?.toString() ?? '1') ?? 1,
      reason: json['reason']?.toString(),
      customerLatitude: double.tryParse(json['customer_latitude']?.toString() ?? ''),
      customerLongitude: double.tryParse(json['customer_longitude']?.toString() ?? ''),
      propertyLatitude: double.tryParse(json['property_latitude']?.toString() ?? ''),
      propertyLongitude: double.tryParse(json['property_longtude']?.toString() ??
          json['property_longitude']?.toString() ??
          ''),
      driverId: json['driver_id']?.toString(),
      orderType: json['order_type']?.toString(),
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      customerFirstName: json['customer_first_name']?.toString(),
      customerLastName: json['customer_last_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      items: itemsList,
    );
  }

  PropertyOrderModel copyWith({
    int? id,
    int? propertyId,
    String? dateOnly,
    String? customerId,
    String? location,
    DateTime? date,
    OrderProgressStatus? status,
    String? rawStatus,
    String? paymentType,
    String? paymentStatus,
    int? totalQuantity,
    double? itemTotalPrice,
    String? deliveryOptionId,
    double? kmPrice,
    double? totalKmPrice,
    double? paymentAmount,
    int? totalItem,
    String? reason,
    double? customerLatitude,
    double? customerLongitude,
    double? propertyLatitude,
    double? propertyLongitude,
    String? driverId,
    String? orderType,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerFirstName,
    String? customerLastName,
    String? customerPhone,
    List<PropertyOrderItemModel>? items,
  }) {
    return PropertyOrderModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      dateOnly: dateOnly ?? this.dateOnly,
      customerId: customerId ?? this.customerId,
      location: location ?? this.location,
      date: date ?? this.date,
      status: status ?? this.status,
      rawStatus: rawStatus ?? this.rawStatus,
      paymentType: paymentType ?? this.paymentType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      itemTotalPrice: itemTotalPrice ?? this.itemTotalPrice,
      deliveryOptionId: deliveryOptionId ?? this.deliveryOptionId,
      kmPrice: kmPrice ?? this.kmPrice,
      totalKmPrice: totalKmPrice ?? this.totalKmPrice,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      totalItem: totalItem ?? this.totalItem,
      reason: reason ?? this.reason,
      customerLatitude: customerLatitude ?? this.customerLatitude,
      customerLongitude: customerLongitude ?? this.customerLongitude,
      propertyLatitude: propertyLatitude ?? this.propertyLatitude,
      propertyLongitude: propertyLongitude ?? this.propertyLongitude,
      driverId: driverId ?? this.driverId,
      orderType: orderType ?? this.orderType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerFirstName: customerFirstName ?? this.customerFirstName,
      customerLastName: customerLastName ?? this.customerLastName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
    );
  }

  // Helper Getters

  /// Friendly display of Order ID (e.g. #AMN-25)
  String get orderCode => '#AMN-$id';

  /// Total customer payment or calculated total
  double get effectiveTotal {
    if (paymentAmount > 0) return paymentAmount;
    if (itemTotalPrice > 0) return itemTotalPrice + totalKmPrice;
    return 0.0;
  }

  /// Customer full name
  String get customerFullName {
    final first = (customerFirstName ?? '').trim();
    final last = (customerLastName ?? '').trim();
    final combined = '$first $last'.trim();
    return combined.isNotEmpty ? combined : 'Customer #$customerId';
  }

  /// Whether the order is currently active
  bool get isActive => status.isActive;

  /// Whether the order has been delivered
  bool get isDelivered => status.isDelivered;

  /// Whether the order was cancelled
  bool get isCancelled => status.isCancelled;

  /// Formatted date / time
  String get formattedDateTime {
    final target = createdAt ?? date;
    final now = DateTime.now();
    final isToday = target.year == now.year && target.month == now.month && target.day == now.day;
    final timeStr = DateFormat('hh:mm a').format(target);

    if (isToday) {
      return 'Today, $timeStr';
    }
    return DateFormat('MMM d, y • hh:mm a').format(target);
  }

  /// Formatted date only
  String get formattedDate {
    final target = createdAt ?? date;
    return DateFormat('MMM d, y').format(target);
  }

  /// Localized status string
  String get statusLabel => status.name.isNotEmpty ? OrderModel(
        orderId: orderCode,
        storeName: '',
        storeImageUrl: '',
        orderDate: date,
        items: const [],
        subtotal: itemTotalPrice,
        deliveryFee: totalKmPrice,
        taxAndFees: 0,
        total: effectiveTotal,
        deliveryAddress: location,
        status: status,
        estimatedArrival: '',
      ).statusLabel : 'Order Placed';

  /// Status badge color
  Color get statusColor {
    switch (status) {
      case OrderProgressStatus.placed:
        return const Color(0xFFF59E0B); // Amber / Orange
      case OrderProgressStatus.accepted:
        return const Color(0xFF3B82F6); // Blue
      case OrderProgressStatus.driverToShop:
        return const Color(0xFF6366F1); // Indigo
      case OrderProgressStatus.driverToYou:
        return const Color(0xFF06B6D4); // Cyan
      case OrderProgressStatus.delivered:
        return const Color(0xFF10B981); // Emerald / Green
      case OrderProgressStatus.cancelled:
        return const Color(0xFFEF4444); // Red
    }
  }

  /// Status icon
  IconData get statusIcon {
    switch (status) {
      case OrderProgressStatus.placed:
        return Icons.access_time_rounded;
      case OrderProgressStatus.accepted:
        return Icons.check_circle_outline_rounded;
      case OrderProgressStatus.driverToShop:
        return Icons.store_rounded;
      case OrderProgressStatus.driverToYou:
        return Icons.delivery_dining_rounded;
      case OrderProgressStatus.delivered:
        return Icons.task_alt_rounded;
      case OrderProgressStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  /// Payment method label
  String get paymentMethodLabel {
    switch (paymentType.toString()) {
      case '0':
        return 'Cash on Delivery';
      case '1':
        return 'Online (Chapa)';
      case '2':
        return 'AMN Wallet';
      default:
        return 'Standard';
    }
  }

  /// Payment status label
  String get paymentStatusLabel {
    switch (paymentStatus.toString()) {
      case '1':
        return 'Paid';
      case '0':
      default:
        return paymentType == '0' ? 'Pay on Delivery' : 'Unpaid';
    }
  }

  /// Convert to [OrderModel] for full map tracking
  OrderModel toOrderModel({
    Store? store,
    String? currencyCode,
  }) {
    final resolvedCurrency = currencyCode ?? CurrencyUtils.resolveCode(null);
    final storeName = store?.name ?? 'Store #$propertyId';
    final storeLogo = store?.logoUrl ?? store?.heroImageUrl ?? AppAssets.parcelBoxItem;

    final cartItems = items.isNotEmpty
        ? items.map((it) {
            return CartItem(
              id: it.menuId ?? 'item_${it.name}',
              item: DeliveryItem(
                id: it.menuId ?? '1',
                storeId: propertyId.toString(),
                name: it.name,
                description: '',
                price: it.price,
                imageUrl: it.imageUrl.isNotEmpty ? it.imageUrl : storeLogo,
                category: 'Order Item',
                currency: resolvedCurrency,
              ),
              quantity: it.quantity,
            );
          }).toList()
        : List.generate(
            totalItem > 0 ? totalItem : 1,
            (idx) => CartItem(
              id: 'item_$idx',
              item: DeliveryItem(
                id: 'menu_$idx',
                storeId: propertyId.toString(),
                name: '$storeName Item ${idx + 1}',
                description: '',
                price: totalItem > 0 ? (itemTotalPrice / totalItem) : itemTotalPrice,
                imageUrl: storeLogo,
                category: 'Order',
                currency: resolvedCurrency,
              ),
              quantity: 1,
            ),
          );

    return OrderModel(
      orderId: orderCode,
      storeName: storeName,
      storeImageUrl: storeLogo,
      orderDate: date,
      items: cartItems,
      subtotal: itemTotalPrice,
      deliveryFee: totalKmPrice,
      taxAndFees: 0.0,
      total: effectiveTotal,
      deliveryAddress: location,
      status: status,
      estimatedArrival: status == OrderProgressStatus.delivered
          ? 'Delivered'
          : (status == OrderProgressStatus.cancelled
              ? 'Cancelled'
              : (status == OrderProgressStatus.placed
                  ? 'Waiting for Driver'
                  : 'In Progress')),
      storeType: store?.type ?? StoreType.restaurant,
      storeLatitude: propertyLatitude ?? store?.latitude,
      storeLongitude: propertyLongitude ?? store?.longitude,
      deliveryLatitude: customerLatitude,
      deliveryLongitude: customerLongitude,
      currency: resolvedCurrency,
    );
  }
}
