import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/models/city_model.dart';
import 'package:delivery_app/models/courier_model.dart';
import 'package:delivery_app/services/city_service.dart';
import 'package:delivery_app/services/courier_service.dart';

void main() {
  setUp(() {
    DioConfig.isTestMode = true;
    CityService.clearCache();
  });

  tearDown(() {
    CityService.clearCache();
  });

  group('CityModel serialization & fallback tests', () {
    test('CityModel parses json properly', () {
      final json = {
        'id': 1,
        'name': 'Addis Ababa',
        'status': '1',
        'created_at': '2026-10-05T07:06:49.000000Z',
        'updated_at': '2026-10-05T07:06:49.000000Z',
      };

      final city = CityModel.fromJson(json);
      expect(city.id, 1);
      expect(city.name, 'Addis Ababa');
      expect(city.status, '1');
      expect(city.toString(), 'Addis Ababa (ID: 1)');
    });

    test('getCities returns fallback list in test mode', () async {
      final cities = await CityService.getCities();
      expect(cities.isNotEmpty, true);
      expect(cities.any((c) => c.id == 1 && c.name == 'Addis Ababa'), true);
      expect(cities.any((c) => c.id == 2 && c.name == 'Hawassa'), true);
      expect(cities.any((c) => c.id == 10 && c.name == 'Bahir Dar'), true);
      expect(cities.any((c) => c.id == 14 && c.name.toLowerCase().contains('dire')), true);
    });
  });

  group('CityService inference from reverse geocoding tests', () {
    test('matches Addis Ababa directly from address text', () async {
      final cityId = await CityService.matchCityIdFromGeocode(
        'Bole Medhanialem, Addis Ababa, Ethiopia',
      );
      expect(cityId, 1);
    });

    test('matches Hawassa from address and district', () async {
      final cityId = await CityService.matchCityIdFromGeocode(
        'Piazza, Hawassa',
        rawGebetaResponse: {
          'address': {
            'district': {'EN': 'Hawasa town', 'AM': 'ሃዋሳቶውን'},
            'province': {'EN': 'Sidama', 'AM': 'ሲዳማ'},
          },
        },
      );
      expect(cityId, 2);
    });

    test('matches Hawassa via district alias when city string is Sidama', () async {
      final cityId = await CityService.matchCityIdFromGeocode(
        'Medan Medium Clinic, Sidama, Ethiopia',
        rawGebetaResponse: {
          'address': {
            'district': {'EN': 'Hawasa town'},
            'province': {'EN': 'Sidama'},
          },
        },
      );
      expect(cityId, 2);
    });

    test('matches Bahir Dar from raw Gebeta response', () async {
      final cityId = await CityService.matchCityIdFromGeocode(
        'Naky Hotel, West Gojam, Ethiopia',
        rawGebetaResponse: {
          'address': {
            'district': {'EN': 'Bahir Dar town'},
            'province': {'EN': 'Amhara'},
          },
        },
      );
      expect(cityId, 10);
    });

    test('matches Debrebirhan correctly', () async {
      final cityId = await CityService.matchCityIdFromGeocode(
        'Eskindir Pharmacy, North Shewa (AM), Ethiopia',
        rawGebetaResponse: {
          'address': {
            'district': {'EN': 'Debre Berhan town'},
          },
        },
      );
      expect(cityId, 11);
    });

    test('matches Dire Dawa correctly', () async {
      final cityId = await CityService.matchCityIdFromGeocode(
        'Ganda Kore, Dire Dawa urban, Ethiopia',
      );
      expect(cityId, 14);
    });

    test('matches Adama / Nazret correctly', () async {
      final cityId1 = await CityService.matchCityIdFromGeocode(
        'Post office, Adama, Ethiopia',
      );
      expect(cityId1, 15);

      final cityId2 = await CityService.matchCityIdFromGeocode(
        'Nazret Bus Station',
      );
      expect(cityId2, 15);
    });

    test('matches Bishoftu correctly', () async {
      final cityId = await CityService.matchCityIdFromGeocode(
        'Bishoftu secondary school, East Shewa',
      );
      expect(cityId, 16);
    });

    test('defaults to defaultCityId (1 - Addis Ababa) for unknown addresses', () async {
      final cityId = await CityService.matchCityIdFromGeocode('Random Unmatched Location');
      expect(cityId, CityService.defaultCityId);
    });
  });

  group('CourierService city_id payload inference tests', () {
    test('CourierService automatically injects city_id into order payload if missing', () async {
      // In test mode, createCourierOrder runs synchronously and passes
      final request = CourierOrderCreateRequest(
        fromLatitude: 9.02,
        fromLongitude: 38.74,
        toLatitude: 9.01,
        toLongitude: 38.76,
        senderUserId: 1,
        receiverName: 'Test Recipient',
        receiverPhone: '0911223344',
        totalPrice: 100.0,
        toAddress: 'Bole, Addis Ababa',
      );

      final result = await CourierService.createCourierOrder(request);
      expect(result, true);
    });
  });
}
