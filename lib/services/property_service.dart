import '../constants/api_endpoints.dart';
import '../models/category_model.dart';
import '../models/delivery_item.dart';
import '../models/store.dart';
import '../utils/templates/dio_template.dart';

class PropertyService {
  /// Fetch all delivery categories
  static Future<List<CategoryModel>> fetchCategories() async {
    final list = <CategoryModel>[];
    await DioService.dioGet(
      path: ApiEndpoints.categories,
      onSuccess: (response) {
        final resData = response.data;
        final rawList = resData is Map<String, dynamic>
            ? (resData['data'] is List
                ? resData['data']
                : (resData['categories'] is List ? resData['categories'] : null))
            : (resData is List ? resData : null);

        if (rawList is List) {
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              list.add(CategoryModel.fromJson(item));
            }
          }
        }
      },
    );
    if (list.isEmpty) {
      return await fetchDeliveryTypes();
    }
    return list;
  }

  /// Fetch all delivery types
  static Future<List<CategoryModel>> fetchDeliveryTypes() async {
    final list = <CategoryModel>[];
    await DioService.dioGet(
      path: ApiEndpoints.deliveryTypes,
      onSuccess: (response) {
        final resData = response.data;
        final rawList = resData is Map<String, dynamic>
            ? (resData['data'] is List
                ? resData['data']
                : (resData['delivery_types'] is List ? resData['delivery_types'] : null))
            : (resData is List ? resData : null);

        if (rawList is List) {
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              list.add(CategoryModel.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Fetch stores by category ID
  static Future<List<Store>> fetchStoresByCategory(dynamic categoryId) async {
    final list = <Store>[];
    await DioService.dioGet(
      path: ApiEndpoints.categoryStores(categoryId),
      onSuccess: (response) {
        final resData = response.data;
        final rawList = resData is Map<String, dynamic>
            ? (resData['data'] is List ? resData['data'] : null)
            : (resData is List ? resData : null);

        if (rawList is List) {
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              list.add(Store.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Fetch stores by delivery type ID
  static Future<List<Store>> fetchStoresByDeliveryType(dynamic typeId) async {
    final list = <Store>[];
    await DioService.dioGet(
      path: ApiEndpoints.deliveryTypeStores(typeId),
      onSuccess: (response) {
        final resData = response.data;
        final rawList = resData is Map<String, dynamic>
            ? (resData['data'] is List ? resData['data'] : null)
            : (resData is List ? resData : null);

        if (rawList is List) {
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              list.add(Store.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Fetch promotional banners
  static Future<List<PromotionalBannerModel>> fetchPromotionalBanners() async {
    final list = <PromotionalBannerModel>[];
    await DioService.dioGet(
      path: ApiEndpoints.promotionalImages,
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(PromotionalBannerModel.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Fetch special offers
  static Future<List<DeliveryItem>> fetchSpecialOffers() async {
    final list = <DeliveryItem>[];
    await DioService.dioGet(
      path: ApiEndpoints.specialOffers,
      onSuccess: (response) {
        final resData = response.data;
        final rawList = resData is Map<String, dynamic>
            ? (resData['data'] is List
                ? resData['data']
                : (resData['special_offers'] is List
                    ? resData['special_offers']
                    : (resData['menus'] is List ? resData['menus'] : null)))
            : (resData is List ? resData : null);

        if (rawList is List) {
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              list.add(DeliveryItem.fromJson(item, defaultCategory: 'Special Offer'));
            }
          }
        }
      },
    );
    return list;
  }

  /// Fetch featured stores
  static Future<List<Store>> fetchFeaturedStores() async {
    final list = <Store>[];
    await DioService.dioGet(
      path: ApiEndpoints.featureStores,
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(Store.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Fetch all properties / stores
  static Future<List<Store>> fetchProperties() async {
    final list = <Store>[];
    await DioService.dioGet(
      path: ApiEndpoints.properties,
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(Store.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Fetch single property detail with menus and menu categories
  static Future<Store?> fetchPropertyDetail(dynamic propertyId) async {
    Store? store;
    await DioService.dioGet(
      path: ApiEndpoints.propertyDetail(propertyId),
      onSuccess: (response) {
        final resData = response.data;
        if (resData is Map<String, dynamic> && resData['data'] is Map<String, dynamic>) {
          final data = resData['data'] as Map<String, dynamic>;
          final propJson = data['property'] is Map<String, dynamic>
              ? data['property'] as Map<String, dynamic>
              : <String, dynamic>{};

          final categories = <String>[];
          final categoryMap = <String, String>{};
          if (data['menu_categories'] is List) {
            for (final mc in data['menu_categories']) {
              if (mc is Map && mc['name'] != null) {
                final name = mc['name'].toString().trim();
                if (name.isNotEmpty && !categories.contains(name)) {
                  categories.add(name);
                }
                if (mc['id'] != null) {
                  categoryMap[mc['id'].toString()] = name;
                }
              }
            }
          }

          final items = <DeliveryItem>[];
          if (data['menus'] is List) {
            for (final m in data['menus']) {
              if (m is Map<String, dynamic>) {
                final catId = m['menu_categroy_id']?.toString() ??
                    m['menu_category_id']?.toString() ??
                    m['category_id']?.toString();
                final resolvedCat = (catId != null && categoryMap.containsKey(catId))
                    ? categoryMap[catId]!
                    : (categories.isNotEmpty ? categories.first : 'Popular');

                items.add(DeliveryItem.fromJson(
                  m,
                  defaultCategory: resolvedCat,
                  fallbackStoreId: propertyId.toString(),
                ));
              }
            }
          }

          final effectiveCategories = <String>[];
          if (categories.isNotEmpty) {
            effectiveCategories.add('All');
            effectiveCategories.addAll(categories);
          } else {
            effectiveCategories.addAll(['All', 'Popular']);
          }

          store = Store.fromJson(propJson, items: items).copyWith(
            categories: effectiveCategories,
          );
        }
      },
    );
    return store;
  }

  /// Global search for properties and menus
  static Future<Map<String, dynamic>> searchGlobal(String keyword) async {
    final result = <String, dynamic>{
      'properties': <Store>[],
      'menus': <DeliveryItem>[],
    };

    await DioService.dioGet(
      path: ApiEndpoints.searchGlobal,
      queryParameters: {'keyword': keyword},
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
          final res = data['data'] as Map<String, dynamic>;

          if (res['properties'] is List) {
            for (final p in res['properties']) {
              if (p is Map<String, dynamic>) {
                (result['properties'] as List<Store>).add(Store.fromJson(p));
              }
            }
          }

          if (res['menus'] is List) {
            for (final m in res['menus']) {
              if (m is Map<String, dynamic>) {
                (result['menus'] as List<DeliveryItem>).add(DeliveryItem.fromJson(m));
              }
            }
          }
        }
      },
    );

    return result;
  }
}
