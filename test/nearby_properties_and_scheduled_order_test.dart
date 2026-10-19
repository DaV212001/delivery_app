import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/models/today_schedule.dart';
import 'package:delivery_app/models/paginated_properties.dart';
import 'package:delivery_app/models/saved_order.dart';
import 'package:delivery_app/models/store.dart';
import 'package:delivery_app/services/saved_order_service.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();
  });

  group('TodaySchedule Model Tests', () {
    test('parses json correctly and handles string/bool flags', () {
      final s1 = TodaySchedule.fromJson({
        'is_closed': false,
        'open_time': '08:30',
        'close_time': '17:30',
      });
      expect(s1.isClosed, false);
      expect(s1.openTime, '08:30');
      expect(s1.closeTime, '17:30');
      expect(s1.formattedOpenTime, '8:30 AM');
      expect(s1.formattedCloseTime, '5:30 PM');

      final s2 = TodaySchedule.fromJson({
        'is_closed': '1',
        'open_time': null,
        'close_time': null,
      });
      expect(s2.isClosed, true);
      expect(s2.isOpenNow, false);
    });

    test('calculates nextOpenDateTime for closed store', () {
      final schedule = TodaySchedule(
        isClosed: true,
        openTime: '09:00',
        closeTime: '18:00',
      );
      final next = schedule.nextOpenDateTime;
      expect(next.hour, 9);
      expect(next.minute, 0);
      expect(next.isAfter(DateTime.now()), true);
    });
  });

  group('Store with TodaySchedule Tests', () {
    test('parses today_schedule from json and derives isPastClosingTime', () {
      final storeJson = {
        'id': 3,
        'property_name': 'Dr Tyre',
        'latitude': '9.1604',
        'longitude': '38.724747',
        'delviery_time': '1 Hour',
        'today_schedule': {
          'is_closed': true,
          'open_time': '08:30',
          'close_time': '17:30',
        },
      };

      final store = Store.fromJson(storeJson);
      expect(store.id, '3');
      expect(store.name, 'Dr Tyre');
      expect(store.todaySchedule, isNotNull);
      expect(store.todaySchedule!.isClosed, true);
      expect(store.isPastClosingTime, true);
      expect(store.isCurrentlyOpen, false);
    });

    test('Store open status message formats cleanly', () {
      final storeOpen = Store(
        id: '1',
        name: 'Test Store',
        categoryDescription: 'Food',
        priceLevel: '\$\$',
        rating: 4.8,
        reviewsCount: 10,
        deliveryTime: '20 min',
        deliveryFee: 'Free',
        minOrder: 100,
        distanceKm: 2.0,
        heroImageUrl: '',
        todaySchedule: const TodaySchedule(
          isClosed: false,
          openTime: '00:00',
          closeTime: '23:59',
        ),
      );
      expect(storeOpen.isCurrentlyOpen, true);
      expect(storeOpen.openStatusText.contains('11:59 PM') || storeOpen.openStatusText.contains('open'), true);
    });
  });

  group('PaginatedProperties Model Tests', () {
    test('parses paginated nearby property endpoint response', () {
      final paginatedJson = {
        'current_page': 1,
        'last_page': 4,
        'per_page': 15,
        'total': 46,
        'next_page_url': 'https://api.amnplc.com/api/nearby-property/9.0/38.7?page=2',
        'data': [
          {
            'id': 3,
            'property_name': 'Dr Tyre',
            'latitude': '9.1604',
            'longitude': '38.724747',
            'delviery_time': '1 Hour',
            'today_schedule': {
              'is_closed': false,
              'open_time': '08:30',
              'close_time': '17:30',
            },
          },
          {
            'id': 9,
            'property_name': 'TRACTOR SPARE PARTS',
            'latitude': '9.0038',
            'longitude': '38.8385',
            'today_schedule': {
              'is_closed': false,
              'open_time': null,
              'close_time': null,
            },
          }
        ],
      };

      final result = PaginatedProperties.fromJson(paginatedJson);
      expect(result.currentPage, 1);
      expect(result.lastPage, 4);
      expect(result.total, 46);
      expect(result.hasMore, true);
      expect(result.properties.length, 2);
      expect(result.properties[0].name, 'Dr Tyre');
      expect(result.properties[1].name, 'TRACTOR SPARE PARTS');
    });
  });

  group('SavedOrder & SavedOrderService Tests', () {
    test('serializes and deserializes SavedOrder correctly', () {
      final order = SavedOrder(
        id: 'saved_123',
        storeId: '3',
        storeName: 'Dr Tyre',
        storeImageUrl: 'https://example.com/logo.png',
        openTime: '08:30',
        scheduledOpenDateTime: DateTime.now().add(const Duration(hours: 2)),
        createdAt: DateTime.now(),
        deliveryAddress: 'Bole Road, Addis Ababa',
        paymentType: '0',
        menuIds: [101, 102],
        quantities: [2, 1],
        prices: [150.0, 250.0],
        subtotal: 550.0,
        totalKmPrice: 130.0,
        total: 680.0,
        deliveryOption: 1,
        kmPrice: 13.0,
        customerLatitude: 9.0320,
        customerLongitude: 38.7469,
        propertyLatitude: 9.1604,
        propertyLongitude: 38.7247,
        itemNames: ['Tire A', 'Tire B'],
      );

      final jsonStr = order.toJsonString();
      final parsed = SavedOrder.fromJsonString(jsonStr);

      expect(parsed.id, 'saved_123');
      expect(parsed.storeName, 'Dr Tyre');
      expect(parsed.subtotal, 550.0);
      expect(parsed.total, 680.0);
      expect(parsed.menuIds, [101, 102]);
      expect(parsed.quantities, [2, 1]);
      expect(parsed.itemNames, ['Tire A', 'Tire B']);
      expect(parsed.status, 'pending');
      expect(parsed.isDue, false);
    });

    test('SavedOrderService saves, retrieves, and cancels orders', () async {
      final order = SavedOrder(
        id: 'saved_456',
        storeId: '5',
        storeName: 'Pharmacy Plus',
        storeImageUrl: '',
        openTime: '08:00',
        scheduledOpenDateTime: DateTime.now().add(const Duration(minutes: 30)),
        createdAt: DateTime.now(),
        deliveryAddress: 'Megenagna',
        paymentType: '2',
        menuIds: [10],
        quantities: [1],
        prices: [200.0],
        subtotal: 200.0,
        totalKmPrice: 50.0,
        total: 250.0,
        customerLatitude: 9.0,
        customerLongitude: 38.7,
        propertyLatitude: 9.0,
        propertyLongitude: 38.7,
      );

      await SavedOrderService.saveOrder(order);
      var list = SavedOrderService.getSavedOrders();
      expect(list.length, 1);
      expect(list.first.storeName, 'Pharmacy Plus');

      await SavedOrderService.cancelOrder('saved_456');
      list = SavedOrderService.getSavedOrders();
      expect(list.first.status, 'cancelled');

      await SavedOrderService.removeOrder('saved_456');
      list = SavedOrderService.getSavedOrders();
      expect(list.isEmpty, true);
    });
  });
}
