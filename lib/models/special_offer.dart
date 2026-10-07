import 'package:flutter/material.dart';
import 'delivery_item.dart';

class SpecialOffer {
  final String id;
  final String name;
  final String storeName;
  final String branchName;
  final double discountedPrice;
  final double originalPrice;
  final double discountPercent;
  final String imageUrl;
  final String storeId;
  final DeliveryItem? deliveryItem;

  const SpecialOffer({
    required this.id,
    required this.name,
    required this.storeName,
    required this.branchName,
    required this.discountedPrice,
    required this.originalPrice,
    required this.discountPercent,
    required this.imageUrl,
    required this.storeId,
    this.deliveryItem,
  });

  String get storeWithBranch => '$storeName | $branchName';
  String get formattedDiscountPercent => '${discountPercent.toStringAsFixed(1)}% OFF';
  String get formattedDiscountedPrice => '${discountedPrice.toStringAsFixed(1)} Br';
  String get formattedOriginalPrice => '${originalPrice.toStringAsFixed(2)} Br';

  DeliveryItem toDeliveryItem() {
    if (deliveryItem != null) return deliveryItem!;
    return DeliveryItem(
      id: id,
      storeId: storeId,
      name: name,
      description: '$storeName - $branchName',
      price: discountedPrice,
      imageUrl: imageUrl,
      category: 'Special Offers',
      isSpecialOffer: true,
      discountPercent: discountPercent,
    );
  }
}

class CircularCategory {
  final String id;
  final String name;
  final String categoryKey;
  final String? imageUrl;
  final IconData? icon;
  final Color backgroundColor;
  final Color iconColor;

  const CircularCategory({
    required this.id,
    required this.name,
    required this.categoryKey,
    this.imageUrl,
    this.icon,
    this.backgroundColor = const Color(0xFFE0F2FE),
    this.iconColor = Colors.white,
  });
}
