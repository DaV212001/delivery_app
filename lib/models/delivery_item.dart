import '../utils/currency_utils.dart';

class DeliveryItem {
  final String id;
  final String storeId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String unit; // e.g. "each", "pack", "kg", "box"
  final String? variantTitle; // e.g. "Select Color", "Select Size", "Choice of Meat Temperature", "Grind"
  final List<String> availableVariants; // e.g. ["Midnight Black", "Pearl White"] or ["Medium Rare", "Medium"]
  final List<CustomizationAddon> availableAddons; // e.g. ["Extended Warranty", "USB-C Adapter", "Gift Wrap"]
  final List<String> removableOptions; // e.g. ["No Onions", "No plastic packaging"]
  final bool isSpecialOffer;
  final double discountPercent;
  final String? currency;

  const DeliveryItem({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.unit = 'each',
    this.variantTitle,
    this.availableVariants = const [],
    this.availableAddons = const [],
    this.removableOptions = const [],
    this.isSpecialOffer = false,
    this.discountPercent = 0.0,
    this.currency,
  });

  String get displayCurrency {
    if (currency != null && currency!.trim().isNotEmpty) {
      return CurrencyUtils.resolveCode(currency);
    }
    return 'Br';
  }
  String get formattedPrice => '${price.toStringAsFixed(0)} $displayCurrency';

  factory DeliveryItem.fromJson(
    Map<String, dynamic> json, {
    String defaultCategory = 'General',
    String? fallbackStoreId,
  }) {
    final itemId = json['id']?.toString() ?? json['item_id']?.toString() ?? '';
    final propId = json['property_id']?.toString() ?? json['storeId']?.toString() ?? fallbackStoreId ?? '';
    final itemName = json['item_name']?.toString() ?? json['name']?.toString() ?? '';
    final itemDesc = json['item_description']?.toString() ??
        json['desacriprion']?.toString() ??
        json['description']?.toString() ??
        '';
    final rawPrice = json['item_price'] ?? json['price'];
    final itemPrice = double.tryParse(rawPrice?.toString() ?? '0') ?? 0.0;
    final itemImage = json['item_image']?.toString() ?? json['imageUrl']?.toString() ?? json['image']?.toString() ?? '';
    final itemCat = json['menu_category']?.toString() ??
        json['category']?.toString() ??
        defaultCategory;

    final specialOffer = json['special_offer'] == '1' || json['special_offer'] == 1;
    final discount = double.tryParse(json['discount_percent']?.toString() ?? '0') ?? 0.0;

    final rawAddons = json['availableAddons'];
    final parsedAddons = rawAddons is List
        ? rawAddons
            .map((a) => CustomizationAddon.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList()
        : const <CustomizationAddon>[];
    final rawVariants = json['availableVariants'];
    final parsedVariants = rawVariants is List
        ? rawVariants.map((v) => v.toString()).toList()
        : const <String>[];
    final rawRemovals = json['removableOptions'];
    final parsedRemovals = rawRemovals is List
        ? rawRemovals.map((r) => r.toString()).toList()
        : const <String>[];

    final itemCurrency = json['currency']?.toString() ??
        json['currency_name']?.toString() ??
        json['currency_code']?.toString() ??
        json['currency_symbol']?.toString() ??
        json['currency_id']?.toString();

    return DeliveryItem(
      id: itemId,
      storeId: propId,
      name: itemName,
      description: itemDesc,
      price: itemPrice,
      imageUrl: itemImage,
      category: itemCat,
      unit: json['unit']?.toString() ?? 'each',
      variantTitle: json['variantTitle']?.toString(),
      availableVariants: parsedVariants,
      availableAddons: parsedAddons,
      removableOptions: parsedRemovals,
      isSpecialOffer: specialOffer,
      discountPercent: discount,
      currency: itemCurrency,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'storeId': storeId,
    'name': name,
    'description': description,
    'price': price,
    'imageUrl': imageUrl,
    'category': category,
    'unit': unit,
    'variantTitle': variantTitle,
    'availableVariants': availableVariants,
    'availableAddons': availableAddons.map((a) => a.toJson()).toList(),
    'removableOptions': removableOptions,
    'isSpecialOffer': isSpecialOffer,
    'discountPercent': discountPercent,
    'currency': currency,
  };

  // Backward-compatibility getters for existing code referencing FoodItem
  String get restaurantId => storeId;
  List<String> get availableTemperatures => availableVariants;
  List<String> get removableIngredients => removableOptions;
}

class CustomizationAddon {
  final String id;
  final String name;
  final double price;

  const CustomizationAddon({
    required this.id,
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
  };

  factory CustomizationAddon.fromJson(Map<String, dynamic> json) => CustomizationAddon(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
  );
}

// Backwards compatibility alias
typedef FoodItem = DeliveryItem;
