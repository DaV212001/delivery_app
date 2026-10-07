import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/controllers/restaurant_controller.dart';
import 'package:delivery_app/data/mock_data.dart';
import 'package:delivery_app/utils/location_utils.dart';

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

  group('LocationUtils and Store Distance Calculations', () {
    test('calculateDistanceInKm calculates accurate Haversine distance', () {
      // Meskel Square (9.0104, 38.7617) to Bole Medhanialem (8.9950, 38.7890)
      final distance = LocationUtils.calculateDistanceInKm(
        lat1: 9.0104,
        lon1: 38.7617,
        lat2: 8.9950,
        lon2: 38.7890,
      );

      // Distance should be approximately 3.48 km
      expect(distance, closeTo(3.48, 0.2));
    });

    test('formatDistanceBadge formats meters and kilometers cleanly', () {
      expect(LocationUtils.formatDistanceBadge(0.450), 'Around 450m');
      expect(LocationUtils.formatDistanceBadge(1.83), 'Around 1.8km');
    });

    test('Store calculateDistanceTo returns distance from user coordinates', () {
      final store = MockData.restaurants.firstWhere(
        (s) => s.id == 'rest_chanoly_olympia',
      );
      expect(store.latitude, isNotNull);
      expect(store.longitude, isNotNull);

      // Calculate distance from nearby location (9.0100, 38.7700)
      final dist = store.calculateDistanceTo(userLat: 9.0100, userLng: 38.7700);
      expect(dist, isNotNull);
      expect(dist!, closeTo(0.63, 0.15));
    });

    test('Store calculateDistanceTo returns null if coordinates are not provided', () {
      final store = MockData.restaurants.firstWhere(
        (s) => s.id == 'rest_chanoly_olympia',
      );
      final dist = store.calculateDistanceTo();
      expect(dist, isNull);
    });

    test('formattedDistanceBadgeTo falls back to default badge if user coordinates missing', () {
      final store = MockData.restaurants.firstWhere(
        (s) => s.id == 'rest_chanoly_olympia',
      );
      final badge = store.formattedDistanceBadgeTo();
      expect(badge, store.formattedDistanceBadge);
    });
  });

  group('RestaurantController Dynamic Distance & Sorting from Current Location', () {
    test('updateUserLocation re-calculates all store distances dynamically', () {
      final controller = Get.put(RestaurantController());

      // Initial store distances are mock distances
      final initialChanoly = controller.restaurants.firstWhere(
        (s) => s.id == 'rest_chanoly_olympia',
      );
      expect(initialChanoly.distanceKm, 1.0);

      // Simulate user current GPS location at Summit/Bole (9.0200, 38.8600)
      controller.updateUserLocation(9.0200, 38.8600);

      final updatedChanoly = controller.restaurants.firstWhere(
        (s) => s.id == 'rest_chanoly_olympia',
      );
      // Distance from Summit (38.86) to Olympia (38.7667) is ~10.3 km
      expect(updatedChanoly.distanceKm, closeTo(10.3, 0.5));
    });

    test('fastest sort orders restaurants by proximity to user current location', () {
      final controller = Get.put(RestaurantController());

      // Set user's current GPS location right next to Stadium (9.0120, 38.7540)
      controller.updateUserLocation(9.0120, 38.7540);

      // Select fastest sort
      controller.sortBy.value = 'fastest';

      final sorted = controller.filteredRestaurants;
      expect(sorted.isNotEmpty, isTrue);

      // The closest store to Stadium should be Express Parcel Courier (Stadium)
      expect(sorted.first.id, 'store_express_courier');
      expect(sorted.first.distanceKm, closeTo(0.0, 0.1));
    });

    test('recalculateStoreDistances updates when moving to a different location', () {
      final controller = Get.put(RestaurantController());

      // Move user to Bole Medhanialem (8.9950, 38.7890)
      controller.updateUserLocation(8.9950, 38.7890);
      controller.sortBy.value = 'fastest';

      final sorted = controller.filteredRestaurants;
      // FreshMart Organics is at Bole Medhanialem
      expect(sorted.first.id, 'store_freshmart');
      expect(sorted.first.distanceKm, closeTo(0.0, 0.1));
    });

    test('RestaurantController implements WidgetsBindingObserver and handles resumed lifecycle', () {
      final controller = Get.put(RestaurantController());
      expect(controller, isA<WidgetsBindingObserver>());

      // Verify didChangeAppLifecycleState triggers without crashing
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(controller.restaurants.isNotEmpty, isTrue);
    });
  });
}
