import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/storage_config.dart';
import '../controllers/auth_controller.dart';
import '../models/courier_model.dart';
import '../models/property_delivery_option.dart';
import '../services/city_service.dart';
import '../services/courier_service.dart';
import '../services/gebeta_location_service.dart';
import '../services/order_notification_retry_service.dart';
import '../utils/api_call_status.dart';
import '../utils/location_utils.dart';
import '../widgets/map/property_location_picker_screen.dart';

class CourierController extends GetxController {
  static CourierController get to => Get.find<CourierController>();

  // State Observables
  final status = ApiCallStatus.holding.obs;
  final ordersLoading = false.obs;
  final isSubmitting = false.obs;

  // Active and past orders
  final activeOrders = <CourierOrderModel>[].obs;
  final pastOrders = <CourierOrderModel>[].obs;

  // Form State Observables (Map Selection)
  final pickupLatitude = Rxn<double>();
  final pickupLongitude = Rxn<double>();
  final pickupAddress = Rxn<String>();

  final dropoffLatitude = Rxn<double>();
  final dropoffLongitude = Rxn<double>();
  final dropoffAddress = Rxn<String>();

  // Delivery Options & Vehicle Selection
  final courierDeliveryOptions = <PropertyDeliveryOption>[].obs;
  final selectedDeliveryOption = Rxn<PropertyDeliveryOption>();
  final isLoadingDeliveryOptions = false.obs;

  // Payment Method Selection: 'cash' ('0'), 'chapa' ('1'), 'wallet' ('2')
  final selectedPaymentMethod = 'cash'.obs;

  // Pricing & Distance
  final calculatedDistanceKm = 0.0.obs;
  final startPrice = 0.0.obs;
  final kmPrice = 35.0.obs;
  final calculatedTotalPrice = 0.0.obs;
  final carTypeId = 1.obs;
  final carTypeName = 'Motorbike'.obs;

  int get currentUserId {
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      final uid = int.tryParse(auth.user.id);
      if (uid != null && uid > 0) return uid;
    }
    return ConfigPreference.getUserId() ?? 1;
  }

  bool get hasCoordinatesSelected =>
      pickupLatitude.value != null &&
      pickupLongitude.value != null &&
      dropoffLatitude.value != null &&
      dropoffLongitude.value != null;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
    loadCourierDeliveryOptions();
  }

  /// Load courier delivery options from backend: GET /courirer_delivery_option + GET /delivery-price-by-car-and-city-id
  Future<void> loadCourierDeliveryOptions({dynamic cityId}) async {
    isLoadingDeliveryOptions.value = true;
    try {
      final options = await CourierService.fetchCourierDeliveryOptions(
        cityId: cityId ?? CityService.defaultCityId,
      );
      if (options.isNotEmpty) {
        courierDeliveryOptions.assignAll(options);
        if (selectedDeliveryOption.value == null) {
          selectDeliveryOption(options.first);
        } else {
          final match = options.firstWhereOrNull(
            (o) => (o.id != null && o.id == selectedDeliveryOption.value?.id) ||
                o.name.toLowerCase() == selectedDeliveryOption.value?.name.toLowerCase(),
          );
          if (match != null) {
            selectDeliveryOption(match);
          }
        }
      } else if (courierDeliveryOptions.isEmpty) {
        _setDefaultDeliveryOptions();
      }
    } catch (_) {
      if (courierDeliveryOptions.isEmpty) {
        _setDefaultDeliveryOptions();
      }
    } finally {
      isLoadingDeliveryOptions.value = false;
    }
  }

  void _setDefaultDeliveryOptions() {
    final defaults = [
      const PropertyDeliveryOption(
        id: 1,
        image: '',
        name: 'Motorbike',
        kmPrice: 7.46,
        startPrice: 26.87,
      ),
      const PropertyDeliveryOption(
        id: 3,
        image: '',
        name: 'Car / Van',
        kmPrice: 13.99,
        startPrice: 24.14,
      ),
    ];
    courierDeliveryOptions.assignAll(defaults);
    if (selectedDeliveryOption.value == null) {
      selectDeliveryOption(defaults.first);
    }
  }

  void selectDeliveryOption(PropertyDeliveryOption option) {
    selectedDeliveryOption.value = option;
    startPrice.value = option.startPrice;
    kmPrice.value = option.kmPrice > 0 ? option.kmPrice : 35.0;
    carTypeName.value = option.name;
    final parsedId = int.tryParse(option.id?.toString() ?? '1') ?? 1;
    carTypeId.value = parsedId;
    _recalculateDistanceAndPrice();
  }

  void selectPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
  }

  /// Launch interactive Gebeta Map location picker screen for coordinate selection
  Future<bool> selectLocationOnMap({required bool isPickup}) async {
    final double initialLat = (isPickup ? pickupLatitude.value : dropoffLatitude.value) ??
        LocationUtils.defaultLatitude;
    final double initialLng = (isPickup ? pickupLongitude.value : dropoffLongitude.value) ??
        LocationUtils.defaultLongitude;
    final String? currentAddress = isPickup ? pickupAddress.value : dropoffAddress.value;

    final result = await Get.to<PropertyLocationResult>(
      () => PropertyLocationPickerScreen(
        title: isPickup ? 'Select Pick-up Location' : 'Select Drop-off Location',
        initialLatitude: initialLat,
        initialLongitude: initialLng,
        initialAddress: currentAddress,
      ),
    );

    if (result != null) {
      if (isPickup) {
        pickupLatitude.value = result.latitude;
        pickupLongitude.value = result.longitude;
        pickupAddress.value = result.address.isNotEmpty
            ? result.address
            : '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}';
      } else {
        dropoffLatitude.value = result.latitude;
        dropoffLongitude.value = result.longitude;
        dropoffAddress.value = result.address.isNotEmpty
            ? result.address
            : '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}';
      }

      _recalculateDistanceAndPrice();
      return true;
    }
    return false;
  }

  /// Set location programmatically (e.g. from GPS or saved address) with coordinates
  void setLocation({
    required bool isPickup,
    required double lat,
    required double lng,
    required String address,
  }) {
    if (isPickup) {
      pickupLatitude.value = lat;
      pickupLongitude.value = lng;
      pickupAddress.value = address;
    } else {
      dropoffLatitude.value = lat;
      dropoffLongitude.value = lng;
      dropoffAddress.value = address;
    }
    _recalculateDistanceAndPrice();
  }

  void _recalculateDistanceAndPrice() {
    if (pickupLatitude.value != null &&
        pickupLongitude.value != null &&
        dropoffLatitude.value != null &&
        dropoffLongitude.value != null) {
      final dist = LocationUtils.calculateDistanceInKm(
        lat1: pickupLatitude.value!,
        lon1: pickupLongitude.value!,
        lat2: dropoffLatitude.value!,
        lon2: dropoffLongitude.value!,
      );
      calculatedDistanceKm.value = double.parse(dist.toStringAsFixed(2));

      // Calculate total price using Formula A: start_price + (distance_km * km_price)
      final option = selectedDeliveryOption.value;
      if (option != null) {
        calculatedTotalPrice.value = option.calculateTotal(calculatedDistanceKm.value);
      } else {
        final rate = kmPrice.value > 0 ? kmPrice.value : 35.0;
        final base = startPrice.value;
        calculatedTotalPrice.value = (base + (calculatedDistanceKm.value * rate)).roundToDouble();
      }
    } else {
      calculatedDistanceKm.value = 0.0;
      calculatedTotalPrice.value = 0.0;
    }
  }

  /// Load active and past courier orders
  Future<void> loadOrders() async {
    final uid = currentUserId;
    ordersLoading.value = true;
    status.value = ApiCallStatus.loading;

    try {
      final results = await Future.wait([
        CourierService.fetchActiveOrders(uid),
        CourierService.fetchPastOrders(uid),
      ]);

      activeOrders.assignAll(results[0]);
      pastOrders.assignAll(results[1]);
      status.value = ApiCallStatus.success;
    } catch (_) {
      status.value = ApiCallStatus.error;
    } finally {
      ordersLoading.value = false;
    }
  }

  /// Place courier delivery order
  Future<bool> submitOrder({
    required String receiverName,
    required String receiverPhone,
    String? description,
    String paymentType = '0',
    Function(int? orderId)? onCreated,
  }) async {
    if (pickupLatitude.value == null || pickupLongitude.value == null) {
      Get.snackbar(
        'Pick-up Location Required',
        'Please select a pick-up coordinate on the map.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }

    if (dropoffLatitude.value == null || dropoffLongitude.value == null) {
      Get.snackbar(
        'Drop-off Location Required',
        'Please select a drop-off coordinate on the map.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }

    if (receiverName.trim().isEmpty) {
      Get.snackbar(
        'Receiver Name Required',
        'Please enter receiver name.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }

    if (receiverPhone.trim().isEmpty) {
      Get.snackbar(
        'Receiver Phone Required',
        'Please enter receiver phone number.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }

    isSubmitting.value = true;

    try {
      String fromFriendly = pickupAddress.value ?? '';
      if (fromFriendly.trim().isEmpty &&
          pickupLatitude.value != null &&
          pickupLongitude.value != null) {
        try {
          fromFriendly = await GebetaLocationService.reverseGeocode(
            pickupLatitude.value!,
            pickupLongitude.value!,
          );
        } catch (_) {}
      }

      String toFriendly = dropoffAddress.value ?? '';
      Map<String, dynamic>? toRawGeo;
      if (dropoffLatitude.value != null && dropoffLongitude.value != null) {
        try {
          final details = await GebetaLocationService.reverseGeocodeWithDetails(
            dropoffLatitude.value!,
            dropoffLongitude.value!,
          );
          if (toFriendly.trim().isEmpty) {
            toFriendly = details['address']?.toString() ?? '';
          }
          toRawGeo = details['raw'] as Map<String, dynamic>?;
        } catch (_) {}
      }

      int? dropoffCityId;
      try {
        dropoffCityId = await CityService.matchCityIdFromGeocode(
          toFriendly,
          rawGebetaResponse: toRawGeo,
        );
      } catch (_) {}

      final request = CourierOrderCreateRequest(
        fromLatitude: pickupLatitude.value!,
        fromLongitude: pickupLongitude.value!,
        toLatitude: dropoffLatitude.value!,
        toLongitude: dropoffLongitude.value!,
        senderUserId: currentUserId,
        receiverName: receiverName.trim(),
        receiverPhone: receiverPhone.trim(),
        carTypeId: carTypeId.value,
        kmPrice: kmPrice.value,
        totalPrice: calculatedTotalPrice.value > 0
            ? calculatedTotalPrice.value
            : 50.0,
        paymentType: paymentType,
        description: description,
        fromAddress: pickupAddress.value,
        toAddress: dropoffAddress.value,
        fromFriendlyLocation: fromFriendly,
        toFriendlyLocation: toFriendly,
        cityId: dropoffCityId,
      );

      final success = await CourierService.createCourierOrder(
        request,
        onSuccess: (data) {
          final idVal = data['order_id'] ?? data['id'] ?? (data['data'] is Map ? data['data']['id'] : null);
          final parsedId = idVal != null ? int.tryParse(idVal.toString()) : null;
          final finalId = parsedId ?? CourierService.lastCreatedOrderId;
          if (finalId != null && finalId > 0) {
            OrderNotificationRetryService.instance.trackCourierOrder(
              orderId: finalId,
              userId: request.senderUserId,
              amount: request.totalPrice,
              fromAddress: (request.fromFriendlyLocation != null &&
                      request.fromFriendlyLocation!.isNotEmpty)
                  ? request.fromFriendlyLocation!
                  : ((pickupAddress.value != null &&
                          pickupAddress.value!.isNotEmpty)
                      ? pickupAddress.value!
                      : 'Addis Ababa'),
              toAddress: (request.toFriendlyLocation != null &&
                      request.toFriendlyLocation!.isNotEmpty)
                  ? request.toFriendlyLocation!
                  : ((dropoffAddress.value != null &&
                          dropoffAddress.value!.isNotEmpty)
                      ? dropoffAddress.value!
                      : 'Addis Ababa'),
              cityId: dropoffCityId,
            );
          }
          onCreated?.call(parsedId);
        },
      );

      if (success) {
        // Reset coordinates & form
        clearSelection();
        // Refresh orders in background
        loadOrders();
        return true;
      } else {
        Get.snackbar(
          'Order Submission Failed',
          'Could not place courier order. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to connect to courier server: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void clearSelection() {
    pickupLatitude.value = null;
    pickupLongitude.value = null;
    pickupAddress.value = null;
    dropoffLatitude.value = null;
    dropoffLongitude.value = null;
    dropoffAddress.value = null;
    calculatedDistanceKm.value = 0.0;
    calculatedTotalPrice.value = 0.0;
  }
}
