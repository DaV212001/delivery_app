import '../utils/currency_utils.dart';

class MyMenuItemModel {
  final int id;
  final dynamic propertyId;
  final dynamic menuCategoryId;
  final String name;
  final String description;
  final String image;
  final double price;
  final int status; // 1 = Active, 0 = Inactive
  final bool specialOffer;
  final double? discountPercent;
  final String? categoryName;
  final String? propertyName;
  final String? currency;

  const MyMenuItemModel({
    required this.id,
    required this.propertyId,
    required this.menuCategoryId,
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.status,
    required this.specialOffer,
    this.discountPercent,
    this.categoryName,
    this.propertyName,
    this.currency,
  });

  bool get isActive => status == 1;

  double get effectivePrice {
    if (specialOffer && discountPercent != null && discountPercent! > 0) {
      return price * (1 - (discountPercent! / 100));
    }
    return price;
  }

  String get displayCurrency {
    if (currency != null && currency!.trim().isNotEmpty) {
      return CurrencyUtils.resolveCode(currency);
    }
    return 'Br';
  }

  String get formattedPrice => '${price.toStringAsFixed(0)} $displayCurrency';
  String get formattedEffectivePrice => '${effectivePrice.toStringAsFixed(0)} $displayCurrency';

  factory MyMenuItemModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    final pId = json['property_id'];
    final catId = json['menu_categroy_id'] ?? json['menu_category_id'] ?? json['category_id'];

    final rawPrice = json['price'] ?? json['item_price'];
    final parsedPrice = double.tryParse(rawPrice?.toString().replaceAll(',', '') ?? '0') ?? 0.0;

    final rawStatus = json['status'];
    final parsedStatus = (rawStatus == 1 || rawStatus == '1' || rawStatus == true || rawStatus == 'active') ? 1 : 0;

    final rawSpecial = json['special_offer'];
    final isSpecial = rawSpecial == 1 || rawSpecial == '1' || rawSpecial == true;

    final rawDiscount = json['discount_percent'];
    final parsedDiscount = rawDiscount != null ? double.tryParse(rawDiscount.toString()) : null;

    final desc = json['desacriprion']?.toString() ??
        json['description']?.toString() ??
        '';

    final itemCurrency = json['currency']?.toString() ??
        json['currency_name']?.toString() ??
        json['currency_code']?.toString() ??
        json['currency_symbol']?.toString() ??
        json['currency_id']?.toString();

    return MyMenuItemModel(
      id: parsedId,
      propertyId: pId,
      menuCategoryId: catId,
      name: json['name']?.toString() ?? '',
      description: desc,
      image: json['image']?.toString() ?? '',
      price: parsedPrice,
      status: parsedStatus,
      specialOffer: isSpecial,
      discountPercent: parsedDiscount,
      categoryName: json['category_name']?.toString(),
      propertyName: json['property_name']?.toString(),
      currency: itemCurrency,
    );
  }

  MyMenuItemModel copyWith({
    int? id,
    dynamic propertyId,
    dynamic menuCategoryId,
    String? name,
    String? description,
    String? image,
    double? price,
    int? status,
    bool? specialOffer,
    double? discountPercent,
    String? categoryName,
    String? propertyName,
    String? currency,
  }) {
    return MyMenuItemModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      menuCategoryId: menuCategoryId ?? this.menuCategoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      price: price ?? this.price,
      status: status ?? this.status,
      specialOffer: specialOffer ?? this.specialOffer,
      discountPercent: discountPercent ?? this.discountPercent,
      categoryName: categoryName ?? this.categoryName,
      propertyName: propertyName ?? this.propertyName,
      currency: currency ?? this.currency,
    );
  }
}
