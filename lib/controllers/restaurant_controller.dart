import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/dio_config.dart';
import '../data/mock_data.dart';
import '../models/category_model.dart';
import '../models/delivery_item.dart';
import '../models/promotion.dart';
import '../models/special_offer.dart';
import '../models/store.dart';
import '../services/property_service.dart';
import '../utils/api_call_status.dart';
import 'profile_controller.dart';

class RestaurantController extends GetxController {
  final status = ApiCallStatus.success.obs;
  final restaurants = <Store>[].obs;
  final promotions = <Promotion>[].obs;
  final specialOffers = <SpecialOffer>[].obs;
  final circularCategories = <CircularCategory>[].obs;
  final selectedCircularCategory = ''.obs;
  final favorites = <String>{'store_techhub', 'store_freshmart'}.obs;

  final selectedCategory = 'All'.obs;
  final searchQuery = ''.obs;

  // Search & Sorting Filters
  final filterRating45 = false.obs;
  final filterUnder30Min = false.obs;
  final filterOffers = false.obs;
  final sortBy = 'recommended'.obs; // 'recommended', 'rating', 'fastest', 'price'

  final categories = [
    'All',
    'Groceries',
    'Electronics',
    'Pharmacy',
    'Food',
    'Flowers',
    'Courier',
  ];

  @override
  void onInit() {
    super.onInit();
    if (DioConfig.isTestMode) {
      restaurants.assignAll(MockData.restaurants);
      promotions.assignAll(MockData.promotions);
      specialOffers.assignAll(MockData.specialOffers);
      circularCategories.assignAll(MockData.circularCategories);
    } else {
      loadRestaurants();
    }
  }

  Future<void> loadRestaurants() async {
    status.value = ApiCallStatus.loading;

    try {
      // Fetch in parallel from live APIs
      final results = await Future.wait([
        PropertyService.fetchCategories(),
        PropertyService.fetchPromotionalBanners(),
        PropertyService.fetchSpecialOffers(),
        PropertyService.fetchProperties(),
        PropertyService.fetchFeaturedStores(),
      ]);

      final apiCategories = results[0] as List<CategoryModel>;
      final apiBanners = results[1] as List<PromotionalBannerModel>;
      final apiOffers = results[2] as List<DeliveryItem>;
      final apiProperties = results[3] as List<Store>;
      final apiFeatured = results[4] as List<Store>;

      // 1. Categories
      if (apiCategories.isNotEmpty) {
        final colors = [
          const Color(0xFFFEE2E2),
          const Color(0xFFFEF3C7),
          const Color(0xFFE0E7FF),
          const Color(0xFFDCFCE7),
          const Color(0xFFF3E8FF),
          const Color(0xFFFFEDD5),
        ];
        final iconColors = [
          const Color(0xFFDC2626),
          const Color(0xFFD97706),
          const Color(0xFF4F46E5),
          const Color(0xFF16A34A),
          const Color(0xFF9333EA),
          const Color(0xFFEA580C),
        ];
        final mappedCats = apiCategories.asMap().entries.map((entry) {
          final idx = entry.key;
          final cat = entry.value;
          return CircularCategory(
            id: cat.id.toString(),
            name: cat.displayName,
            categoryKey: cat.displayName,
            imageUrl: cat.image,
            icon: _getCategoryFallbackIcon(cat.displayName),
            backgroundColor: colors[idx % colors.length],
            iconColor: iconColors[idx % iconColors.length],
          );
        }).toList();
        circularCategories.assignAll(mappedCats);
      } else if (DioConfig.isTestMode) {
        circularCategories.assignAll(MockData.circularCategories);
      } else {
        circularCategories.clear();
      }

      // 2. Promotional Banners
      if (apiBanners.isNotEmpty) {
        final mappedPromos = apiBanners.map((b) {
          return Promotion(
            id: b.id.toString(),
            title: b.name.text,
            subtitle: b.propertyName,
            imageUrl: b.image,
            storeId: b.propertyId.toString(),
          );
        }).toList();
        promotions.assignAll(mappedPromos);
      } else if (DioConfig.isTestMode) {
        promotions.assignAll(MockData.promotions);
      } else {
        promotions.clear();
      }

      // 3. Special Offers
      if (apiOffers.isNotEmpty) {
        final mappedOffers = apiOffers.map((item) {
          final discount = item.discountPercent > 0 ? item.discountPercent : 20.0;
          final orig = item.price / (1 - (discount / 100));
          return SpecialOffer(
            id: item.id,
            name: item.name,
            storeName: 'AMN Restaurant',
            branchName: 'Summit',
            discountedPrice: item.price,
            originalPrice: orig,
            discountPercent: discount,
            imageUrl: item.imageUrl,
            storeId: item.storeId.isNotEmpty ? item.storeId : '1',
          );
        }).toList();
        specialOffers.assignAll(mappedOffers);
      } else if (DioConfig.isTestMode) {
        specialOffers.assignAll(MockData.specialOffers);
      } else {
        specialOffers.clear();
      }

      // 4. Properties / Stores
      final combinedStores = <Store>[];
      final seenIds = <String>{};

      for (final s in [...apiFeatured, ...apiProperties]) {
        if (!seenIds.contains(s.id)) {
          seenIds.add(s.id);
          combinedStores.add(s);
        }
      }

      if (combinedStores.isNotEmpty) {
        restaurants.assignAll(combinedStores);
      } else if (DioConfig.isTestMode) {
        restaurants.assignAll(MockData.restaurants);
      } else {
        restaurants.clear();
      }

      if (combinedStores.isEmpty && apiOffers.isEmpty && apiCategories.isEmpty && !DioConfig.isTestMode) {
        status.value = ApiCallStatus.empty;
      } else {
        status.value = ApiCallStatus.success;
      }
    } catch (_) {
      if (DioConfig.isTestMode) {
        restaurants.assignAll(MockData.restaurants);
        promotions.assignAll(MockData.promotions);
        specialOffers.assignAll(MockData.specialOffers);
        circularCategories.assignAll(MockData.circularCategories);
        status.value = ApiCallStatus.success;
      } else {
        status.value = ApiCallStatus.error;
      }
    }
  }

  void selectCircularCategory(CircularCategory category) {
    if (selectedCircularCategory.value == category.categoryKey) {
      selectedCircularCategory.value = '';
    } else {
      selectedCircularCategory.value = category.categoryKey;
    }
  }

  List<Store> get filteredRestaurants {
    final list = restaurants.where((r) {
      if (selectedCategory.value != 'All') {
        final cat = selectedCategory.value.toLowerCase();
        final matchesCuisine = r.categoryDescription.toLowerCase().contains(cat);
        final matchesCatList = r.categories.any((c) => c.toLowerCase() == cat);
        final matchesType = (cat == 'groceries' && r.type == StoreType.grocery) ||
            (cat == 'electronics' && r.type == StoreType.electronics) ||
            (cat == 'pharmacy' && r.type == StoreType.pharmacy) ||
            (cat == 'food' && r.type == StoreType.restaurant) ||
            (cat == 'flowers' && r.type == StoreType.flowers) ||
            (cat == 'courier' && r.type == StoreType.courier);
        if (!matchesCuisine && !matchesCatList && !matchesType) {
          return false;
        }
      }
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        final matchesName = r.name.toLowerCase().contains(query);
        final matchesCuisine = r.categoryDescription.toLowerCase().contains(query);
        final matchesItem = r.items.any((item) =>
            item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query));
        if (!matchesName && !matchesCuisine && !matchesItem) return false;
      }
      if (filterRating45.value && r.rating < 4.5) return false;
      if (filterUnder30Min.value) {
        final isFast = r.deliveryTime.contains('10') ||
            r.deliveryTime.contains('15') ||
            r.deliveryTime.contains('20') ||
            r.deliveryTime.contains('25') ||
            r.deliveryTime.contains('30');
        if (!isFast) return false;
      }
      if (filterOffers.value && !r.deliveryFee.toLowerCase().contains('free')) {
        return false;
      }
      return true;
    }).toList();

    if (sortBy.value == 'rating') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (sortBy.value == 'fastest') {
      final profileController = Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>()
          : null;
      final uLat = profileController?.activeLatitude;
      final uLng = profileController?.activeLongitude;
      list.sort((a, b) {
        final distA = a.calculateDistanceTo(userLat: uLat, userLng: uLng) ?? a.distanceKm;
        final distB = b.calculateDistanceTo(userLat: uLat, userLng: uLng) ?? b.distanceKm;
        return distA.compareTo(distB);
      });
    } else if (sortBy.value == 'price') {
      list.sort((a, b) => (a.avgPricePerPerson ?? 0).compareTo(b.avgPricePerPerson ?? 0));
    }

    return list;
  }

  void toggleFavorite(String restaurantId) {
    if (favorites.contains(restaurantId)) {
      favorites.remove(restaurantId);
    } else {
      favorites.add(restaurantId);
    }
  }

  bool isFavorite(String restaurantId) => favorites.contains(restaurantId);

  Store? getRestaurantById(String id) {
    try {
      return restaurants.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Store?> fetchLiveStoreDetail(String id) async {
    final detail = await PropertyService.fetchPropertyDetail(id);
    if (detail != null) {
      final index = restaurants.indexWhere((r) => r.id == id);
      if (index >= 0) {
        restaurants[index] = detail;
        restaurants.refresh();
      } else {
        restaurants.add(detail);
      }
      return detail;
    }
    return getRestaurantById(id);
  }

  List<Store> getStoresForCategory(String categoryKey, {String query = ''}) {
    final cKey = categoryKey.toLowerCase();
    final list = restaurants.where((r) {
      final matchesCuisine = r.categoryDescription.toLowerCase().contains(cKey);
      final matchesCatList = r.categories.any((c) => c.toLowerCase().contains(cKey));
      final matchesName = r.name.toLowerCase().contains(cKey);
      final matchesType = (cKey.contains('grocery') && r.type == StoreType.grocery) ||
          (cKey.contains('electronic') && r.type == StoreType.electronics) ||
          (cKey.contains('pharmacy') && r.type == StoreType.pharmacy) ||
          (cKey.contains('restaurant') && r.type == StoreType.restaurant) ||
          (cKey.contains('burger') && (r.categoryDescription.toLowerCase().contains('burger') || r.type == StoreType.restaurant)) ||
          (cKey.contains('fasting') && (r.categoryDescription.toLowerCase().contains('asian') || r.type == StoreType.grocery)) ||
          (cKey.contains('courier') && r.type == StoreType.courier);

      if (!matchesCuisine && !matchesCatList && !matchesName && !matchesType) {
        return false;
      }

      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final matchQName = r.name.toLowerCase().contains(q);
        final matchQCuisine = r.categoryDescription.toLowerCase().contains(q);
        final matchQItems = r.items.any((item) =>
            item.name.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q));
        if (!matchQName && !matchQCuisine && !matchQItems) return false;
      }

      if (filterRating45.value && r.rating < 4.5) return false;
      if (filterUnder30Min.value) {
        final isFast = r.deliveryTime.contains('10') ||
            r.deliveryTime.contains('15') ||
            r.deliveryTime.contains('20') ||
            r.deliveryTime.contains('25') ||
            r.deliveryTime.contains('30');
        if (!isFast) return false;
      }
      if (filterOffers.value && !r.deliveryFee.toLowerCase().contains('free')) {
        return false;
      }

      return true;
    }).toList();

    if (sortBy.value == 'rating') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (sortBy.value == 'fastest') {
      final profileController = Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>()
          : null;
      final uLat = profileController?.activeLatitude;
      final uLng = profileController?.activeLongitude;
      list.sort((a, b) {
        final distA = a.calculateDistanceTo(userLat: uLat, userLng: uLng) ?? a.distanceKm;
        final distB = b.calculateDistanceTo(userLat: uLat, userLng: uLng) ?? b.distanceKm;
        return distA.compareTo(distB);
      });
    } else if (sortBy.value == 'price') {
      list.sort((a, b) => (a.avgPricePerPerson ?? 0).compareTo(b.avgPricePerPerson ?? 0));
    }

    return list;
  }

  static IconData _getCategoryFallbackIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('restaurant') || n.contains('food') || n.contains('bar')) {
      return Icons.restaurant_rounded;
    }
    if (n.contains('pharmacy') || n.contains('drug') || n.contains('health')) {
      return Icons.local_pharmacy_rounded;
    }
    if (n.contains('market') || n.contains('grocer')) {
      return Icons.shopping_basket_rounded;
    }
    if (n.contains('cloth') || n.contains('shoe') || n.contains('wear') || n.contains('fashion')) {
      return Icons.checkroom_rounded;
    }
    if (n.contains('mobile') || n.contains('phone')) {
      return Icons.phone_iphone_rounded;
    }
    if (n.contains('electron')) {
      return Icons.devices_rounded;
    }
    if (n.contains('motorcycle') || n.contains('bike')) {
      return Icons.two_wheeler_rounded;
    }
    if (n.contains('car') ||
        n.contains('spare') ||
        n.contains('tyre') ||
        n.contains('tractor') ||
        n.contains('machin')) {
      return Icons.directions_car_rounded;
    }
    if (n.contains('flower') || n.contains('gift')) {
      return Icons.local_florist_rounded;
    }
    if (n.contains('post') || n.contains('courier') || n.contains('deliver')) {
      return Icons.local_shipping_rounded;
    }
    return Icons.category_rounded;
  }
}

// Backwards compatibility alias
typedef StoreController = RestaurantController;
