import 'cart_item.dart';

class CartBatch {
  final String propertyId;
  final String propertyName;
  final String? propertyImage;
  final List<CartItem> items;
  final DateTime updatedAt;

  CartBatch({
    required this.propertyId,
    required this.propertyName,
    this.propertyImage,
    required this.items,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => items.fold(0.0, (sum, i) => sum + i.totalPrice);

  Map<String, dynamic> toJson() => {
    'propertyId': propertyId,
    'propertyName': propertyName,
    'propertyImage': propertyImage,
    'items': items.map((i) => i.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CartBatch.fromJson(Map<String, dynamic> json) => CartBatch(
    propertyId: json['propertyId']?.toString() ?? '',
    propertyName: json['propertyName']?.toString() ?? 'Store',
    propertyImage: json['propertyImage']?.toString(),
    items: (json['items'] as List<dynamic>?)
            ?.map((i) => CartItem.fromJson(Map<String, dynamic>.from(i as Map)))
            .toList() ??
        [],
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
        : DateTime.now(),
  );
}
