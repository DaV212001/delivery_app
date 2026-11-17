import '../config/dio_config.dart';
import '../constants/api_endpoints.dart';
import '../models/delivery_price_rate.dart';
import '../models/property_delivery_option.dart';
import '../utils/templates/dio_template.dart';
import 'city_service.dart';

class DeliveryPricingService {
  /// Cache of rates keyed by "$vehicleId-$cityId"
  static final Map<String, DeliveryPriceRate> _cache = {};

  /// Fallback cached rates for known vehicle types and Addis Ababa (city 1)
  static final Map<String, DeliveryPriceRate> _fallbackRates = {
    // MoterBick (vehicle_id: 1, city_id: 1)
    '1-1': const DeliveryPriceRate(
      id: 1,
      cityId: 1,
      currencyId: 1,
      carTypeId: 1,
      propertyStartPrice: 136.57,
      propertyKmPrice: 17.08,
      courierStartPrice: 26.87,
      courierKmPrice: 7.46,
      pickupStartPrice: 168.66,
      pickupKmPrice: 23.21,
    ),
    // Bajaj (vehicle_id: 2, city_id: 1)
    '2-1': const DeliveryPriceRate(
      id: 2,
      cityId: 1,
      currencyId: 1,
      carTypeId: 2,
      propertyStartPrice: 57.11,
      propertyKmPrice: 5.81,
      courierStartPrice: 26.55,
      courierKmPrice: 6.55,
      pickupStartPrice: 292.75,
      pickupKmPrice: 18.94,
    ),
    // Car (vehicle_id: 3, city_id: 1)
    '3-1': const DeliveryPriceRate(
      id: 3,
      cityId: 1,
      currencyId: 1,
      carTypeId: 3,
      propertyStartPrice: 97.43,
      propertyKmPrice: 18.25,
      courierStartPrice: 24.14,
      courierKmPrice: 13.99,
      pickupStartPrice: 169.92,
      pickupKmPrice: 10.9,
    ),
    // Isuzu truck (vehicle_id: 5, city_id: 1)
    '5-1': const DeliveryPriceRate(
      id: 4,
      cityId: 1,
      currencyId: 1,
      carTypeId: 5,
      propertyStartPrice: 105.06,
      propertyKmPrice: 16.57,
      courierStartPrice: 43.73,
      courierKmPrice: 6.2,
      pickupStartPrice: 163.12,
      pickupKmPrice: 34.21,
    ),
    // ISUZU (vehicle_id: 6, city_id: 1)
    '6-1': const DeliveryPriceRate(
      id: 5,
      cityId: 1,
      currencyId: 1,
      carTypeId: 6,
      propertyStartPrice: 125.45,
      propertyKmPrice: 17.71,
      courierStartPrice: 79.51,
      courierKmPrice: 9.07,
      pickupStartPrice: 195.62,
      pickupKmPrice: 10.21,
    ),
    // PICK UP (vehicle_id: 7, city_id: 1)
    '7-1': const DeliveryPriceRate(
      id: 6,
      cityId: 1,
      currencyId: 1,
      carTypeId: 7,
      propertyStartPrice: 142.94,
      propertyKmPrice: 7.82,
      courierStartPrice: 77.29,
      courierKmPrice: 4.41,
      pickupStartPrice: 231.06,
      pickupKmPrice: 30.02,
    ),
    // LOWBED (vehicle_id: 8, city_id: 1)
    '8-1': const DeliveryPriceRate(
      id: 7,
      cityId: 1,
      currencyId: 1,
      carTypeId: 8,
      propertyStartPrice: 84.64,
      propertyKmPrice: 6.75,
      courierStartPrice: 48.87,
      courierKmPrice: 3.07,
      pickupStartPrice: 285.53,
      pickupKmPrice: 21.43,
    ),
  };

  /// Preload / seed cache with fallback rates
  static void seedCache(Map<String, DeliveryPriceRate> rates) {
    _cache.addAll(rates);
  }

  /// Clear the cache
  static void clearCache() {
    _cache.clear();
  }

  /// Get cached rate synchronously if present
  static DeliveryPriceRate? getCachedRate(dynamic vehicleId, dynamic cityId) {
    final vId = int.tryParse(vehicleId?.toString() ?? '1') ?? 1;
    final cId = int.tryParse(cityId?.toString() ?? '1') ?? CityService.defaultCityId;
    return _cache['$vId-$cId'] ?? _fallbackRates['$vId-$cId'];
  }

  /// Fetch price rate by vehicle_id and city_id:
  /// GET /delivery-price-by-car-and-city-id/{vehicle_id}/{city_id}
  static Future<DeliveryPriceRate?> fetchPriceRate({
    required dynamic vehicleId,
    dynamic cityId = CityService.defaultCityId,
  }) async {
    final vId = int.tryParse(vehicleId?.toString() ?? '1') ?? 1;
    final cId = int.tryParse(cityId?.toString() ?? '1') ?? CityService.defaultCityId;
    final key = '$vId-$cId';

    if (DioConfig.isTestMode && _cache.containsKey(key)) {
      return _cache[key];
    }
    if (DioConfig.isTestMode && _fallbackRates.containsKey(key)) {
      return _fallbackRates[key];
    }

    try {
      DeliveryPriceRate? result;
      await DioService.dioGet(
        path: ApiEndpoints.deliveryPriceByCarAndCity(vId, cId),
        onSuccess: (response) {
          final data = response.data;
          final raw = data is Map ? (data['data'] ?? data) : data;
          if (raw is List && raw.isNotEmpty && raw.first is Map) {
            result = DeliveryPriceRate.fromJson(Map<String, dynamic>.from(raw.first as Map));
          } else if (raw is Map) {
            result = DeliveryPriceRate.fromJson(Map<String, dynamic>.from(raw));
          }
        },
        onFailure: (error, response) {
          // Will fall back to cached / seeded rates below
        },
      );

      if (result != null) {
        _cache[key] = result!;
        return result;
      }
    } catch (_) {}

    // Fall back to memory cache or fallback rate
    return _cache[key] ?? _fallbackRates[key] ?? _fallbackRates['1-1'];
  }

  /// Resolves the price rate and updates the PropertyDeliveryOption's startPrice and kmPrice
  /// based on whether it is for 'property' or 'courier'.
  static Future<PropertyDeliveryOption> resolveDeliveryOptionPrice({
    required PropertyDeliveryOption option,
    required dynamic cityId,
    bool isCourier = false,
  }) async {
    final vehicleId = option.id ?? 1;
    final rate = await fetchPriceRate(vehicleId: vehicleId, cityId: cityId);

    if (rate != null) {
      if (isCourier) {
        return option.copyWith(
          startPrice: rate.courierStartPrice,
          kmPrice: rate.courierKmPrice,
        );
      } else {
        return option.copyWith(
          startPrice: rate.propertyStartPrice,
          kmPrice: rate.propertyKmPrice,
        );
      }
    }

    return option;
  }
}
