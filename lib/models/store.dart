import 'package:get/get.dart';
import '../utils/currency_utils.dart';
import '../utils/location_utils.dart';
import 'delivery_item.dart';
import 'multilingual_string.dart';
import 'today_schedule.dart';

enum StoreType {
  grocery,
  electronics,
  pharmacy,
  flowers,
  restaurant,
  courier,
  corporate,
  retail,
}

class Store {
  final String id;
  final String name;
  final String categoryDescription; // e.g. "Bar and Restaurant", "Habesha Food"
  final StoreType type;
  final String priceLevel; // $, $$, $$$
  final double rating;
  final int reviewsCount;
  final String deliveryTime; // e.g. "30 min"
  final String deliveryFee; // e.g. "Free delivery" or "132 Br"
  final double minOrder;
  final double distanceKm;
  final String heroImageUrl;
  final String? logoUrl;
  final bool isFeatured;
  final String? badge; // e.g. "Editor's Pick", "Top Rated", "Fastest Delivery"
  final String? branch; // e.g. "summit around birhanu hotel"
  final double? avgPricePerPerson; // In Br, e.g. 778.0
  final double? deliveryFeeAmount; // In Br, e.g. 132.0
  final double? latitude;
  final double? longitude;
  final String? openingTime;
  final String? closingTime;
  final TodaySchedule? todaySchedule;
  final List<String> categories;
  final List<DeliveryItem> items;
  final String? currency;

  const Store({
    required this.id,
    required this.name,
    required this.categoryDescription,
    this.type = StoreType.retail,
    required this.priceLevel,
    required this.rating,
    required this.reviewsCount,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.minOrder,
    required this.distanceKm,
    required this.heroImageUrl,
    this.logoUrl,
    this.isFeatured = false,
    this.badge,
    this.branch,
    this.avgPricePerPerson,
    this.deliveryFeeAmount,
    this.latitude,
    this.longitude,
    this.openingTime,
    this.closingTime,
    this.todaySchedule,
    this.categories = const [],
    this.items = const [],
    this.currency,
  });

  String get displayCurrency => CurrencyUtils.resolveCode(currency);

  factory Store.fromJson(Map<String, dynamic> json, {List<DeliveryItem> items = const []}) {
    // Determine category / cuisine name
    String catDesc = 'General Store';
    if (json['categroy_name'] != null) {
      catDesc = MultiLangString.fromJson(json['categroy_name']).text;
    } else if (json['category_name'] != null) {
      catDesc = MultiLangString.fromJson(json['category_name']).text;
    } else if (json['type_name'] != null) {
      catDesc = MultiLangString.fromJson(json['type_name']).text;
    } else if (json['description'] != null) {
      catDesc = json['description'].toString();
    }

    // Determine type
    final lowerCat = catDesc.toLowerCase();
    StoreType detectedType = StoreType.restaurant;
    if (lowerCat.contains('grocery') || lowerCat.contains('market')) {
      detectedType = StoreType.grocery;
    } else if (lowerCat.contains('electronic') || lowerCat.contains('mobile')) {
      detectedType = StoreType.electronics;
    } else if (lowerCat.contains('pharmacy')) {
      detectedType = StoreType.pharmacy;
    } else if (lowerCat.contains('flower')) {
      detectedType = StoreType.flowers;
    } else if (lowerCat.contains('courier')) {
      detectedType = StoreType.courier;
    }

    final coverImage = json['property_cover_image']?.toString() ??
        json['cover_image']?.toString() ??
        json['heroImageUrl']?.toString() ??
        '';
    final logoImage = json['property_logo']?.toString() ??
        json['logo']?.toString() ??
        '';

    final friendlyLoc = json['property_frendly_location']?.toString() ??
        json['property_friendly_location']?.toString() ??
        json['location']?.toString() ??
        '';

    final delTime = json['delviery_time']?.toString() ??
        json['delivery_time']?.toString() ??
        '25-35 min';

    final lat = double.tryParse(json['latitude']?.toString() ?? '');
    final lng = double.tryParse(json['longitude']?.toString() ?? '');

    final rawMinOrder = json['min_order'] ?? json['minimum_order'] ?? json['min_price'];
    double minOrderValue = double.tryParse(rawMinOrder?.toString() ?? '') ?? 0.0;
    if (minOrderValue <= 0 && items.isNotEmpty) {
      final validPrices = items.map((i) => i.price).where((p) => p > 0);
      if (validPrices.isNotEmpty) {
        minOrderValue = validPrices.reduce((a, b) => a < b ? a : b);
      }
    }
    if (minOrderValue <= 0) {
      minOrderValue = 100.0;
    }

    double initialDistance = 2.5;
    if (lat != null && lng != null) {
      initialDistance = LocationUtils.calculateDistanceInKm(
        lat1: LocationUtils.defaultLatitude,
        lon1: LocationUtils.defaultLongitude,
        lat2: lat,
        lon2: lng,
      );
    }

    final todaySched = json['today_schedule'] != null
        ? TodaySchedule.fromJson(json['today_schedule'])
        : null;

    final rawCurrency = json['currency']?.toString() ??
        json['currency_code']?.toString() ??
        json['currency_name']?.toString() ??
        json['currency_symbol']?.toString() ??
        json['currency_id']?.toString() ??
        (json['currencies'] is Map ? json['currencies']['code']?.toString() : null);

    return Store(
      id: json['id']?.toString() ?? '',
      name: json['property_name']?.toString() ?? json['name']?.toString() ?? 'Store',
      categoryDescription: catDesc,
      type: detectedType,
      priceLevel: '\$\$',
      rating: double.tryParse(json['rating']?.toString() ?? '4.8') ?? 4.8,
      reviewsCount: int.tryParse(json['reviews_count']?.toString() ?? '120') ?? 120,
      deliveryTime: delTime,
      deliveryFee: 'Free delivery',
      minOrder: minOrderValue,
      distanceKm: initialDistance,
      heroImageUrl: coverImage.isNotEmpty ? coverImage : logoImage,
      logoUrl: logoImage,
      isFeatured: true,
      badge: json['badge']?.toString() ?? 'Top Rated',
      branch: friendlyLoc.isNotEmpty ? friendlyLoc : null,
      avgPricePerPerson: 350.0,
      deliveryFeeAmount: 50.0,
      latitude: lat,
      longitude: lng,
      openingTime: json['openning_tiem']?.toString() ?? json['opening_time']?.toString(),
      closingTime: json['closing_time']?.toString(),
      todaySchedule: todaySched,
      categories: [catDesc],
      items: items,
      currency: rawCurrency,
    );
  }

  Store copyWith({
    String? id,
    String? name,
    String? categoryDescription,
    StoreType? type,
    String? priceLevel,
    double? rating,
    int? reviewsCount,
    String? deliveryTime,
    String? deliveryFee,
    double? minOrder,
    double? distanceKm,
    String? heroImageUrl,
    String? logoUrl,
    bool? isFeatured,
    String? badge,
    String? branch,
    double? avgPricePerPerson,
    double? deliveryFeeAmount,
    double? latitude,
    double? longitude,
    String? openingTime,
    String? closingTime,
    TodaySchedule? todaySchedule,
    List<String>? categories,
    List<DeliveryItem>? items,
    String? currency,
  }) {
    final newItems = items ?? this.items;
    double? newMinOrder = minOrder;
    if (newMinOrder == null && items != null && items.isNotEmpty) {
      final validPrices = items.map((i) => i.price).where((p) => p > 0);
      if (validPrices.isNotEmpty) {
        newMinOrder = validPrices.reduce((a, b) => a < b ? a : b);
      }
    }
    newMinOrder ??= this.minOrder;

    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryDescription: categoryDescription ?? this.categoryDescription,
      type: type ?? this.type,
      priceLevel: priceLevel ?? this.priceLevel,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minOrder: newMinOrder,
      distanceKm: distanceKm ?? this.distanceKm,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      badge: badge ?? this.badge,
      branch: branch ?? this.branch,
      avgPricePerPerson: avgPricePerPerson ?? this.avgPricePerPerson,
      deliveryFeeAmount: deliveryFeeAmount ?? this.deliveryFeeAmount,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      todaySchedule: todaySchedule ?? this.todaySchedule,
      categories: categories ?? this.categories,
      items: newItems,
      currency: currency ?? this.currency,
    );
  }

  // Backward compatibility getters for existing code referencing Restaurant
  String get cuisine => categoryDescription;
  List<DeliveryItem> get menuItems => items;

  // Dynamic minimum order price based on actual items
  double get effectiveMinOrder {
    if (items.isNotEmpty) {
      final validPrices = items.map((i) => i.price).where((p) => p > 0);
      if (validPrices.isNotEmpty) {
        return validPrices.reduce((a, b) => a < b ? a : b);
      }
    }
    return minOrder;
  }

  String get formattedMinOrder {
    final price = effectiveMinOrder;
    if (price <= 0) return '0 Br';
    if (price % 1 == 0) {
      return '${price.toInt()} Br';
    }
    return '${price.toStringAsFixed(1)} Br';
  }

  // Localized Ethiopian UI getters
  String get displayNameWithBranch =>
      (branch != null && branch!.isNotEmpty) ? '$name | $branch' : name;

  String? get friendlyLocation => branch;

  /// Calculate distance between this store and user coordinates
  double? calculateDistanceTo({double? userLat, double? userLng}) {
    if (latitude == null || longitude == null) return null;
    if (userLat == null || userLng == null) return null;
    return LocationUtils.calculateDistanceInKm(
      lat1: userLat,
      lon1: userLng,
      lat2: latitude!,
      lon2: longitude!,
    );
  }

  /// Formatted dynamic distance badge e.g. "Around 1.2km"
  String formattedDistanceBadgeTo({double? userLat, double? userLng}) {
    final dist = calculateDistanceTo(userLat: userLat, userLng: userLng);
    if (dist == null) return formattedDistanceBadge;
    return LocationUtils.formatDistanceBadge(dist);
  }

  String get formattedDistanceBadge {
    final km = distanceKm < 1 ? '1' : distanceKm.toStringAsFixed(0);
    return '${'around'.tr} ${km}KM';
  }

  String get formattedTimeBadge {
    final cleanTime = deliveryTime.replaceAll(' min', '').replaceAll('min', '').trim();
    return '${'around'.tr} $cleanTime ${'min'.tr}';
  }

  /// Formatted operating hours e.g. "8:00 AM - 10:00 PM"
  String get formattedOperatingHours {
    if (openingTime == null && closingTime == null) return '';
    final open = _formatTime(openingTime);
    final close = _formatTime(closingTime);
    if (open.isNotEmpty && close.isNotEmpty) {
      return '$open - $close';
    }
    return open.isNotEmpty ? open : close;
  }

  /// Returns true if the store is currently closed (past closing time, before opening time, or scheduled closed)
  bool get isPastClosingTime {
    if (todaySchedule != null) {
      return !todaySchedule!.isOpenNow;
    }
    if (closingTime == null || closingTime!.trim().isEmpty) return false;
    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;

      final closeParts = closingTime!.trim().split(':');
      if (closeParts.length >= 2) {
        final closeHour = int.tryParse(closeParts[0]);
        final closeMinute = int.tryParse(closeParts[1]);
        if (closeHour == null || closeMinute == null) return false;
        final closeMinutes = closeHour * 60 + closeMinute;

        if (openingTime != null && openingTime!.trim().isNotEmpty) {
          final openParts = openingTime!.trim().split(':');
          if (openParts.length >= 2) {
            final openHour = int.tryParse(openParts[0]);
            final openMinute = int.tryParse(openParts[1]);
            if (openHour != null && openMinute != null) {
              final openMinutes = openHour * 60 + openMinute;
              if (closeMinutes >= openMinutes) {
                // Same day operation e.g. 08:00 - 22:00
                return currentMinutes < openMinutes || currentMinutes >= closeMinutes;
              } else {
                // Overnight operation e.g. 18:00 - 02:00
                return currentMinutes < openMinutes && currentMinutes >= closeMinutes;
              }
            }
          }
        }

        return currentMinutes >= closeMinutes;
      }
    } catch (_) {}
    return false;
  }

  bool get isOpen => !isPastClosingTime;
  bool get isCurrentlyOpen => isOpen;

  /// User friendly schedule status message
  String get openStatusText {
    if (todaySchedule != null) {
      return todaySchedule!.statusMessage;
    }
    if (isPastClosingTime) {
      final open = _formatTime(openingTime);
      return open.isNotEmpty
          ? '${'store_closed_opens_at'.tr} $open'
          : 'store_currently_closed'.tr;
    }
    final close = _formatTime(closingTime);
    return close.isNotEmpty
        ? '${'open_until'.tr} $close'
        : 'store_open'.tr;
  }

  /// Calculates next DateTime when store opens
  DateTime get nextOpenDateTime {
    if (todaySchedule != null) {
      return todaySchedule!.nextOpenDateTime;
    }
    final now = DateTime.now();
    int openHour = 8;
    int openMinute = 30;
    if (openingTime != null && openingTime!.trim().isNotEmpty) {
      final parts = openingTime!.trim().split(':');
      if (parts.length >= 2) {
        openHour = int.tryParse(parts[0]) ?? 8;
        openMinute = int.tryParse(parts[1]) ?? 30;
      }
    }
    final todayOpen = DateTime(now.year, now.month, now.day, openHour, openMinute);
    if (now.isBefore(todayOpen)) return todayOpen;
    return todayOpen.add(const Duration(days: 1));
  }

  /// Formatted next open time string e.g. "08:30 AM"
  String get formattedNextOpenTime {
    if (todaySchedule != null && todaySchedule!.formattedOpenTime != null) {
      return todaySchedule!.formattedOpenTime!;
    }
    final open = _formatTime(openingTime);
    return open.isNotEmpty ? open : '08:30 AM';
  }

  static String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return '';
    final parts = timeStr.trim().split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        final period = hour >= 12 ? 'PM' : 'AM';
        final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final m = minute.toString().padLeft(2, '0');
        return '$h:$m $period';
      }
    }
    return timeStr;
  }

  String get formattedAvgPrice {
    final price = avgPricePerPerson?.toInt() ?? 350;
    return '${'avg'.tr} $price Br ${'per_person'.tr}';
  }

  String get formattedDeliveryFeeText {
    final fee = deliveryFeeAmount?.toInt() ?? 50;
    return '${'delivery_fee_starting_from'.tr} $fee Br';
  }
}

// Backwards compatibility alias
typedef Restaurant = Store;
