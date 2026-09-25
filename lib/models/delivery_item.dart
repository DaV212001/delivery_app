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
  });

  factory DeliveryItem.fromJson(
    Map<String, dynamic> json, {
    String defaultCategory = 'General',
    String? fallbackStoreId,
  }) {
    final itemId = json['id']?.toString() ?? json['item_id']?.toString() ?? '';
    final propId = json['property_id']?.toString() ?? fallbackStoreId ?? '';
    final itemName = json['item_name']?.toString() ?? json['name']?.toString() ?? '';
    final itemDesc = json['item_description']?.toString() ??
        json['desacriprion']?.toString() ??
        json['description']?.toString() ??
        '';
    final rawPrice = json['item_price'] ?? json['price'];
    final itemPrice = double.tryParse(rawPrice?.toString() ?? '0') ?? 0.0;
    final itemImage = json['item_image']?.toString() ?? json['image']?.toString() ?? '';
    final itemCat = json['menu_category']?.toString() ??
        json['category']?.toString() ??
        defaultCategory;

    final specialOffer = json['special_offer'] == '1' || json['special_offer'] == 1;
    final discount = double.tryParse(json['discount_percent']?.toString() ?? '0') ?? 0.0;

    return DeliveryItem(
      id: itemId,
      storeId: propId,
      name: itemName,
      description: itemDesc,
      price: itemPrice,
      imageUrl: itemImage,
      category: itemCat,
      isSpecialOffer: specialOffer,
      discountPercent: discount,
    );
  }

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
}

// Backwards compatibility alias
typedef FoodItem = DeliveryItem;
