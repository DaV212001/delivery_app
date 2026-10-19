import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../config/dio_config.dart';
import '../config/storage_config.dart';
import '../controllers/cart_controller.dart';
import '../controllers/restaurant_controller.dart';
import 'gebeta_location_service.dart';

class UserLocationService extends GetxService with WidgetsBindingObserver {
  static UserLocationService get to => Get.find<UserLocationService>();

  final currentPosition = Rxn<Position>();
  final currentLatitude = Rxn<double>();
  final currentLongitude = Rxn<double>();
  final currentAddress = ''.obs;

  final isUpdatingLocation = false.obs;
  final locationPermissionDenied = false.obs;
  final locationServiceDisabled = false.obs;

  static bool get isInTest =>
      Get.testMode || Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadCachedLocation();
    // Automatically update location when service initializes (app opens)
    updateLocation();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      updateLocation();
    }
  }

  /// Load cached location from persistent storage for immediate availability
  void loadCachedLocation() {
    try {
      final lat = ConfigPreference.getUserLatitude();
      final lng = ConfigPreference.getUserLongitude();
      final addr = ConfigPreference.getUserAddress();

      if (lat != null && lng != null) {
        currentLatitude.value = lat;
        currentLongitude.value = lng;
      }
      if (addr != null && addr.isNotEmpty) {
        currentAddress.value = addr;
      }
    } catch (_) {}
  }

  /// Set explicit coordinates (e.g. from tests or location picker)
  Future<void> setCurrentCoordinates(double lat, double lng) async {
    currentLatitude.value = lat;
    currentLongitude.value = lng;
    await ConfigPreference.setUserLocation(lat, lng);
    _syncWithActiveControllers(lat, lng);
  }

  bool _isRequesting = false;

  /// Always updates the user's location via GPS and reverse-geocoding,
  /// persisting coordinates and address and updating all controllers.
  Future<Position?> updateLocation({bool promptIfDeniedForever = false}) async {
    if (DioConfig.isTestMode || isInTest) {
      const testLat = 9.0104;
      const testLng = 38.7617;
      final testPos = Position(
        latitude: testLat,
        longitude: testLng,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 2355.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
      await _onPositionObtained(testPos, saveAddress: true);
      return testPos;
    }

    if (_isRequesting) return currentPosition.value;
    _isRequesting = true;
    isUpdatingLocation.value = true;

    try {
      // 1. Quick lock with last known position if no coordinates yet
      if (currentLatitude.value == null || currentLongitude.value == null) {
        try {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            await _onPositionObtained(lastKnown, saveAddress: false);
          }
        } catch (_) {}
      }

      // 2. Fetch fresh high-accuracy position from GebetaLocationService
      final freshPos = await GebetaLocationService.getCurrentPosition(
        promptIfDeniedForever: promptIfDeniedForever,
      );

      if (freshPos != null) {
        await _onPositionObtained(freshPos, saveAddress: true);
        locationPermissionDenied.value = false;
        locationServiceDisabled.value = false;
        return freshPos;
      } else {
        final recheckService = await Geolocator.isLocationServiceEnabled();
        locationServiceDisabled.value = !recheckService;

        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          locationPermissionDenied.value = true;
        } else {
          locationPermissionDenied.value = false;
        }

        _syncFlagsWithControllers();
        return null;
      }
    } catch (_) {
      locationPermissionDenied.value = true;
      _syncFlagsWithControllers();
      return null;
    } finally {
      isUpdatingLocation.value = false;
      _isRequesting = false;
    }
  }

  Future<void> _onPositionObtained(Position pos, {required bool saveAddress}) async {
    currentPosition.value = pos;
    currentLatitude.value = pos.latitude;
    currentLongitude.value = pos.longitude;

    // Persist coordinates
    await ConfigPreference.setUserLocation(pos.latitude, pos.longitude);

    // Sync to active controllers
    _syncWithActiveControllers(pos.latitude, pos.longitude);

    // Reverse geocode to readable address
    if (saveAddress) {
      try {
        String addr = 'Meskel Square, Addis Ababa';
        if (!DioConfig.isTestMode && !isInTest) {
          final resolved = await GebetaLocationService.reverseGeocode(
            pos.latitude,
            pos.longitude,
          );
          if (resolved.isNotEmpty) {
            addr = resolved;
          }
        }
        currentAddress.value = addr;
        await ConfigPreference.setUserAddress(addr);

        // Update cart delivery address if empty
        if (Get.isRegistered<CartController>()) {
          final cart = Get.find<CartController>();
          if (cart.deliveryAddress.value.isEmpty) {
            cart.deliveryAddress.value = addr;
          }
        }
      } catch (_) {}
    }
  }

  void _syncWithActiveControllers(double lat, double lng) {
    if (Get.isRegistered<RestaurantController>()) {
      final rc = Get.find<RestaurantController>();
      rc.userLat.value = lat;
      rc.userLng.value = lng;
      rc.locationPermissionDenied.value = false;
      rc.locationServiceDisabled.value = false;
      rc.recalculateStoreDistances();
    }
  }

  void _syncFlagsWithControllers() {
    if (Get.isRegistered<RestaurantController>()) {
      final rc = Get.find<RestaurantController>();
      rc.locationPermissionDenied.value = locationPermissionDenied.value;
      rc.locationServiceDisabled.value = locationServiceDisabled.value;
    }
  }
}
