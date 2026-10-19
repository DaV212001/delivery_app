import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/controllers/cart_controller.dart';
import 'package:delivery_app/controllers/my_property_controller.dart';
import 'package:delivery_app/models/cart_batch.dart';
import 'package:delivery_app/models/cart_item.dart';
import 'package:delivery_app/models/delivery_item.dart';
import 'package:delivery_app/models/my_property_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('Cart Batches & Multi-Store Cart Separation Tests', () {
    final itemStoreA = DeliveryItem(
      id: 'item_1',
      storeId: 'store_10',
      name: 'Burger Deluxe',
      description: 'Juicy beef burger',
      price: 250.0,
      imageUrl: 'https://example.com/burger.jpg',
      category: 'Food',
    );

    final itemStoreB = DeliveryItem(
      id: 'item_2',
      storeId: 'store_20',
      name: 'Michelin Tyre 17"',
      description: 'Durable commercial tyre',
      price: 4500.0,
      imageUrl: 'https://example.com/tyre.jpg',
      category: 'Commercial Tyres',
    );

    test('CartItem and CartBatch JSON serialization and deserialization', () {
      final cartItem = CartItem(
        id: 'cart_1',
        item: itemStoreA,
        quantity: 2,
        selectedVariant: 'Medium Well',
        selectedAddons: [
          const CustomizationAddon(id: 'add_1', name: 'Extra Cheese', price: 30.0),
        ],
        removedOptions: ['Pickles'],
        specialInstructions: 'No onions please',
      );

      final itemJson = cartItem.toJson();
      final restoredItem = CartItem.fromJson(itemJson);

      expect(restoredItem.id, 'cart_1');
      expect(restoredItem.item.name, 'Burger Deluxe');
      expect(restoredItem.item.storeId, 'store_10');
      expect(restoredItem.quantity, 2);
      expect(restoredItem.selectedVariant, 'Medium Well');
      expect(restoredItem.selectedAddons.length, 1);
      expect(restoredItem.selectedAddons.first.name, 'Extra Cheese');
      expect(restoredItem.removedOptions, ['Pickles']);
      expect(restoredItem.specialInstructions, 'No onions please');
      expect(restoredItem.totalPrice, (250.0 + 30.0) * 2);

      final batch = CartBatch(
        propertyId: 'store_10',
        propertyName: 'Burger House',
        propertyImage: 'https://example.com/logo.jpg',
        items: [cartItem],
      );

      final batchJson = batch.toJson();
      final restoredBatch = CartBatch.fromJson(batchJson);

      expect(restoredBatch.propertyId, 'store_10');
      expect(restoredBatch.propertyName, 'Burger House');
      expect(restoredBatch.items.length, 1);
      expect(restoredBatch.totalQuantity, 2);
      expect(restoredBatch.subtotal, 560.0);
    });

    test('isDifferentProperty correctly detects cross-property items', () {
      final cart = CartController();
      expect(cart.isDifferentProperty(itemStoreA), isFalse);

      cart.addItem(item: itemStoreA, quantity: 1);
      expect(cart.activePropertyId, 'store_10');

      // Adding same store item is not different property
      final sameStoreItem = DeliveryItem(
        id: 'item_3',
        storeId: 'store_10',
        name: 'Fries',
        description: 'Crispy fries',
        price: 80.0,
        imageUrl: '',
        category: 'Sides',
      );
      expect(cart.isDifferentProperty(sameStoreItem), isFalse);

      // Adding different store item is detected as different property
      expect(cart.isDifferentProperty(itemStoreB), isTrue);
    });

    test('saveCurrentBatch archives active cart and clears active items', () {
      final cart = CartController();
      cart.addItem(item: itemStoreA, quantity: 2);
      expect(cart.items.length, 1);
      expect(cart.savedBatches.isEmpty, isTrue);

      cart.saveCurrentBatch(propertyName: 'Burger House');

      expect(cart.items.isEmpty, isTrue);
      expect(cart.savedBatches.length, 1);
      expect(cart.savedBatches.first.propertyId, 'store_10');
      expect(cart.savedBatches.first.propertyName, 'Burger House');
      expect(cart.savedBatches.first.items.first.item.id, 'item_1');
      expect(cart.savedBatches.first.totalQuantity, 2);
    });

    test('restoreBatch activates saved batch and archives different active batch', () {
      final cart = CartController();

      // Start with Store A batch
      cart.addItem(item: itemStoreA, quantity: 2);
      cart.saveCurrentBatch(propertyName: 'Burger House');

      // Now active has Store B
      cart.addItem(item: itemStoreB, quantity: 1);
      expect(cart.items.first.item.storeId, 'store_20');
      expect(cart.savedBatches.length, 1);

      // Restore Store A batch: Store B should be archived to saved batches, Store A becomes active
      final storeABatch = cart.savedBatches.first;
      cart.restoreBatch(storeABatch);

      expect(cart.items.first.item.storeId, 'store_10');
      expect(cart.items.first.quantity, 2);
      expect(cart.savedBatches.length, 1);
      expect(cart.savedBatches.first.propertyId, 'store_20');
    });

    test('saveCurrentBatchAndStartNew cleanly archives old batch and starts new batch', () {
      final cart = CartController();
      cart.addItem(item: itemStoreA, quantity: 2);

      cart.saveCurrentBatchAndStartNew(
        newItem: itemStoreB,
        quantity: 3,
      );

      // Active cart should now have itemStoreB with quantity 3
      expect(cart.items.length, 1);
      expect(cart.items.first.item.id, 'item_2');
      expect(cart.items.first.quantity, 3);
      expect(cart.activePropertyId, 'store_20');

      // Saved batches should contain store_10 with itemStoreA
      expect(cart.savedBatches.length, 1);
      expect(cart.savedBatches.first.propertyId, 'store_10');
      expect(cart.savedBatches.first.items.first.quantity, 2);
    });

    test('Cart batches and active items persist across simulated app reboot', () async {
      // 1. Session 1: User adds items, saves one batch, keeps one active
      final cart1 = CartController();
      cart1.addItem(item: itemStoreA, quantity: 2);
      cart1.saveCurrentBatch(propertyName: 'Burger House');
      cart1.addItem(item: itemStoreB, quantity: 1);

      // Wait for async persistence
      cart1.saveToLocalStorage();

      // Verify raw SharedPreferences contents
      final activeStored = ConfigPreference.getActiveCartJson();
      final batchesStored = ConfigPreference.getSavedCartBatchesJson();
      expect(activeStored, isNotNull);
      expect(batchesStored, isNotNull);

      final List<dynamic> activeDecoded = jsonDecode(activeStored!);
      final List<dynamic> batchesDecoded = jsonDecode(batchesStored!);
      expect(activeDecoded.length, 1);
      expect(batchesDecoded.length, 1);

      // 2. Session 2 (simulated app restart): Fresh CartController loads saved state
      final cart2 = CartController();
      cart2.loadFromLocalStorage();

      expect(cart2.items.length, 1);
      expect(cart2.items.first.item.id, 'item_2');
      expect(cart2.items.first.item.storeId, 'store_20');

      expect(cart2.savedBatches.length, 1);
      expect(cart2.savedBatches.first.propertyId, 'store_10');
      expect(cart2.savedBatches.first.propertyName, 'Burger House');
      expect(cart2.savedBatches.first.items.first.item.name, 'Burger Deluxe');
    });

    test('MyPropertyController.saveMenuItem requires description', () async {
      final propertyController = MyPropertyController();
      propertyController.selectedProperty.value = const MyPropertyModel(
        id: 1,
        name: 'Test Property',
        logo: '',
        coverImage: '',
        friendlyLocation: 'Bole',
        latitude: '9.0',
        longitude: '38.0',
        openingTime: '08:00',
        closingTime: '20:00',
        description: 'Test Property description',
        deliveryTime: '30 min',
        status: '1',
        typeName: 'Restaurant',
        categoryName: 'Food',
        deliveryTypeImage: '',
        deliveryCategoryImage: '',
      );

      // Empty description should return false and not proceed
      final resultEmpty = await propertyController.saveMenuItem(
        name: 'Item without desc',
        menuCategoryId: 1,
        price: 100.0,
        description: '',
      );
      expect(resultEmpty, isFalse);

      final resultWhitespace = await propertyController.saveMenuItem(
        name: 'Item with whitespace desc',
        menuCategoryId: 1,
        price: 100.0,
        description: '   ',
      );
      expect(resultWhitespace, isFalse);
    });
  });
}
