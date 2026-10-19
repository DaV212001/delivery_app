import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../config/storage_config.dart';
import '../models/cart_batch.dart';
import '../models/cart_item.dart';
import '../models/delivery_item.dart';
import '../models/property_delivery_option.dart';
import '../services/order_service.dart';
import '../utils/location_utils.dart';
import 'restaurant_controller.dart';

class CartController extends GetxController {
  final items = <CartItem>[].obs;
  final savedBatches = <CartBatch>[].obs;
  final deliveryAddress = ''.obs;
  final deliveryInstructions = ''.obs;
  final selectedPaymentMethod = 'chapa'.obs; // 'chapa', 'wallet', 'cash'
  final promoCode = ''.obs;
  final promoDiscount = 0.0.obs;

  // Property Delivery Options & Pricing
  final propertyDeliveryOptions = <PropertyDeliveryOption>[].obs;
  final selectedDeliveryOption = Rxn<PropertyDeliveryOption>();
  final isLoadingDeliveryOptions = false.obs;

  // Dynamic Coordinates
  final customerLatitude = Rxn<double>();
  final customerLongitude = Rxn<double>();
  final propertyLatitude = Rxn<double>();
  final propertyLongitude = Rxn<double>();

  @override
  void onInit() {
    super.onInit();
    loadFromLocalStorage();
    ever(items, (_) => saveToLocalStorage());
    ever(savedBatches, (_) => saveToLocalStorage());
  }

  void loadFromLocalStorage() {
    try {
      final activeJson = ConfigPreference.getActiveCartJson();
      if (activeJson != null && activeJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(activeJson);
        final loadedItems = decoded
            .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        items.assignAll(loadedItems);
        if (items.isNotEmpty && selectedDeliveryOption.value == null) {
          loadDeliveryOptionsForProperty(items.first.item.storeId);
        }
      }

      final batchesJson = ConfigPreference.getSavedCartBatchesJson();
      if (batchesJson != null && batchesJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(batchesJson);
        final loadedBatches = decoded
            .map((e) => CartBatch.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        savedBatches.assignAll(loadedBatches);
      }
    } catch (e) {
      debugPrint('Error loading cart from local storage: $e');
    }
  }

  void saveToLocalStorage() {
    try {
      if (items.isEmpty) {
        ConfigPreference.clearActiveCartJson().catchError((_) {});
      } else {
        final activeJson = jsonEncode(items.map((i) => i.toJson()).toList());
        ConfigPreference.setActiveCartJson(activeJson).catchError((_) {});
      }

      if (savedBatches.isEmpty) {
        ConfigPreference.clearSavedCartBatchesJson().catchError((_) {});
      } else {
        final batchesJson = jsonEncode(savedBatches.map((b) => b.toJson()).toList());
        ConfigPreference.setSavedCartBatchesJson(batchesJson).catchError((_) {});
      }
    } catch (e) {
      debugPrint('Error saving cart to local storage: $e');
    }
  }

  /// Cash payment is only available for orders under 2,000 ETB
  bool get isCashAllowed => total < 2000.0;

  /// Payment type mapping: 0 (Cash), 1 (Chapa), 2 (Wallet)
  String get paymentTypeNumeric {
    switch (selectedPaymentMethod.value) {
      case 'cash':
        return '0';
      case 'chapa':
        return '1';
      case 'wallet':
        return '2';
      default:
        return '0';
    }
  }

  int get totalItemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// item_total_price sum
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Distance in km calculated via Haversine formula between customer and property
  double get distanceInKm {
    final uLat = customerLatitude.value ?? LocationUtils.defaultLatitude;
    final uLng = customerLongitude.value ?? LocationUtils.defaultLongitude;
    final pLat = propertyLatitude.value ?? LocationUtils.defaultLatitude;
    final pLng = propertyLongitude.value ?? LocationUtils.defaultLongitude;
    return LocationUtils.calculateDistanceInKm(
      lat1: uLat,
      lon1: uLng,
      lat2: pLat,
      lon2: pLng,
    );
  }

  /// Total km price derived from km_price * haversine distance
  double get totalKmPrice {
    if (items.isEmpty) return 0.0;
    final option = selectedDeliveryOption.value;
    if (option == null) return 0.0;
    final dist = distanceInKm > 0 ? distanceInKm : 1.0;
    return double.parse((option.kmPrice * dist).toStringAsFixed(2));
  }

  double get deliveryFee {
    if (items.isEmpty) return 0.0;
    if (selectedDeliveryOption.value != null) {
      return totalKmPrice;
    }
    return 2.99; // Fallback for testing environments
  }

  double get taxAndFees {
    if (items.isEmpty) return 0.0;
    // When delivery option is active, total equals item_total_price + total_km_price
    if (selectedDeliveryOption.value != null) return 0.0;
    return (subtotal * 0.10) + 0.40; // ~10% tax plus service fee for mock tests
  }

  /// Total amount: item_total_price + total_km_price (minus promo if any)
  double get total {
    if (items.isEmpty) return 0.0;
    final fee = selectedDeliveryOption.value != null ? totalKmPrice : (deliveryFee + taxAndFees);
    final val = subtotal + fee - promoDiscount.value;
    return val > 0 ? val : 0.0;
  }

  /// Fetch delivery options for property
  Future<void> loadDeliveryOptionsForProperty(dynamic propertyId, {double? propLat, double? propLng}) async {
    if (propLat != null) propertyLatitude.value = propLat;
    if (propLng != null) propertyLongitude.value = propLng;

    isLoadingDeliveryOptions.value = true;
    try {
      final options = await OrderService.fetchPropertyDeliveryOptions(propertyId);
      if (options.isNotEmpty) {
        propertyDeliveryOptions.assignAll(options);
        if (selectedDeliveryOption.value == null ||
            !options.any((o) => o.name == selectedDeliveryOption.value?.name)) {
          selectedDeliveryOption.value = options.first;
        }
      } else {
        const fallback = PropertyDeliveryOption(
          id: 1,
          image: '',
          name: 'Motorbike',
          kmPrice: 13.0,
        );
        propertyDeliveryOptions.assignAll([fallback]);
        if (selectedDeliveryOption.value == null) {
          selectedDeliveryOption.value = fallback;
        }
      }
    } catch (_) {
      const fallback = PropertyDeliveryOption(
        id: 1,
        image: '',
        name: 'Motorbike',
        kmPrice: 13.0,
      );
      propertyDeliveryOptions.assignAll([fallback]);
      if (selectedDeliveryOption.value == null) {
        selectedDeliveryOption.value = fallback;
      }
    } finally {
      isLoadingDeliveryOptions.value = false;
    }
  }

  /// Current active property ID
  String? get activePropertyId => items.isNotEmpty ? items.first.item.storeId : null;

  /// Display name of the store for currently active items
  String get activePropertyName {
    if (items.isEmpty) return '';
    final sId = items.first.item.storeId;
    if (Get.isRegistered<RestaurantController>()) {
      final rc = Get.find<RestaurantController>();
      final store = rc.getRestaurantById(sId);
      if (store != null && store.name.isNotEmpty) return store.name;
    }
    return items.first.item.name;
  }

  /// Checks if an item belongs to a different property than the active cart
  bool isDifferentProperty(DeliveryItem item) {
    if (items.isEmpty) return false;
    final currentStoreId = items.first.item.storeId;
    if (currentStoreId.isEmpty || item.storeId.isEmpty) return false;
    return currentStoreId != item.storeId;
  }

  /// Archive current active cart items into saved batches
  void saveCurrentBatch({String? propertyName, String? propertyImage}) {
    if (items.isEmpty) return;
    final sId = items.first.item.storeId;
    String name = propertyName ?? '';
    String? image = propertyImage;
    if (name.isEmpty && Get.isRegistered<RestaurantController>()) {
      final rc = Get.find<RestaurantController>();
      final store = rc.getRestaurantById(sId);
      if (store != null) {
        name = store.name;
        image ??= (store.logoUrl != null && store.logoUrl!.isNotEmpty)
            ? store.logoUrl
            : store.heroImageUrl;
      }
    }
    if (name.isEmpty) {
      name = items.first.item.name;
    }

    savedBatches.removeWhere((b) => b.propertyId == sId);
    savedBatches.add(
      CartBatch(
        propertyId: sId,
        propertyName: name,
        propertyImage: image,
        items: List<CartItem>.from(items),
        updatedAt: DateTime.now(),
      ),
    );

    items.clear();
    promoDiscount.value = 0.0;
    propertyDeliveryOptions.clear();
    selectedDeliveryOption.value = null;
    saveToLocalStorage();
  }

  /// Restores a saved batch to become the active cart.
  /// If active cart has items from another store, archives them first.
  void restoreBatch(CartBatch batch) {
    if (items.isNotEmpty && items.first.item.storeId != batch.propertyId) {
      saveCurrentBatch();
    }
    savedBatches.removeWhere((b) => b.propertyId == batch.propertyId);
    items.assignAll(batch.items);
    loadDeliveryOptionsForProperty(batch.propertyId);
    saveToLocalStorage();
  }

  /// Deletes a saved batch
  void deleteSavedBatch(String propertyId) {
    savedBatches.removeWhere((b) => b.propertyId == propertyId);
    saveToLocalStorage();
  }

  /// Saves current batch and starts a new batch with newItem
  void saveCurrentBatchAndStartNew({
    required DeliveryItem newItem,
    int quantity = 1,
    String? selectedVariant,
    List<CustomizationAddon> selectedAddons = const [],
    List<String> removedOptions = const [],
    String? specialInstructions,
  }) {
    saveCurrentBatch();
    final existingSaved = savedBatches.firstWhereOrNull((b) => b.propertyId == newItem.storeId);
    if (existingSaved != null) {
      restoreBatch(existingSaved);
    }
    addItem(
      item: newItem,
      quantity: quantity,
      selectedVariant: selectedVariant,
      selectedAddons: selectedAddons,
      removedOptions: removedOptions,
      specialInstructions: specialInstructions,
    );
    loadDeliveryOptionsForProperty(newItem.storeId);
  }

  void addItem({
    DeliveryItem? item,
    FoodItem? foodItem,
    int quantity = 1,
    String? selectedVariant,
    String? selectedTemperature,
    List<CustomizationAddon> selectedAddons = const [],
    List<String> removedOptions = const [],
    List<String> removedIngredients = const [],
    String? specialInstructions,
  }) {
    final effectiveItem = item ?? foodItem;
    if (effectiveItem == null) return;

    if (Get.isRegistered<RestaurantController>()) {
      final rc = Get.find<RestaurantController>();
      final store = rc.getRestaurantById(effectiveItem.storeId);
      if (store != null && store.isPastClosingTime) {
        if (Get.context != null && !Get.testMode) {
          Get.snackbar('store'.tr, 'closed_ordering_disabled'.tr);
        }
        return;
      }
    }

    final effectiveVariant = selectedVariant ?? selectedTemperature;
    final effectiveRemovals = removedOptions.isNotEmpty ? removedOptions : removedIngredients;

    // Check if duplicate item with exact customizations exists
    final existingIndex = items.indexWhere((ci) =>
        ci.item.id == effectiveItem.id &&
        ci.selectedVariant == effectiveVariant &&
        ci.selectedAddons.length == selectedAddons.length &&
        ci.removedOptions.length == effectiveRemovals.length);

    if (existingIndex >= 0) {
      items[existingIndex].quantity += quantity;
      items.refresh();
    } else {
      items.add(
        CartItem(
          id: 'cart_${DateTime.now().millisecondsSinceEpoch}',
          item: effectiveItem,
          quantity: quantity,
          selectedVariant: effectiveVariant,
          selectedAddons: selectedAddons,
          removedOptions: effectiveRemovals,
          specialInstructions: specialInstructions,
        ),
      );
    }
  }

  void incrementQuantity(String cartItemId) {
    final index = items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      items[index].quantity++;
      items.refresh();
    }
  }

  void decrementQuantity(String cartItemId) {
    final index = items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      if (items[index].quantity > 1) {
        items[index].quantity--;
        items.refresh();
      } else {
        items.removeAt(index);
      }
    }
  }

  void applyPromo(String code) {
    final upper = code.trim().toUpperCase();
    if (upper == 'AMN' || upper == 'AMNDELIVERY' || upper == 'FREESHIP' || upper == 'FREEDELIVERY') {
      promoDiscount.value = 50.0;
      if (Get.context != null) {
        Get.snackbar('promo_applied'.tr, 'promo_freedelivery'.tr);
      }
    } else if (code.trim().isNotEmpty) {
      promoDiscount.value = 50.0;
      if (Get.context != null) {
        Get.snackbar('promo_applied'.tr, 'promo_discount_applied'.tr);
      }
    }
  }
  void clearCart() {
    items.clear();
    promoDiscount.value = 0.0;
    propertyDeliveryOptions.clear();
    selectedDeliveryOption.value = null;
    saveToLocalStorage();
  }

  void clearAll() {
    items.clear();
    savedBatches.clear();
    promoDiscount.value = 0.0;
    propertyDeliveryOptions.clear();
    selectedDeliveryOption.value = null;
    saveToLocalStorage();
  }
}

