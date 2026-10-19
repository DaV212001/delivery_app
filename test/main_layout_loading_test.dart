import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/controllers/auth_controller.dart';
import 'package:delivery_app/controllers/cart_controller.dart';
import 'package:delivery_app/controllers/order_controller.dart';
import 'package:delivery_app/controllers/profile_controller.dart';
import 'package:delivery_app/controllers/restaurant_controller.dart';
import 'package:delivery_app/screens/main_navigation.dart';

import 'package:delivery_app/bindings/initial_binding.dart';
import 'package:delivery_app/controllers/corporate_controller.dart';
import 'package:delivery_app/controllers/courier_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    DioConfig.isTestMode = true;
    DioConfig.resetDio();
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('Main Layout & Controller onInit Lifecycle Tests', () {
    test('InitialBinding registers domain controllers lazily without eager initialization', () {
      InitialBinding().dependencies();

      // Core global controllers are registered and initialized
      expect(Get.isRegistered<AuthController>(), isTrue);
      expect(Get.isPrepared<AuthController>(), isFalse);
      expect(Get.isRegistered<CartController>(), isTrue);
      expect(Get.isPrepared<CartController>(), isFalse);

      // Domain controllers are registered lazily (isPrepared == true means NOT yet initialized)
      expect(Get.isRegistered<RestaurantController>(), isTrue);
      expect(Get.isPrepared<RestaurantController>(), isTrue);

      expect(Get.isRegistered<OrderController>(), isTrue);
      expect(Get.isPrepared<OrderController>(), isTrue);

      expect(Get.isRegistered<ProfileController>(), isTrue);
      expect(Get.isPrepared<ProfileController>(), isTrue);

      expect(Get.isRegistered<CourierController>(), isTrue);
      expect(Get.isPrepared<CourierController>(), isTrue);

      expect(Get.isRegistered<CorporateController>(), isTrue);
      expect(Get.isPrepared<CorporateController>(), isTrue);
    });

    test('Domain controllers run onInit and make network requests ONLY when resolved on their screens', () async {
      await ConfigPreference.setUserId(42);
      await ConfigPreference.updateTokens('test_token', 'test_refresh', 3600);
      InitialBinding().dependencies();

      // 1. Initially, OrderController is not initialized
      expect(Get.isPrepared<OrderController>(), isTrue);

      // 2. When Orders screen needs OrderController, resolving it triggers onInit()
      final orderController = Get.find<OrderController>();
      expect(Get.isPrepared<OrderController>(), isFalse);
      // In test mode, onInit loaded mock orders
      expect(orderController.pastOrders.isNotEmpty, isTrue);

      // 3. ProfileController was untouched
      expect(Get.isPrepared<ProfileController>(), isTrue);
      final profileController = Get.find<ProfileController>();
      expect(Get.isPrepared<ProfileController>(), isFalse);
      // In test mode, onInit loaded profile data
      expect(profileController.status.value, isNotNull);

      // 4. CourierController was untouched until Courier screen opens
      expect(Get.isPrepared<CourierController>(), isTrue);
      final courierController = Get.find<CourierController>();
      expect(Get.isPrepared<CourierController>(), isFalse);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(courierController.activeOrders.isNotEmpty, isTrue);
    });

    test('MainNavigationController tracks visited tabs lazily without eager network loading', () {
      final nav = Get.put(MainNavigationController());

      // Only tab 0 is visited initially
      expect(nav.currentIndex.value, 0);
      expect(nav.isTabVisited(0), isTrue);
      expect(nav.isTabVisited(1), isFalse);
      expect(nav.isTabVisited(2), isFalse);
      expect(nav.isTabVisited(3), isFalse);

      // Navigate to Orders (tab 2)
      nav.changePage(2);
      expect(nav.currentIndex.value, 2);
      expect(nav.isTabVisited(2), isTrue);
      expect(nav.isTabVisited(3), isFalse);

      // Navigate to Profile (tab 3)
      nav.changePage(3);
      expect(nav.currentIndex.value, 3);
      expect(nav.isTabVisited(3), isTrue);
    });

    test('AuthController logout clears only active controllers without instantiating idle ones', () async {
      await ConfigPreference.setUserId(42);
      await ConfigPreference.updateTokens('test_token', 'test_refresh', 3600);
      InitialBinding().dependencies();

      final auth = Get.find<AuthController>();

      // Only resolve CartController and OrderController; leave ProfileController idle
      final cart = Get.find<CartController>();
      final orders = Get.find<OrderController>();
      expect(Get.isPrepared<ProfileController>(), isTrue);

      await auth.logout();

      expect(auth.isLoggedIn, isFalse);
      expect(orders.activeOrder.value, isNull);
      expect(orders.pastOrders.isEmpty, isTrue);
      expect(cart.items.isEmpty, isTrue);

      // ProfileController should still be uninstantiated!
      expect(Get.isPrepared<ProfileController>(), isTrue);
    });
  });
}
