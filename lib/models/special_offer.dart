import 'package:flutter/material.dart';
import 'delivery_item.dart';
import '../utils/currency_utils.dart';

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
  final String? currency;

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
    this.currency,
  });

  String get displayCurrency {
    final effectiveCurrency = (currency != null && currency!.trim().isNotEmpty)
        ? currency!.trim()
        : deliveryItem?.currency?.trim();

    if (effectiveCurrency != null && effectiveCurrency.isNotEmpty) {
      return CurrencyUtils.resolveCode(effectiveCurrency);
    }

    if (deliveryItem != null && deliveryItem!.displayCurrency.isNotEmpty) {
      return deliveryItem!.displayCurrency;
    }

    return 'Br';
  }

  String get storeWithBranch => '$storeName | $branchName';
  String get formattedDiscountPercent => '${discountPercent.toStringAsFixed(1)}% OFF';
  String get formattedDiscountedPrice => '${discountedPrice.toStringAsFixed(1)} $displayCurrency';
  String get formattedOriginalPrice => '${originalPrice.toStringAsFixed(2)} $displayCurrency';

  DeliveryItem toDeliveryItem() {
    if (deliveryItem != null) {
      if (deliveryItem!.currency == null && currency != null) {
        return DeliveryItem(
          id: deliveryItem!.id,
          storeId: deliveryItem!.storeId,
          name: deliveryItem!.name,
          description: deliveryItem!.description,
          price: deliveryItem!.price,
          imageUrl: deliveryItem!.imageUrl,
          category: deliveryItem!.category,
          unit: deliveryItem!.unit,
          variantTitle: deliveryItem!.variantTitle,
          availableVariants: deliveryItem!.availableVariants,
          availableAddons: deliveryItem!.availableAddons,
          removableOptions: deliveryItem!.removableOptions,
          isSpecialOffer: deliveryItem!.isSpecialOffer,
          discountPercent: deliveryItem!.discountPercent,
          currency: currency,
        );
      }
      return deliveryItem!;
    }
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
      currency: currency,
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
