import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/controllers/cart_controller.dart';
import 'package:delivery_app/controllers/restaurant_controller.dart';
import 'package:delivery_app/services/user_location_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();
    DioConfig.isTestMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
  });

  tearDown(() {
    Get.reset();
    DioConfig.isTestMode = false;
  });

  group('UserLocationService Tests', () {
    test('loadCachedLocation loads cached coordinates from ConfigPreference', () async {
      await ConfigPreference.setUserLocation(9.0200, 38.7500);
      await ConfigPreference.setUserAddress('Bole, Addis Ababa');

      final service = UserLocationService();
      service.loadCachedLocation();
      expect(service.currentLatitude.value, 9.0200);
      expect(service.currentLongitude.value, 38.7500);
      expect(service.currentAddress.value, 'Bole, Addis Ababa');
    });

    test('updateLocation fetches position, persists to ConfigPreference and syncs with RestaurantController', () async {
      final restaurantController = Get.put(RestaurantController());
      final service = Get.put(UserLocationService());

      final pos = await service.updateLocation();
      expect(pos, isNotNull);
      expect(pos!.latitude, 9.0104);
      expect(pos.longitude, 38.7617);

      expect(service.currentLatitude.value, 9.0104);
      expect(service.currentLongitude.value, 38.7617);
      expect(service.currentAddress.value, contains('Addis Ababa'));

      // Check ConfigPreference persistence
      expect(ConfigPreference.getUserLatitude(), 9.0104);
      expect(ConfigPreference.getUserLongitude(), 38.7617);

      // Check RestaurantController sync
      expect(restaurantController.userLat.value, 9.0104);
      expect(restaurantController.userLng.value, 38.7617);
    });

    test('updateLocation syncs delivery address with CartController if empty', () async {
      final cartController = Get.put(CartController());
      expect(cartController.deliveryAddress.value, isEmpty);

      final service = Get.put(UserLocationService());
      await service.updateLocation();

      expect(cartController.deliveryAddress.value, contains('Addis Ababa'));
    });

    test('setCurrentCoordinates updates state, ConfigPreference, and RestaurantController', () async {
      final restaurantController = Get.put(RestaurantController());
      final service = Get.put(UserLocationService());

      await service.setCurrentCoordinates(8.9950, 38.7890);

      expect(service.currentLatitude.value, 8.9950);
      expect(service.currentLongitude.value, 38.7890);
      expect(ConfigPreference.getUserLatitude(), 8.9950);
      expect(ConfigPreference.getUserLongitude(), 38.7890);
      expect(restaurantController.userLat.value, 8.9950);
      expect(restaurantController.userLng.value, 38.7890);
    });

    test('handles AppLifecycleState.resumed without errors', () async {
      final service = Get.put(UserLocationService());
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(service.currentLatitude.value, isNotNull);
    });
  });
}
