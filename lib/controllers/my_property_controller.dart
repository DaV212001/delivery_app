import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/storage_config.dart';
import '../constants/pages.dart';
import '../core/theme/app_colors.dart';
import '../models/category_model.dart';
import '../models/currency_model.dart';
import '../models/my_menu_category_model.dart';
import '../models/my_menu_item_model.dart';
import '../models/my_property_model.dart';
import '../models/property_order_model.dart';
import '../services/property_service.dart';
import '../utils/currency_utils.dart';
import 'auth_controller.dart';

class MyPropertyController extends GetxController {
  final isLoading = false.obs;
  final isLoadingMenus = false.obs;
  final isActionLoading = false.obs;
  final isRegistering = false.obs;

  final properties = <MyPropertyModel>[].obs;
  final Rx<MyPropertyModel?> selectedProperty = Rx<MyPropertyModel?>(null);

  final categories = <MyMenuCategoryModel>[].obs;
  final Rx<int?> selectedCategoryId = Rx<int?>(null); // null means "All"

  final menuItems = <MyMenuItemModel>[].obs;
  final searchQuery = ''.obs;

  // Property orders
  final propertyOrders = <PropertyOrderModel>[].obs;
  final isLoadingOrders = false.obs;
  final ordersFilter = 'all'.obs; // 'all', 'active', 'delivered', 'cancelled'
  final ordersSearchQuery = ''.obs;

  // Delivery categories, types & currencies for registration
  final deliveryCategories = <CategoryModel>[].obs;
  final deliveryTypes = <CategoryModel>[].obs;
  final currencies = <CurrencyModel>[].obs;
  final isLoadingDropdowns = false.obs;

  late final AuthController _authController;

  @override
  void onInit() {
    super.onInit();
    _authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    loadProperties();
    loadRegistrationDropdowns();
    loadCurrencies();
  }

  /// Load available currencies
  Future<void> loadCurrencies() async {
    try {
      final list = await PropertyService.fetchCurrencies();
      currencies.assignAll(list);
    } catch (_) {}
  }

  /// Cross-reference the property's currency string to obtain the matching currency ID.
  /// Used when registering/updating menu items.
  int? getCurrencyIdForProperty(MyPropertyModel? property) {
    if (property == null) return null;

    // 1. Check if ID was explicitly persisted
    final savedId = ConfigPreference.getPropertyCurrencyId(property.id);
    if (savedId != null && savedId > 0) return savedId;

    // 2. Check if currency code/name was persisted or on property
    final savedCode = ConfigPreference.getPropertyCurrency(property.id);
    final propCurrency = (savedCode != null && savedCode.trim().isNotEmpty)
        ? savedCode.trim()
        : property.currency.trim();

    final allCurrencies = currencies.isNotEmpty ? currencies : PropertyService.defaultCurrencies;

    if (propCurrency.isEmpty) {
      final etb = allCurrencies.firstWhereOrNull((c) => c.code.toUpperCase() == 'ETB');
      return etb?.id ?? (allCurrencies.isNotEmpty ? allCurrencies.first.id : 2);
    }

    final numericId = int.tryParse(propCurrency);
    if (numericId != null && allCurrencies.any((c) => c.id == numericId)) {
      return numericId;
    }

    final matchCode = allCurrencies.firstWhereOrNull(
      (c) => c.code.trim().toLowerCase() == propCurrency.toLowerCase(),
    );
    if (matchCode != null) return matchCode.id;

    final matchSymbol = allCurrencies.firstWhereOrNull(
      (c) => c.symbol.trim().toLowerCase() == propCurrency.toLowerCase(),
    );
    if (matchSymbol != null) return matchSymbol.id;

    final matchLoose = allCurrencies.firstWhereOrNull(
      (c) => propCurrency.toLowerCase().contains(c.code.toLowerCase()) ||
          c.code.toLowerCase().contains(propCurrency.toLowerCase()),
    );
    if (matchLoose != null) return matchLoose.id;

    final utilId = CurrencyUtils.resolveId(propCurrency);
    if (utilId != null) return utilId;

    // Default fallback to ETB if present, else first currency or 2
    final etb = allCurrencies.firstWhereOrNull((c) => c.code.toUpperCase() == 'ETB');
    if (etb != null) return etb.id;
    return allCurrencies.isNotEmpty ? allCurrencies.first.id : 2;
  }

  /// Returns the display code or symbol for a property's currency.
  String getPropertyCurrencyCode(MyPropertyModel? property) {
    if (property == null) return 'ETB';

    final savedCode = ConfigPreference.getPropertyCurrency(property.id);
    final propCurrency = (savedCode != null && savedCode.trim().isNotEmpty)
        ? savedCode.trim()
        : property.currency.trim();
    if (propCurrency.isEmpty) return 'ETB';

    final allCurrencies = currencies.isNotEmpty ? currencies : PropertyService.defaultCurrencies;
    final match = allCurrencies.firstWhereOrNull(
      (c) => c.code.toLowerCase() == propCurrency.toLowerCase() ||
             c.symbol.toLowerCase() == propCurrency.toLowerCase() ||
             c.id.toString() == propCurrency,
    );
    if (match != null) return match.code;

    final resolved = CurrencyUtils.resolveCode(propCurrency);
    if (resolved.isNotEmpty) return resolved;

    return propCurrency;
  }

  int get currentCustomerId {
    final uid = ConfigPreference.getUserId();
    if (uid != null && uid > 0) return uid;
    final authId = int.tryParse(_authController.user.id);
    if (authId != null && authId > 0) return authId;
    return 1; // Fallback customer ID if testing unauthenticated
  }

  /// Load merchant properties
  Future<void> loadProperties({bool forceRefresh = false}) async {
    isLoading.value = true;
    try {
      final list = await PropertyService.fetchMyProperties(currentCustomerId);

      // Merge persisted currency into properties if backend returned null/ETB
      final mergedList = list.map((p) {
        final savedCode = ConfigPreference.getPropertyCurrency(p.id);
        if (savedCode != null && savedCode.isNotEmpty && p.currency != savedCode) {
          return p.copyWith(currency: savedCode);
        }
        return p;
      }).toList();

      properties.assignAll(mergedList);

      if (properties.isNotEmpty) {
        // Keep current selected if still present, otherwise choose first
        if (selectedProperty.value == null ||
            !properties.any((p) => p.id == selectedProperty.value!.id)) {
          selectedProperty.value = properties.first;
        } else {
          selectedProperty.value = properties.firstWhere(
            (p) => p.id == selectedProperty.value!.id,
            orElse: () => properties.first,
          );
        }
        await loadCategoriesAndMenus(selectedProperty.value!.id);
        loadOrdersForProperty(selectedProperty.value!.id, silent: true);
      } else {
        selectedProperty.value = null;
        categories.clear();
        menuItems.clear();
        propertyOrders.clear();
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'Failed to load properties: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Switch active property
  void selectProperty(MyPropertyModel property) {
    if (selectedProperty.value?.id == property.id) return;
    selectedProperty.value = property;
    selectedCategoryId.value = null;
    searchQuery.value = '';
    ordersSearchQuery.value = '';
    ordersFilter.value = 'all';
    loadCategoriesAndMenus(property.id);
    loadOrdersForProperty(property.id, silent: false);
  }

  int get activeOrdersCount =>
      propertyOrders.where((o) => o.isActive).length;

  int get deliveredOrdersCount =>
      propertyOrders.where((o) => o.isDelivered).length;

  int get cancelledOrdersCount =>
      propertyOrders.where((o) => o.isCancelled).length;

  double get totalOrdersRevenue => propertyOrders
      .where((o) => !o.isCancelled)
      .fold(0.0, (sum, o) => sum + o.effectiveTotal);

  List<PropertyOrderModel> get filteredOrders {
    final query = ordersSearchQuery.value.trim().toLowerCase();
    final filter = ordersFilter.value;

    return propertyOrders.where((o) {
      if (filter == 'active' && !o.isActive) return false;
      if (filter == 'delivered' && !o.isDelivered) return false;
      if (filter == 'cancelled' && !o.isCancelled) return false;

      if (query.isNotEmpty) {
        final matchesId = o.id.toString().contains(query) ||
            o.orderCode.toLowerCase().contains(query);
        final matchesLocation = o.location.toLowerCase().contains(query);
        final matchesCustomer = o.customerFullName.toLowerCase().contains(query);
        final matchesPhone = (o.customerPhone ?? '').contains(query);
        if (!matchesId && !matchesLocation && !matchesCustomer && !matchesPhone) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Load orders for a property
  Future<void> loadOrdersForProperty(int propertyId, {bool silent = false}) async {
    if (!silent) isLoadingOrders.value = true;
    try {
      final list = await PropertyService.fetchOrdersByPropertyId(propertyId);
      propertyOrders.assignAll(list);
    } catch (e) {
      if (!silent) {
        Get.snackbar('error'.tr, 'Failed to load property orders: $e');
      }
    } finally {
      if (!silent) isLoadingOrders.value = false;
    }
  }

  /// Refresh orders for currently selected property
  Future<void> refreshCurrentPropertyOrders() async {
    final prop = selectedProperty.value;
    if (prop != null) {
      await loadOrdersForProperty(prop.id, silent: false);
    }
  }

  /// Load categories and menu items for a property
  Future<void> loadCategoriesAndMenus(int propertyId) async {
    isLoadingMenus.value = true;
    try {
      final catList = await PropertyService.fetchMyMenuCategories(propertyId);
      categories.assignAll(catList);

      final items = await PropertyService.fetchPropertyMenus(propertyId);
      final propCurrencyCode = getPropertyCurrencyCode(selectedProperty.value);

      // Infer property currency from items if not already saved
      if (ConfigPreference.getPropertyCurrency(propertyId) == null && propCurrencyCode == 'ETB') {
        final nonEtbItem = items.firstWhereOrNull((m) =>
            m.currency != null &&
            m.currency!.isNotEmpty &&
            m.currency != 'ETB' &&
            m.currency != 'Br');
        if (nonEtbItem != null) {
          final inferredCode = CurrencyUtils.resolveCode(nonEtbItem.currency);
          await ConfigPreference.setPropertyCurrency(propertyId, inferredCode);
          final inferredId = CurrencyUtils.resolveId(inferredCode);
          if (inferredId != null) {
            await ConfigPreference.setPropertyCurrencyId(propertyId, inferredId);
          }
          if (selectedProperty.value != null && selectedProperty.value!.id == propertyId) {
            selectedProperty.value = selectedProperty.value!.copyWith(currency: inferredCode);
          }
          final idx = properties.indexWhere((p) => p.id == propertyId);
          if (idx != -1) {
            properties[idx] = properties[idx].copyWith(currency: inferredCode);
          }
        }
      }

      // Enrich menu items with property currency if null/empty/ETB and store is non-ETB
      final effectivePropCurrency = getPropertyCurrencyCode(selectedProperty.value);
      final enrichedMenus = items.map((item) {
        if (effectivePropCurrency != 'ETB') {
          if (item.currency == null || item.currency!.isEmpty || item.currency == 'ETB') {
            return item.copyWith(currency: effectivePropCurrency);
          }
        }
        return item;
      }).toList();

      menuItems.assignAll(enrichedMenus);
    } catch (e) {
      Get.snackbar('error'.tr, 'Failed to load catalog: $e');
    } finally {
      isLoadingMenus.value = false;
    }
  }

  /// Filtered list of menu items based on search query and selected category
  List<MyMenuItemModel> get filteredMenuItems {
    return menuItems.where((item) {
      // Category filter
      if (selectedCategoryId.value != null) {
        final matchesCat = item.menuCategoryId?.toString() == selectedCategoryId.value.toString();
        if (!matchesCat) return false;
      }

      // Search keyword
      if (searchQuery.value.trim().isNotEmpty) {
        final q = searchQuery.value.trim().toLowerCase();
        final nameMatch = item.name.toLowerCase().contains(q);
        final descMatch = item.description.toLowerCase().contains(q);
        if (!nameMatch && !descMatch) return false;
      }

      return true;
    }).toList();
  }

  /// Filter by category
  void filterByCategory(int? categoryId) {
    selectedCategoryId.value = categoryId;
  }

  /// Update search query
  void updateSearch(String query) {
    searchQuery.value = query;
  }

  /// Toggle menu status (active / inactive) with optimistic update
  Future<void> toggleMenuStatus(MyMenuItemModel item) async {
    final newStatus = item.status == 1 ? 0 : 1;
    final index = menuItems.indexWhere((m) => m.id == item.id);
    if (index == -1) return;

    // Optimistic update
    final oldItem = menuItems[index];
    menuItems[index] = oldItem.copyWith(status: newStatus);

    final ok = await PropertyService.updateMenuStatus(
      menuId: item.id,
      status: newStatus,
    );

    if (!ok) {
      // Rollback
      menuItems[index] = oldItem;
      Get.snackbar(
        'error'.tr,
        'Failed to update menu item status',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'success'.tr,
        newStatus == 1 ? 'Item is now active' : 'Item is now inactive',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 1),
        backgroundColor: (newStatus == 1 ? Colors.green : Colors.grey).withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  /// Add new menu category
  Future<bool> addCategory(String name) async {
    if (selectedProperty.value == null || name.trim().isEmpty) return false;
    isActionLoading.value = true;
    try {
      final created = await PropertyService.addMenuCategory(
        name: name.trim(),
        propertyId: selectedProperty.value!.id,
      );
      if (created != null) {
        categories.add(created);
        Get.back(); // close dialog if open
        Get.snackbar(
          'success'.tr,
          'Category added successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'Failed to add category: $e');
    } finally {
      isActionLoading.value = false;
    }
    return false;
  }

  /// Edit existing category
  Future<bool> editCategory(int categoryId, String newName) async {
    if (selectedProperty.value == null || newName.trim().isEmpty) return false;
    isActionLoading.value = true;
    try {
      final ok = await PropertyService.updateMenuCategory(
        id: categoryId,
        name: newName.trim(),
        propertyId: selectedProperty.value!.id,
      );
      if (ok) {
        final idx = categories.indexWhere((c) => c.id == categoryId);
        if (idx != -1) {
          categories[idx] = MyMenuCategoryModel(
            id: categoryId,
            name: newName.trim(),
            propertyId: selectedProperty.value!.id,
            propertyName: selectedProperty.value!.name,
          );
        }
        Get.back();
        Get.snackbar(
          'success'.tr,
          'Category updated successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'Failed to update category: $e');
    } finally {
      isActionLoading.value = false;
    }
    return false;
  }

  /// Add or update menu item
  Future<bool> saveMenuItem({
    int? editingId,
    required String name,
    required dynamic menuCategoryId,
    required double price,
    String? description,
    bool specialOffer = false,
    double discountPercent = 0.0,
    String? imagePath,
    dynamic currencyId,
  }) async {
    if (selectedProperty.value == null) return false;
    final effectiveCurrencyId = currencyId ?? getCurrencyIdForProperty(selectedProperty.value);

    if (description == null || description.trim().isEmpty) {
      if (Get.context != null && !Get.testMode) {
        Get.snackbar(
          'error'.tr,
          'Please enter a description',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
      return false;
    }
    isActionLoading.value = true;

    try {
      if (editingId != null) {
        // Update existing item
        final ok = await PropertyService.updateMenuItem(
          menuId: editingId,
          propertyId: selectedProperty.value!.id,
          name: name.trim(),
          menuCategoryId: menuCategoryId,
          price: price,
          description: description,
          specialOffer: specialOffer,
          discountPercent: discountPercent,
          imageFilePath: imagePath,
          currencyId: effectiveCurrencyId,
        );
        if (ok) {
          await loadCategoriesAndMenus(selectedProperty.value!.id);
          Get.back();
          Get.snackbar(
            'success'.tr,
            'Item updated successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
          return true;
        }
      } else {
        // Create new item
        final created = await PropertyService.addMenuItem(
          propertyId: selectedProperty.value!.id,
          name: name.trim(),
          menuCategoryId: menuCategoryId,
          price: price,
          description: description,
          specialOffer: specialOffer,
          discountPercent: discountPercent,
          imageFilePath: imagePath,
          currencyId: effectiveCurrencyId,
        );
        if (created != null) {
          await loadCategoriesAndMenus(selectedProperty.value!.id);
          Get.back();
          Get.snackbar(
            'success'.tr,
            'Item added successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
          return true;
        }
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'Failed to save menu item: $e');
    } finally {
      isActionLoading.value = false;
    }
    return false;
  }

  /// Load delivery categories, types & currencies for registering property
  Future<void> loadRegistrationDropdowns() async {
    if (deliveryCategories.isNotEmpty && deliveryTypes.isNotEmpty && currencies.isNotEmpty) return;
    isLoadingDropdowns.value = true;
    try {
      final cats = await PropertyService.fetchCategories();
      deliveryCategories.assignAll(cats);
      final types = await PropertyService.fetchDeliveryTypes();
      deliveryTypes.assignAll(types);
      final currList = await PropertyService.fetchCurrencies();
      currencies.assignAll(currList);
    } catch (_) {
    } finally {
      isLoadingDropdowns.value = false;
    }
  }

  /// Register a new property
  Future<bool> registerNewProperty({
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
    dynamic currencyId,
  }) async {
    isRegistering.value = true;
    try {
      final prop = await PropertyService.registerProperty(
        customerId: currentCustomerId,
        name: name.trim(),
        categoryId: categoryId,
        typeId: typeId,
        friendlyLocation: friendlyLocation.trim(),
        description: description.trim(),
        deliveryTime: deliveryTime.trim(),
        tinNumber: tinNumber.trim(),
        latitude: latitude.trim(),
        longitude: longitude.trim(),
        fromTime: fromTime.trim(),
        toTime: toTime.trim(),
        logoPath: logoPath,
        coverImagePath: coverImagePath,
        tinCertificatePath: tinCertificatePath,
        tradeLicensePath: tradeLicensePath,
        currencyId: currencyId,
      );

      if (prop != null) {
        String chosenCurrencyCode = 'ETB';
        if (currencyId != null) {
          final allCurrencies = currencies.isNotEmpty ? currencies : PropertyService.defaultCurrencies;
          final match = allCurrencies.firstWhereOrNull((c) => c.id.toString() == currencyId.toString());
          chosenCurrencyCode = match?.code ?? CurrencyUtils.resolveCode(currencyId);
          await ConfigPreference.setPropertyCurrency(prop.id, chosenCurrencyCode);
          final cid = int.tryParse(currencyId.toString());
          if (cid != null) {
            await ConfigPreference.setPropertyCurrencyId(prop.id, cid);
          }
        }

        final propertyWithCurrency = prop.copyWith(currency: chosenCurrencyCode);

        await loadProperties(forceRefresh: true);

        final existingIdx = properties.indexWhere((p) => p.id == prop.id);
        if (existingIdx != -1) {
          properties[existingIdx] = properties[existingIdx].copyWith(currency: chosenCurrencyCode);
          selectedProperty.value = properties[existingIdx];
        } else {
          properties.add(propertyWithCurrency);
          selectedProperty.value = propertyWithCurrency;
        }

        final targetProp = selectedProperty.value ?? propertyWithCurrency;
        selectProperty(targetProp);

        Get.offNamed(AppRoutes.manageProperty);
        Get.toNamed(
          AppRoutes.propertySchedules,
          arguments: {
            'property': targetProp,
            'id': targetProp.id,
            'name': targetProp.name,
            'isFromRegistration': true,
          },
        );
        Get.snackbar(
          'success'.tr,
          'Property registered successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        return true;
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'Failed to register property: $e');
    } finally {
      isRegistering.value = false;
    }
    return false;
  }

  /// Update an existing property
  Future<bool> updateExistingProperty({
    required int propertyId,
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
    dynamic currencyId,
  }) async {
    isRegistering.value = true;
    try {
      final ok = await PropertyService.updateProperty(
        propertyId: propertyId,
        customerId: currentCustomerId,
        name: name.trim(),
        categoryId: categoryId,
        typeId: typeId,
        friendlyLocation: friendlyLocation.trim(),
        description: description.trim(),
        deliveryTime: deliveryTime.trim(),
        tinNumber: tinNumber?.trim(),
        latitude: latitude.trim(),
        longitude: longitude.trim(),
        fromTime: fromTime.trim(),
        toTime: toTime.trim(),
        logoPath: logoPath,
        coverImagePath: coverImagePath,
        tinCertificatePath: tinCertificatePath,
        tradeLicensePath: tradeLicensePath,
        currencyId: currencyId,
      );

      if (ok) {
        if (currencyId != null) {
          final allCurrencies = currencies.isNotEmpty ? currencies : PropertyService.defaultCurrencies;
          final match = allCurrencies.firstWhereOrNull((c) => c.id.toString() == currencyId.toString());
          final chosenCode = match?.code ?? CurrencyUtils.resolveCode(currencyId);
          await ConfigPreference.setPropertyCurrency(propertyId, chosenCode);
          final cid = int.tryParse(currencyId.toString());
          if (cid != null) {
            await ConfigPreference.setPropertyCurrencyId(propertyId, cid);
          }
        }
        await loadProperties(forceRefresh: true);
        if (selectedProperty.value != null && selectedProperty.value!.id == propertyId) {
          final savedCode = ConfigPreference.getPropertyCurrency(propertyId);
          if (savedCode != null) {
            selectedProperty.value = selectedProperty.value!.copyWith(currency: savedCode);
          }
        }
        Get.back();
        Get.snackbar(
          'success'.tr,
          'Property updated successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        return true;
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'Failed to update property: $e');
    } finally {
      isRegistering.value = false;
    }
    return false;
  }

  /// Reset all merchant property and catalog state (called on logout)
  void clear() {
    properties.clear();
    selectedProperty.value = null;
    categories.clear();
    menuItems.clear();
    propertyOrders.clear();
  }
}
