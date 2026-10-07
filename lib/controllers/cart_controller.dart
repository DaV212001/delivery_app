import 'package:get/get.dart';
import '../models/cart_item.dart';
import '../models/delivery_item.dart';

import 'restaurant_controller.dart';

class CartController extends GetxController {
  final items = <CartItem>[].obs;
  final deliveryAddress = ''.obs;
  final deliveryInstructions = ''.obs;
  final selectedPaymentMethod = 'chapa'.obs; // 'chapa', 'wallet', 'cash'
  final promoCode = ''.obs;
  final promoDiscount = 0.0.obs;

  bool get isCashAllowed => total <= 2000.0;

  int get totalItemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get deliveryFee {
    if (items.isEmpty) return 0.0;
    return 2.99;
  }

  double get taxAndFees {
    if (items.isEmpty) return 0.0;
    return (subtotal * 0.10) + 0.40; // ~10% tax plus service fee
  }

  double get total {
    if (items.isEmpty) return 0.0;
    final val = subtotal + deliveryFee + taxAndFees - promoDiscount.value;
    return val > 0 ? val : 0.0;
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
  }
}
