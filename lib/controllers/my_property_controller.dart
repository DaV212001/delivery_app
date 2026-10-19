import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/storage_config.dart';
import '../models/category_model.dart';
import '../models/my_menu_category_model.dart';
import '../models/my_menu_item_model.dart';
import '../models/my_property_model.dart';
import '../services/property_service.dart';
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

  // Delivery categories & delivery types for registration
  final deliveryCategories = <CategoryModel>[].obs;
  final deliveryTypes = <CategoryModel>[].obs;
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
      properties.assignAll(list);

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
      } else {
        selectedProperty.value = null;
        categories.clear();
        menuItems.clear();
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
    loadCategoriesAndMenus(property.id);
  }

  /// Load categories and menu items for a property
  Future<void> loadCategoriesAndMenus(int propertyId) async {
    isLoadingMenus.value = true;
    try {
      final catList = await PropertyService.fetchMyMenuCategories(propertyId);
      categories.assignAll(catList);

      final items = await PropertyService.fetchPropertyMenus(propertyId);
      menuItems.assignAll(items);
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

  /// Add new menu item
  Future<bool> saveMenuItem({
    int? editingId,
    required String name,
    required dynamic menuCategoryId,
    required double price,
    String? description,
    bool specialOffer = false,
    double discountPercent = 0.0,
    String? imagePath,
  }) async {
    if (selectedProperty.value == null) return false;
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

  /// Load delivery categories & types for registering property
  Future<void> loadRegistrationDropdowns() async {
    if (deliveryCategories.isNotEmpty && deliveryTypes.isNotEmpty) return;
    isLoadingDropdowns.value = true;
    try {
      final cats = await PropertyService.fetchCategories();
      deliveryCategories.assignAll(cats);
      final types = await PropertyService.fetchDeliveryTypes();
      deliveryTypes.assignAll(types);
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
      );

      if (prop != null) {
        await loadProperties(forceRefresh: true);
        selectedProperty.value = prop;
        Get.back();
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
      );

      if (ok) {
        await loadProperties(forceRefresh: true);
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
  }
}
