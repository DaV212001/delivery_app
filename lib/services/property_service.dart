import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../models/category_model.dart';
import '../models/delivery_item.dart';
import '../models/my_menu_category_model.dart';
import '../models/my_menu_item_model.dart';
import '../models/my_property_model.dart';
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

  static final Map<String, Store> _propertyCache = {};

  /// Synchronously get cached property by ID if already fetched
  static Store? getCachedProperty(dynamic id) {
    if (id == null) return null;
    final key = id.toString();
    return _propertyCache[key];
  }

  /// Bulk cache stores into in-memory lookup map
  static void cacheStores(Iterable<Store> stores) {
    for (final s in stores) {
      if (s.id.isNotEmpty) {
        _propertyCache[s.id] = s;
      }
    }
  }

  /// Ensure all properties are cached in memory for instant name/logo resolution
  static Future<void> ensurePropertiesCached() async {
    if (_propertyCache.isNotEmpty) return;
    await fetchProperties();
  }

  /// Resolve property by ID from cache or fetch asynchronously
  static Future<Store?> resolveProperty(dynamic propertyId) async {
    if (propertyId == null) return null;
    final key = propertyId.toString();
    if (_propertyCache.containsKey(key)) {
      return _propertyCache[key];
    }
    final store = await fetchPropertyDetail(key);
    if (store != null && store.id.isNotEmpty) {
      _propertyCache[store.id] = store;
    }
    return store;
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
              final store = Store.fromJson(item);
              list.add(store);
              if (store.id.isNotEmpty) {
                _propertyCache[store.id] = store;
              }
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

          final resolvedStore = Store.fromJson(propJson, items: items).copyWith(
            categories: effectiveCategories,
          );
          store = resolvedStore;
          if (resolvedStore.id.isNotEmpty) {
            _propertyCache[resolvedStore.id] = resolvedStore;
          }
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

  /// Fetch properties owned by a customer
  static Future<List<MyPropertyModel>> fetchMyProperties(dynamic customerId) async {
    final list = <MyPropertyModel>[];
    await DioService.dioGet(
      path: ApiEndpoints.myProperty(customerId),
      onSuccess: (response) {
        final resData = response.data;
        final rawList = resData is Map<String, dynamic>
            ? (resData['data'] is List ? resData['data'] : null)
            : (resData is List ? resData : null);
        if (rawList is List) {
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              list.add(MyPropertyModel.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Fetch menu categories for a specific property
  static Future<List<MyMenuCategoryModel>> fetchMyMenuCategories(dynamic propertyId) async {
    final list = <MyMenuCategoryModel>[];
    await DioService.dioGet(
      path: ApiEndpoints.myMenuCategory(propertyId),
      onSuccess: (response) {
        final resData = response.data;
        final rawList = resData is Map<String, dynamic>
            ? (resData['data'] is List ? resData['data'] : null)
            : (resData is List ? resData : null);
        if (rawList is List) {
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              list.add(MyMenuCategoryModel.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }

  /// Add a new menu category
  static Future<MyMenuCategoryModel?> addMenuCategory({
    required String name,
    required dynamic propertyId,
  }) async {
    MyMenuCategoryModel? created;
    await DioService.dioPost(
      path: ApiEndpoints.menuCategory,
      data: {
        'name': name,
        'property_id': propertyId.toString(),
      },
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] != null) {
          final inner = data['data'];
          if (inner is List && inner.isNotEmpty && inner.first is Map<String, dynamic>) {
            created = MyMenuCategoryModel.fromJson(inner.first as Map<String, dynamic>);
          } else if (inner is Map<String, dynamic>) {
            created = MyMenuCategoryModel.fromJson(inner);
          }
        }
      },
    );
    return created;
  }

  /// Update an existing menu category
  static Future<bool> updateMenuCategory({
    required dynamic id,
    required String name,
    required dynamic propertyId,
  }) async {
    bool ok = false;
    await DioService.dioPut(
      path: ApiEndpoints.menuCategoryDetail(id),
      data: {
        'name': name,
        'property_id': propertyId.toString(),
      },
      onSuccess: (response) {
        ok = true;
      },
    );
    return ok;
  }

  /// Fetch menu items of a property (detailed catalog)
  static Future<List<MyMenuItemModel>> fetchPropertyMenus(dynamic propertyId) async {
    final list = <MyMenuItemModel>[];

    // First attempt: fetch from property details which returns rich items
    await DioService.dioGet(
      path: ApiEndpoints.propertyDetail(propertyId),
      onSuccess: (response) {
        final resData = response.data;
        if (resData is Map<String, dynamic> && resData['data'] is Map<String, dynamic>) {
          final data = resData['data'] as Map<String, dynamic>;
          if (data['menus'] is List) {
            for (final m in data['menus']) {
              if (m is Map<String, dynamic>) {
                list.add(MyMenuItemModel.fromJson(m));
              }
            }
          }
        }
      },
    );

    // Fallback if propertyDetail returned no menus
    if (list.isEmpty) {
      await DioService.dioGet(
        path: ApiEndpoints.myMenuByProperty(propertyId),
        onSuccess: (response) {
          final resData = response.data;
          final rawList = resData is Map<String, dynamic>
              ? (resData['data'] is List ? resData['data'] : null)
              : (resData is List ? resData : null);
          if (rawList is List) {
            for (final m in rawList) {
              if (m is Map<String, dynamic>) {
                list.add(MyMenuItemModel.fromJson(m));
              }
            }
          }
        },
      );
    }

    return list;
  }

  /// Search menus within a specific property
  static Future<List<MyMenuItemModel>> searchPropertyMenus({
    required dynamic propertyId,
    required String keyword,
  }) async {
    final list = <MyMenuItemModel>[];
    await DioService.dioGet(
      path: ApiEndpoints.searchProperty(propertyId),
      queryParameters: {'keyword': keyword},
      onSuccess: (response) {
        final resData = response.data;
        if (resData is Map<String, dynamic> && resData['data'] is Map<String, dynamic>) {
          final data = resData['data'] as Map<String, dynamic>;
          final results = data['results'] ?? data['menus'];
          if (results is List) {
            for (final m in results) {
              if (m is Map<String, dynamic>) {
                list.add(MyMenuItemModel.fromJson(m));
              }
            }
          }
        }
      },
    );
    return list;
  }

  /// Add a new menu item
  static Future<MyMenuItemModel?> addMenuItem({
    required dynamic propertyId,
    required String name,
    required dynamic menuCategoryId,
    required double price,
    String? description,
    bool specialOffer = false,
    double discountPercent = 0.0,
    String? imageFilePath,
  }) async {
    MyMenuItemModel? created;
    final map = <String, dynamic>{
      'property_id': propertyId.toString(),
      'name': name,
      'desacriprion': description ?? '',
      'menu_categroy_id': menuCategoryId.toString(),
      'price': price.toString(),
      'special_offer': specialOffer ? '1' : '0',
      'discount_percent': discountPercent > 0 ? discountPercent.toString() : '0',
    };

    if (imageFilePath != null && imageFilePath.isNotEmpty) {
      final fileName = imageFilePath.split(RegExp(r'[/\\]')).last;
      map['image'] = await MultipartFile.fromFile(imageFilePath, filename: fileName);
    }

    final formData = FormData.fromMap(map);

    await DioService.dioUpload(
      path: ApiEndpoints.myMenu,
      formData: formData,
      onSuccess: (response) {
        final resData = response.data;
        if (resData is Map<String, dynamic> && resData['data'] != null) {
          final data = resData['data'];
          if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
            created = MyMenuItemModel.fromJson(data.first as Map<String, dynamic>);
          } else if (data is Map<String, dynamic>) {
            created = MyMenuItemModel.fromJson(data);
          }
        }
      },
    );

    return created;
  }

  /// Update an existing menu item
  static Future<bool> updateMenuItem({
    required dynamic menuId,
    required dynamic propertyId,
    required String name,
    required dynamic menuCategoryId,
    required double price,
    String? description,
    bool specialOffer = false,
    double discountPercent = 0.0,
    String? imageFilePath,
  }) async {
    bool ok = false;
    final map = <String, dynamic>{
      'property_id': propertyId.toString(),
      'name': name,
      'desacriprion': description ?? '',
      'menu_categroy_id': menuCategoryId.toString(),
      'price': price.toString(),
      'special_offer': specialOffer ? '1' : '0',
      'discount_percent': discountPercent > 0 ? discountPercent.toString() : '0',
    };

    if (imageFilePath != null && imageFilePath.isNotEmpty) {
      final fileName = imageFilePath.split(RegExp(r'[/\\]')).last;
      map['image'] = await MultipartFile.fromFile(imageFilePath, filename: fileName);
    }

    final formData = FormData.fromMap(map);

    await DioService.dioUpload(
      path: ApiEndpoints.myMenuDetail(menuId),
      formData: formData,
      onSuccess: (response) {
        ok = true;
      },
    );

    return ok;
  }

  /// Toggle or update menu item active status (1 = active, 0 = inactive)
  static Future<bool> updateMenuStatus({
    required dynamic menuId,
    required int status,
  }) async {
    bool ok = false;
    final formData = FormData.fromMap({
      'id': menuId.toString(),
      'status': status.toString(),
    });

    await DioService.dioUpload(
      path: ApiEndpoints.updateMenuStatus,
      formData: formData,
      onSuccess: (response) {
        ok = true;
      },
    );

    return ok;
  }

  /// Register a new property
  static Future<MyPropertyModel?> registerProperty({
    required dynamic customerId,
    required String name,
    required dynamic categoryId,
    required dynamic typeId,
    required String friendlyLocation,
    required String description,
    required String deliveryTime,
    required String tinNumber,
    required String latitude,
    required String longitude,
    required String fromTime,
    required String toTime,
    String? logoPath,
    String? coverImagePath,
    String? tinCertificatePath,
    String? tradeLicensePath,
  }) async {
    MyPropertyModel? registered;

    final map = <String, dynamic>{
      'customer_id': customerId.toString(),
      'name': name,
      'category_id': categoryId.toString(),
      'type_id': typeId.toString(),
      'frendly_location': friendlyLocation,
      'description': description,
      'delivery_time': deliveryTime,
      'tin_number': tinNumber,
      'latitude': latitude,
      'longitude': longitude,
      'from_time': fromTime,
      'to_time': toTime,
    };

    if (logoPath != null && logoPath.isNotEmpty) {
      final fName = logoPath.split(RegExp(r'[/\\]')).last;
      map['logo'] = await MultipartFile.fromFile(logoPath, filename: fName);
    }

    if (coverImagePath != null && coverImagePath.isNotEmpty) {
      final fName = coverImagePath.split(RegExp(r'[/\\]')).last;
      map['cover_image'] = await MultipartFile.fromFile(coverImagePath, filename: fName);
    }

    if (tinCertificatePath != null && tinCertificatePath.isNotEmpty) {
      final fName = tinCertificatePath.split(RegExp(r'[/\\]')).last;
      map['tin_certificate'] = await MultipartFile.fromFile(tinCertificatePath, filename: fName);
    }

    if (tradeLicensePath != null && tradeLicensePath.isNotEmpty) {
      final fName = tradeLicensePath.split(RegExp(r'[/\\]')).last;
      map['trade_license'] = await MultipartFile.fromFile(tradeLicensePath, filename: fName);
    }

    final formData = FormData.fromMap(map);

    await DioService.dioUpload(
      path: ApiEndpoints.properties,
      formData: formData,
      onSuccess: (response) {
        final resData = response.data;
        if (resData is Map<String, dynamic> && resData['data'] != null) {
          final data = resData['data'];
          if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
            registered = MyPropertyModel.fromJson(data.first as Map<String, dynamic>);
          } else if (data is Map<String, dynamic>) {
            registered = MyPropertyModel.fromJson(data);
          }
        }
      },
    );

    return registered;
  }

  /// Update an existing property
  static Future<bool> updateProperty({
    required dynamic propertyId,
    required dynamic customerId,
    required String name,
    required dynamic categoryId,
    required dynamic typeId,
    required String friendlyLocation,
    required String description,
    required String deliveryTime,
    String? tinNumber,
    required String latitude,
    required String longitude,
    required String fromTime,
    required String toTime,
    String? logoPath,
    String? coverImagePath,
    String? tinCertificatePath,
    String? tradeLicensePath,
  }) async {
    bool ok = false;
    final map = <String, dynamic>{
      '_method': 'PUT',
      'customer_id': customerId.toString(),
      'name': name,
      'category_id': categoryId.toString(),
      'type_id': typeId.toString(),
      'frendly_location': friendlyLocation,
      'description': description,
      'delivery_time': deliveryTime,
      'latitude': latitude,
      'longitude': longitude,
      'from_time': fromTime,
      'to_time': toTime,
    };

    if (tinNumber != null && tinNumber.isNotEmpty) {
      map['tin_number'] = tinNumber;
    }

    if (logoPath != null && logoPath.isNotEmpty) {
      final fName = logoPath.split(RegExp(r'[/\\]')).last;
      map['logo'] = await MultipartFile.fromFile(logoPath, filename: fName);
    }

    if (coverImagePath != null && coverImagePath.isNotEmpty) {
      final fName = coverImagePath.split(RegExp(r'[/\\]')).last;
      map['cover_image'] = await MultipartFile.fromFile(coverImagePath, filename: fName);
    }

    if (tinCertificatePath != null && tinCertificatePath.isNotEmpty) {
      final fName = tinCertificatePath.split(RegExp(r'[/\\]')).last;
      map['tin_certificate'] = await MultipartFile.fromFile(tinCertificatePath, filename: fName);
    }

    if (tradeLicensePath != null && tradeLicensePath.isNotEmpty) {
      final fName = tradeLicensePath.split(RegExp(r'[/\\]')).last;
      map['trade_license'] = await MultipartFile.fromFile(tradeLicensePath, filename: fName);
    }

    final formData = FormData.fromMap(map);

    await DioService.dioUpload(
      path: ApiEndpoints.propertyDetail(propertyId),
      formData: formData,
      onSuccess: (response) {
        ok = true;
      },
    );

    return ok;
  }
}
