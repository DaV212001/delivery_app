import 'dart:convert';
import 'package:get/get.dart';

class SavedOrder {
  final String id;
  final String storeId;
  final String storeName;
  final String storeImageUrl;
  final String? openTime;
  final DateTime scheduledOpenDateTime;
  final DateTime createdAt;
  final String deliveryAddress;
  final String paymentType; // '0' cash, '1' chapa, '2' wallet
  final List<int> menuIds;
  final List<int> quantities;
  final List<double> prices;
  final double subtotal;
  final double totalKmPrice;
  final double total;
  final int deliveryOption;
  final double kmPrice;
  final double customerLatitude;
  final double customerLongitude;
  final double propertyLatitude;
  final double propertyLongitude;
  final List<String> itemNames;
  String status; // 'pending', 'submitted', 'cancelled'

  SavedOrder({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.storeImageUrl,
    this.openTime,
    required this.scheduledOpenDateTime,
    required this.createdAt,
    required this.deliveryAddress,
    required this.paymentType,
    required this.menuIds,
    required this.quantities,
    required this.prices,
    required this.subtotal,
    required this.totalKmPrice,
    required this.total,
    this.deliveryOption = 1,
    this.kmPrice = 13.0,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.propertyLatitude,
    required this.propertyLongitude,
    this.itemNames = const [],
    this.status = 'pending',
  });

  bool get isDue =>
      status == 'pending' && DateTime.now().isAfter(scheduledOpenDateTime);

  String get formattedScheduledTime {
    final hour = scheduledOpenDateTime.hour;
    final minute = scheduledOpenDateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    final isTomorrow = scheduledOpenDateTime.day != DateTime.now().day;
    final dayLabel = isTomorrow ? '${'tomorrow'.tr} ' : '${'today'.tr} ';
    return '$dayLabel$h:$m $period';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'storeId': storeId,
        'storeName': storeName,
        'storeImageUrl': storeImageUrl,
        'openTime': openTime,
        'scheduledOpenDateTime': scheduledOpenDateTime.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'deliveryAddress': deliveryAddress,
        'paymentType': paymentType,
        'menuIds': menuIds,
        'quantities': quantities,
        'prices': prices,
        'subtotal': subtotal,
        'totalKmPrice': totalKmPrice,
        'total': total,
        'deliveryOption': deliveryOption,
        'kmPrice': kmPrice,
        'customerLatitude': customerLatitude,
        'customerLongitude': customerLongitude,
        'propertyLatitude': propertyLatitude,
        'propertyLongitude': propertyLongitude,
        'itemNames': itemNames,
        'status': status,
      };

  factory SavedOrder.fromJson(Map<String, dynamic> json) {
    return SavedOrder(
      id: json['id']?.toString() ?? '',
      storeId: json['storeId']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? '',
      storeImageUrl: json['storeImageUrl']?.toString() ?? '',
      openTime: json['openTime']?.toString(),
      scheduledOpenDateTime: DateTime.tryParse(
              json['scheduledOpenDateTime']?.toString() ?? '') ??
          DateTime.now().add(const Duration(hours: 1)),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      deliveryAddress: json['deliveryAddress']?.toString() ?? 'Addis Ababa',
      paymentType: json['paymentType']?.toString() ?? '0',
      menuIds: (json['menuIds'] as List?)
              ?.map((e) => int.tryParse(e.toString()) ?? 1)
              .toList() ??
          [1],
      quantities: (json['quantities'] as List?)
              ?.map((e) => int.tryParse(e.toString()) ?? 1)
              .toList() ??
          [1],
      prices: (json['prices'] as List?)
              ?.map((e) => double.tryParse(e.toString()) ?? 0.0)
              .toList() ??
          [0.0],
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      totalKmPrice:
          double.tryParse(json['totalKmPrice']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      deliveryOption:
          int.tryParse(json['deliveryOption']?.toString() ?? '1') ?? 1,
      kmPrice: double.tryParse(json['kmPrice']?.toString() ?? '13') ?? 13.0,
      customerLatitude:
          double.tryParse(json['customerLatitude']?.toString() ?? '') ?? 9.0320,
      customerLongitude:
          double.tryParse(json['customerLongitude']?.toString() ?? '') ??
              38.7469,
      propertyLatitude:
          double.tryParse(json['propertyLatitude']?.toString() ?? '') ?? 9.0320,
      propertyLongitude:
          double.tryParse(json['propertyLongitude']?.toString() ?? '') ??
              38.7469,
      itemNames: (json['itemNames'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: json['status']?.toString() ?? 'pending',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SavedOrder.fromJsonString(String str) =>
      SavedOrder.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
