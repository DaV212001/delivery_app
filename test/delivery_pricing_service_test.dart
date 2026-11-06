import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/constants/api_endpoints.dart';
import 'package:delivery_app/models/delivery_price_rate.dart';
import 'package:delivery_app/models/property_delivery_option.dart';
import 'package:delivery_app/services/delivery_pricing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DioConfig.isTestMode = true;
    DioConfig.resetDio();
    DeliveryPricingService.clearCache();
  });

  tearDown(() {
    DioConfig.resetDio();
    DeliveryPricingService.clearCache();
  });

  group('DeliveryPriceRate Model Tests', () {
    test('fromJson parses exact backend payload accurately', () {
      final json = {
        'id': 1,
        'city_id': '1',
        'currency_id': '1',
        'car_type_id': '1',
        'property_start_price': '136.57',
        'property_km_price': '17.08',
        'courirer_start_price': '26.87',
        'courirer_km_price': '7.46',
        'pickup_start_price': '168.66',
        'pickup_km_price': '23.21',
        'created_at': '2026-10-05T10:00:00.000000Z',
        'updated_at': '2026-10-05T10:00:00.000000Z',
      };

      final rate = DeliveryPriceRate.fromJson(json);

      expect(rate.id, 1);
      expect(rate.cityId, 1);
      expect(rate.currencyId, 1);
      expect(rate.carTypeId, 1);
      expect(rate.propertyStartPrice, 136.57);
      expect(rate.propertyKmPrice, 17.08);
      expect(rate.courierStartPrice, 26.87);
      expect(rate.courierKmPrice, 7.46);
      expect(rate.pickupStartPrice, 168.66);
      expect(rate.pickupKmPrice, 23.21);
    });

    test('Formula A calculations compute start_price + (km * dist) with 2 decimals', () {
      const rate = DeliveryPriceRate(
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
      );

      // Property: 136.57 + (5.0 * 17.08) = 136.57 + 85.4 = 221.97
      expect(rate.calculatePropertyPrice(5.0), 221.97);

      // Courier: 26.87 + (5.0 * 7.46) = 26.87 + 37.3 = 64.17
      expect(rate.calculateCourierPrice(5.0), 64.17);

      // Zero distance returns start price
      expect(rate.calculatePropertyPrice(0.0), 136.57);
      expect(rate.calculateCourierPrice(0.0), 26.87);
    });
  });

  group('DeliveryPricingService Tests', () {
    test('fetchPriceRate returns live data when backend succeeds and caches it', () async {
      final dio = await DioConfig.dio();
      final dioAdapter = DioAdapter(dio: dio);

      dioAdapter.onGet(
        ApiEndpoints.deliveryPriceByCarAndCity(1, 1),
        (server) => server.reply(200, {
          'message': 'Delviery price by Car id List successfully',
          'data': [
            {
              'id': 1,
              'city_id': '1',
              'currency_id': '1',
              'car_type_id': '1',
              'property_start_price': '136.57',
              'property_km_price': '17.08',
              'courirer_start_price': '26.87',
              'courirer_km_price': '7.46',
              'pickup_start_price': '168.66',
              'pickup_km_price': '23.21',
            }
          ]
        }),
      );

      final rate = await DeliveryPricingService.fetchPriceRate(vehicleId: 1, cityId: 1);
      expect(rate, isNotNull);
      expect(rate!.propertyStartPrice, 136.57);
      expect(rate.courierStartPrice, 26.87);

      // Cache lookup should now return it without network
      final cached = DeliveryPricingService.getCachedRate(1, 1);
      expect(cached, isNotNull);
      expect(cached!.courierKmPrice, 7.46);
    });

    test('fetchPriceRate falls back to cached rates when endpoint returns 404/500 or empty', () async {
      final dio = await DioConfig.dio();
      final dioAdapter = DioAdapter(dio: dio);

      dioAdapter.onGet(
        ApiEndpoints.deliveryPriceByCarAndCity(2, 1),
        (server) => server.reply(500, {'error': 'Internal server error'}),
      );

      // Vehicle 2 (Bajaj) in Addis Ababa (city 1) has fallback rate
      final rate = await DeliveryPricingService.fetchPriceRate(vehicleId: 2, cityId: 1);
      expect(rate, isNotNull);
      expect(rate!.carTypeId, 2);
      expect(rate.propertyStartPrice, 57.11);
      expect(rate.courierStartPrice, 26.55);
    });

    test('resolveDeliveryOptionPrice applies Formula A pricing for property and courier', () async {
      final dio = await DioConfig.dio();
      final dioAdapter = DioAdapter(dio: dio);

      dioAdapter.onGet(
        ApiEndpoints.deliveryPriceByCarAndCity(1, 1),
        (server) => server.reply(200, {
          'message': 'Delviery price by Car id List successfully',
          'data': [
            {
              'id': 1,
              'city_id': '1',
              'currency_id': '1',
              'car_type_id': '1',
              'property_start_price': '136.57',
              'property_km_price': '17.08',
              'courirer_start_price': '26.87',
              'courirer_km_price': '7.46',
              'pickup_start_price': '168.66',
              'pickup_km_price': '23.21',
            }
          ]
        }),
      );

      const baseOption = PropertyDeliveryOption(
        id: 1,
        image: 'https://example.com/bike.png',
        name: 'MoterBick',
        kmPrice: 999.0, // old stale price
      );

      // Property flow
      final propertyOpt = await DeliveryPricingService.resolveDeliveryOptionPrice(
        option: baseOption,
        cityId: 1,
        isCourier: false,
      );
      expect(propertyOpt.startPrice, 136.57);
      expect(propertyOpt.kmPrice, 17.08);
      expect(propertyOpt.calculateTotal(10.0), 307.37);

      // Courier flow
      final courierOpt = await DeliveryPricingService.resolveDeliveryOptionPrice(
        option: baseOption,
        cityId: 1,
        isCourier: true,
      );
      expect(courierOpt.startPrice, 26.87);
      expect(courierOpt.kmPrice, 7.46);
      expect(courierOpt.calculateTotal(10.0), 101.47);
    });
  });
}
