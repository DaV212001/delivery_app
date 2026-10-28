import '../config/storage_config.dart';
import 'multilingual_string.dart';

class MyPropertyModel {
  final int id;
  final String name;
  final String logo;
  final String coverImage;
  final String friendlyLocation;
  final String latitude;
  final String longitude;
  final String openingTime;
  final String closingTime;
  final String description;
  final String deliveryTime;
  final String status;
  final String typeName;
  final String categoryName;
  final String deliveryTypeImage;
  final String deliveryCategoryImage;
  final String currency;

  const MyPropertyModel({
    required this.id,
    required this.name,
    required this.logo,
    required this.coverImage,
    required this.friendlyLocation,
    required this.latitude,
    required this.longitude,
    required this.openingTime,
    required this.closingTime,
    required this.description,
    required this.deliveryTime,
    required this.status,
    required this.typeName,
    required this.categoryName,
    required this.deliveryTypeImage,
    required this.deliveryCategoryImage,
    this.currency = 'ETB',
  });

  /// Whether the property is active and approved on the platform.
  /// status == '0' indicates it is pending review / inactive.
  bool get isActive => status == '1' || status == 'active' || status == 'open';

  /// Whether the property is pending review by the platform team.
  bool get isUnderReview => !isActive;

  /// Checks if the property is open at a specific [DateTime] based on operating hours.
  bool isCurrentlyOpenAt(DateTime time) {
    if (openingTime.trim().isEmpty || closingTime.trim().isEmpty) return true;
    try {
      final currentMinutes = time.hour * 60 + time.minute;
      final openParts = openingTime.trim().split(':');
      final closeParts = closingTime.trim().split(':');
      if (openParts.length >= 2 && closeParts.length >= 2) {
        final openHour = int.tryParse(openParts[0]);
        final openMinute = int.tryParse(openParts[1]);
        final closeHour = int.tryParse(closeParts[0]);
        final closeMinute = int.tryParse(closeParts[1]);
        if (openHour != null && openMinute != null && closeHour != null && closeMinute != null) {
          final openMinutes = openHour * 60 + openMinute;
          final closeMinutes = closeHour * 60 + closeMinute;
          if (closeMinutes >= openMinutes) {
            // Same day operation e.g. 08:00 - 22:00
            return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
          } else {
            // Overnight operation e.g. 18:00 - 02:00
            return currentMinutes >= openMinutes || currentMinutes < closeMinutes;
          }
        }
      }
    } catch (_) {}
    return true;
  }

  /// Returns true if the property is currently within its opening and closing hours.
  bool get isOpen => isCurrentlyOpenAt(DateTime.now());

  factory MyPropertyModel.fromJson(Map<String, dynamic> json) {
    // Extract ID safely
    final rawId = json['id'];
    final parsedId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    // Names can be under property_name or name
    final pName = json['property_name']?.toString() ?? json['name']?.toString() ?? '';

    // Images
    final pLogo = json['property_logo']?.toString() ??
        json['logo']?.toString() ??
        json['logo_url']?.toString() ??
        '';
    final pCover = json['property_cover_image']?.toString() ??
        json['cover_image']?.toString() ??
        json['cover_image_url']?.toString() ??
        '';

    // Location
    final pLocation = json['property_frendly_location']?.toString() ??
        json['property_friendly_location']?.toString() ??
        json['frendly_location']?.toString() ??
        json['friendly_location']?.toString() ??
        '';

    // Coordinates
    final pLat = json['latitude']?.toString() ?? '9.0300';
    final pLng = json['longitude']?.toString() ?? '38.7400';

    // Times
    final pOpen = json['openning_tiem']?.toString() ??
        json['openning_time']?.toString() ??
        json['opening_time']?.toString() ??
        '08:00';
    final pClose = json['closing_time']?.toString() ?? '22:00';

    // Description & delivery time
    final pDesc = json['description']?.toString() ?? '';
    final pDelivTime = json['delviery_time']?.toString() ??
        json['delivery_time']?.toString() ??
        '30 min';

    // Status
    final pStatus = json['status']?.toString() ?? '1';

    // Type name
    String pType = '';
    if (json['type_name'] != null) {
      if (json['type_name'] is Map) {
        pType = MultiLangString.fromJson(json['type_name']).text;
      } else {
        pType = json['type_name'].toString();
      }
    }

    // Category name
    String pCat = '';
    if (json['categroy_name'] != null) {
      if (json['categroy_name'] is Map) {
        pCat = MultiLangString.fromJson(json['categroy_name']).text;
      } else {
        pCat = json['categroy_name'].toString();
      }
    } else if (json['category_name'] != null) {
      if (json['category_name'] is Map) {
        pCat = MultiLangString.fromJson(json['category_name']).text;
      } else {
        pCat = json['category_name'].toString();
      }
    }

    // Type and Category images
    final pTypeImg = json['delviery_type_image']?.toString() ??
        json['delivery_type_image']?.toString() ??
        '';
    final pCatImg = json['delviery_categroy_image']?.toString() ??
        json['delivery_category_image']?.toString() ??
        '';

    String pCurrency = 'ETB';
    final rawCurrency = json['currency'] ??
        json['currencies'] ??
        json['currency_name'] ??
        json['currency_code'] ??
        json['currency_symbol'] ??
        json['currency_id'] ??
        json['currencyId'];
    if (rawCurrency != null) {
      if (rawCurrency is Map) {
        final cVal = rawCurrency['code'] ??
            rawCurrency['currency_code'] ??
            rawCurrency['name'] ??
            rawCurrency['symbol'] ??
            rawCurrency['id'];
        if (cVal != null) {
          final s = cVal.toString().trim();
          if (s.isNotEmpty && s.toLowerCase() != 'null') {
            pCurrency = s;
          }
        }
      } else {
        final s = rawCurrency.toString().trim();
        if (s.isNotEmpty && s.toLowerCase() != 'null') {
          pCurrency = s;
        }
      }
    }

    // If the API payload returned null or default 'ETB', check local persistence
    if (parsedId > 0 && (pCurrency == 'ETB' || rawCurrency == null)) {
      final savedCode = ConfigPreference.getPropertyCurrency(parsedId);
      if (savedCode != null && savedCode.trim().isNotEmpty) {
        pCurrency = savedCode.trim();
      } else {
        final savedId = ConfigPreference.getPropertyCurrencyId(parsedId);
        if (savedId != null && savedId > 0) {
          pCurrency = savedId.toString();
        }
      }
    } else if (parsedId > 0 && pCurrency != 'ETB') {
      ConfigPreference.setPropertyCurrency(parsedId, pCurrency);
    }

    return MyPropertyModel(
      id: parsedId,
      name: pName,
      logo: pLogo,
      coverImage: pCover,
      friendlyLocation: pLocation,
      latitude: pLat,
      longitude: pLng,
      openingTime: pOpen,
      closingTime: pClose,
      description: pDesc,
      deliveryTime: pDelivTime,
      status: pStatus,
      typeName: pType,
      categoryName: pCat,
      deliveryTypeImage: pTypeImg,
      deliveryCategoryImage: pCatImg,
      currency: pCurrency,
    );
  }

  MyPropertyModel copyWith({
    int? id,
    String? name,
    String? logo,
    String? coverImage,
    String? friendlyLocation,
    String? latitude,
    String? longitude,
    String? openingTime,
    String? closingTime,
    String? description,
    String? deliveryTime,
    String? status,
    String? typeName,
    String? categoryName,
    String? deliveryTypeImage,
    String? deliveryCategoryImage,
    String? currency,
  }) {
    return MyPropertyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      coverImage: coverImage ?? this.coverImage,
      friendlyLocation: friendlyLocation ?? this.friendlyLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      description: description ?? this.description,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      status: status ?? this.status,
      typeName: typeName ?? this.typeName,
      categoryName: categoryName ?? this.categoryName,
      deliveryTypeImage: deliveryTypeImage ?? this.deliveryTypeImage,
      deliveryCategoryImage: deliveryCategoryImage ?? this.deliveryCategoryImage,
      currency: currency ?? this.currency,
    );
  }
}
