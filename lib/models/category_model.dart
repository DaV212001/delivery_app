import 'multilingual_string.dart';

class CategoryModel {
  final int id;
  final MultiLangString name;
  final String image;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.image,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] ??
        json['category_name'] ??
        json['categroy_name'] ??
        json['type_name'];
    final rawImage = json['image'] ??
        json['imageUrl'] ??
        json['category_image'] ??
        json['categroy_image'] ??
        json['delviery_categroy_image'] ??
        json['delviery_type_image'] ??
        json['category_icon'] ??
        json['icon_url'] ??
        json['icon'];

    final imgStr = rawImage?.toString().trim() ?? '';
    final cleanImage = (imgStr == 'null' || imgStr == 'undefined') ? '' : imgStr;

    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: MultiLangString.fromJson(rawName),
      image: cleanImage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name.toJson(),
        'image': image,
      };

  String get displayName => name.text;
}

class PromotionalBannerModel {
  final int id;
  final String image;
  final int propertyId;
  final String propertyName;
  final MultiLangString name;

  const PromotionalBannerModel({
    required this.id,
    required this.image,
    required this.propertyId,
    required this.propertyName,
    required this.name,
  });

  factory PromotionalBannerModel.fromJson(Map<String, dynamic> json) {
    return PromotionalBannerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      image: json['image']?.toString() ?? '',
      propertyId: json['property_id'] is int
          ? json['property_id']
          : int.tryParse(json['property_id']?.toString() ?? '0') ?? 0,
      propertyName: json['property_name']?.toString() ?? '',
      name: MultiLangString.fromJson(json['name']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'image': image,
        'property_id': propertyId,
        'property_name': propertyName,
        'name': name.toJson(),
      };
}
