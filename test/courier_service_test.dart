import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/constants/api_endpoints.dart';
import 'package:delivery_app/controllers/courier_controller.dart';
import 'package:delivery_app/models/courier_model.dart';
import 'package:delivery_app/models/property_delivery_option.dart';
import 'package:delivery_app/services/courier_service.dart';
import 'package:delivery_app/utils/location_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();
    DioConfig.isTestMode = true;
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Courier Models & Serialization Tests', () {
    test('CourierOrderCreateRequest serializes with exact backend postman keys', () {
      const request = CourierOrderCreateRequest(
        fromLatitude: 9.02497,
        fromLongitude: 38.74689,
        toLatitude: 8.98060,
        toLongitude: 38.75780,
        senderUserId: 1,
        receiverName: 'Bluye',
        receiverPhone: '+251911234567',
        carTypeId: 1,
        kmPrice: 35.0,
        totalPrice: 250.0,
        description: 'Fragile electronics. Please call upon arrival.',
      );

      final json = request.toJson();

      expect(json['from_latitude'], 9.02497);
      expect(json['from_longtude'], 38.74689); // Note backend spelling: from_longtude
      expect(json['to_latitude'], 8.98060);
      expect(json['to_longtude'], 38.75780); // Note backend spelling: to_longtude
      expect(json['sender_user_id'], 1);
      expect(json['reciver_name'], 'Bluye'); // Note backend spelling: reciver_name
      expect(json['reciver_phone'], '+251911234567');
      expect(json['car_type_id'], 1);
      expect(json['km_price'], 35.0);
      expect(json['total_price'], 250.0);
      expect(json['description'], 'Fragile electronics. Please call upon arrival.');
      expect(json['from_friendly_location'], '');
      expect(json['to_friendly_location'], '');
    });

    test('CourierOrderCreateRequest serializes with from_friendly_location and to_friendly_location', () {
      const request = CourierOrderCreateRequest(
        fromLatitude: 9.02497,
        fromLongitude: 38.74689,
        toLatitude: 8.98060,
        toLongitude: 38.75780,
        senderUserId: 1,
        receiverName: 'Bluye',
        receiverPhone: '+251911234567',
        fromFriendlyLocation: 'Bole Atlas, Addis Ababa',
        toFriendlyLocation: 'Sarbet, Addis Ababa',
        totalPrice: 250.0,
      );

      final json = request.toJson();
      expect(json['from_friendly_location'], 'Bole Atlas, Addis Ababa');
      expect(json['to_friendly_location'], 'Sarbet, Addis Ababa');
    });

    test('CourierOrderCreateRequest serializes city_id correctly', () {
      const request = CourierOrderCreateRequest(
        fromLatitude: 9.02497,
        fromLongitude: 38.74689,
        toLatitude: 8.98060,
        toLongitude: 38.75780,
        senderUserId: 1,
        receiverName: 'Bluye',
        receiverPhone: '+251911234567',
        fromFriendlyLocation: 'Bole, Addis Ababa',
        toFriendlyLocation: 'Sarbet, Addis Ababa',
        cityId: 1,
        totalPrice: 250.0,
      );

      final json = request.toJson();
      expect(json['city_id'], 1);
    });

    test('CourierOrderModel deserializes backend active order response with longtude safely', () {
      final json = {
        'id': 1,
        'status': '0',
        'from_latitude': '9.02497',
        'from_longtude': '38.74689',
        'to_latitude': '8.9806',
        'to_longtude': '38.7578',
        'sender_f_name': 'aman',
        'sender_l_name': 'tilahun',
        'sender_phone': '251911058179',
        'receiver_name': 'Bluye',
        'receiver_phone': '+251911234567',
        'driver_f_name': null,
        'driver_l_name': null,
        'driver_phone': null,
        'car_type': 'MoterBick',
        'km_price': '35',
        'total_km': '0',
        'total_price': '250',
        'date_time': '2026-10-16 19:25:59'
      };

      final order = CourierOrderModel.fromJson(json);

      expect(order.id, 1);
      expect(order.status, '0');
      expect(order.fromLatitude, closeTo(9.02497, 0.0001));
      expect(order.fromLongitude, closeTo(38.74689, 0.0001));
      expect(order.toLatitude, closeTo(8.9806, 0.0001));
      expect(order.toLongitude, closeTo(38.7578, 0.0001));
      expect(order.senderFullName, 'aman tilahun');
      expect(order.receiverName, 'Bluye');
      expect(order.receiverPhone, '+251911234567');
      expect(order.carType, 'MoterBick');
      expect(order.kmPrice, 35.0);
      expect(order.totalPrice, 250.0);
      expect(order.statusTitle, 'Pending Rider');
      expect(order.hasDriverAssigned, isFalse);
    });

    test('CourierOrderModel deserializes assigned driver and transit status', () {
      final json = {
        'id': 15,
        'status': '2',
        'from_latitude': 9.02497,
        'from_longtude': 38.74689,
        'to_latitude': 8.98060,
        'to_longtude': 38.75780,
        'sender_f_name': 'Abel',
        'sender_l_name': 'Seyoum',
        'receiver_name': 'Sara',
        'receiver_phone': '+251912345678',
        'driver_f_name': 'Kebede',
        'driver_l_name': 'Chala',
        'driver_phone': '+251933445566',
        'car_type': 'Motorbike',
        'km_price': 35,
        'total_km': 6.5,
        'total_price': 227.5,
      };

      final order = CourierOrderModel.fromJson(json);

      expect(order.status, '2');
      expect(order.statusTitle, 'In Transit');
      expect(order.hasDriverAssigned, isTrue);
      expect(order.driverFullName, 'Kebede Chala');
      expect(order.totalKm, 6.5);
    });

    test('CourierOrderModel.formattedDateTime normalizes date strings to human-readable words', () {
      final now = DateTime.now();

      // Case 1: Null or empty date
      const emptyOrder = CourierOrderModel(
        id: 1,
        status: '0',
        fromLatitude: 9.0,
        fromLongitude: 38.0,
        toLatitude: 9.1,
        toLongitude: 38.1,
        receiverName: 'Test',
        receiverPhone: '123',
        carType: 'Motorbike',
        kmPrice: 35.0,
        totalKm: 1.0,
        totalPrice: 50.0,
        dateTime: null,
      );
      expect(emptyOrder.formattedDateTime, isEmpty);

      // Case 2: Today (just now or minutes ago)
      final justNowDate = now.subtract(const Duration(minutes: 5)).toIso8601String();
      final justNowOrder = emptyOrder.copyWith(dateTime: justNowDate);
      expect(justNowOrder.formattedDateTime, contains('mins ago'));

      // Case 3: Yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayDate = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')} 14:30:00';
      final yesterdayOrder = emptyOrder.copyWith(dateTime: yesterdayDate);
      expect(yesterdayOrder.formattedDateTime, startsWith('Yesterday at '));

      // Case 4: Past year
      final pastYearDate = '2023-05-12 10:15:00';
      final pastYearOrder = emptyOrder.copyWith(dateTime: pastYearDate);
      expect(pastYearOrder.formattedDateTime, contains('2023'));

      // Case 5: Invalid date string falls back safely
      final invalidOrder = emptyOrder.copyWith(dateTime: 'not-a-valid-date');
      expect(invalidOrder.formattedDateTime, 'not-a-valid-date');
    });
  });

  group('Courier Distance & Pricing Logic Tests', () {
    test('Calculates distance and fare between Bole and Sarbet coordinates accurately', () {
      const fromLat = 9.02497;
      const fromLng = 38.74689;
      const toLat = 8.98060;
      const toLng = 38.75780;

      final distance = LocationUtils.calculateDistanceInKm(
        lat1: fromLat,
        lon1: fromLng,
        lat2: toLat,
        lon2: toLng,
      );

      expect(distance, greaterThan(4.5));
      expect(distance, lessThan(6.5));

      final controller = CourierController();
      controller.setLocation(
        isPickup: true,
        lat: fromLat,
        lng: fromLng,
        address: 'Bole Medhanialem',
      );
      controller.setLocation(
        isPickup: false,
        lat: toLat,
        lng: toLng,
        address: 'Sarbet',
      );

      expect(controller.calculatedDistanceKm.value, closeTo(distance, 0.05));
      expect(controller.calculatedTotalPrice.value, greaterThan(150.0));
      expect(controller.hasCoordinatesSelected, isTrue);
    });

    test('CourierController enforces minimum base price for short trips', () {
      final controller = CourierController();
      // Points very close to each other (< 100 meters)
      controller.setLocation(
        isPickup: true,
        lat: 9.0209,
        lng: 38.7469,
        address: 'Point A',
      );
      controller.setLocation(
        isPickup: false,
        lat: 9.0211,
        lng: 38.7470,
        address: 'Point B',
      );

      // Even for short distances, base fee is at least 50 ETB
      expect(controller.calculatedTotalPrice.value, equals(50.0));
    });
  });

  group('Courier Service Mock Tests', () {
    test('CourierService creates order and loads orders in test mode', () async {
      final active = await CourierService.fetchActiveOrders(1);
      expect(active, isNotEmpty);
      expect(active.first.receiverName, 'Bluye');

      final past = await CourierService.fetchPastOrders(1);
      expect(past, isNotEmpty);
      expect(past.first.statusTitle, 'Delivered');

      final placed = await CourierService.createCourierOrder(
        const CourierOrderCreateRequest(
          fromLatitude: 9.02497,
          fromLongitude: 38.74689,
          toLatitude: 8.98060,
          toLongitude: 38.75780,
          senderUserId: 1,
          receiverName: 'Test',
          receiverPhone: '+251911223344',
          totalPrice: 150.0,
        ),
      );
      expect(placed, isTrue);
    });

    test('CourierOrderCreateRequest serializes payment_type correctly', () {
      const defaultRequest = CourierOrderCreateRequest(
        fromLatitude: 9.0,
        fromLongitude: 38.0,
        toLatitude: 9.1,
        toLongitude: 38.1,
        senderUserId: 1,
        receiverName: 'Test',
        receiverPhone: '+251911000000',
        totalPrice: 100.0,
      );
      expect(defaultRequest.toJson()['payment_type'], '0');

      const chapaRequest = CourierOrderCreateRequest(
        fromLatitude: 9.0,
        fromLongitude: 38.0,
        toLatitude: 9.1,
        toLongitude: 38.1,
        senderUserId: 1,
        receiverName: 'Test',
        receiverPhone: '+251911000000',
        totalPrice: 100.0,
        paymentType: '1',
      );
      expect(chapaRequest.toJson()['payment_type'], '1');

      const walletRequest = CourierOrderCreateRequest(
        fromLatitude: 9.0,
        fromLongitude: 38.0,
        toLatitude: 9.1,
        toLongitude: 38.1,
        senderUserId: 1,
        receiverName: 'Test',
        receiverPhone: '+251911000000',
        totalPrice: 100.0,
        paymentType: '2',
      );
      expect(walletRequest.toJson()['payment_type'], '2');
    });

    test('CourierController handles delivery option selection and price recalculation', () async {
      final controller = CourierController();
      await controller.loadCourierDeliveryOptions();

      expect(controller.courierDeliveryOptions, isNotEmpty);
      expect(controller.selectedDeliveryOption.value, isNotNull);

      // Set coordinates
      controller.setLocation(
        isPickup: true,
        lat: 9.02497,
        lng: 38.74689,
        address: 'Bole',
      );
      controller.setLocation(
        isPickup: false,
        lat: 8.98060,
        lng: 38.75780,
        address: 'Sarbet',
      );

      final initialPrice = controller.calculatedTotalPrice.value;
      expect(initialPrice, greaterThan(0));

      // Select custom higher rate option
      const higherRateOption = PropertyDeliveryOption(
        id: 2,
        image: '',
        name: 'Car / Van',
        kmPrice: 50.0,
      );
      controller.selectDeliveryOption(higherRateOption);

      expect(controller.kmPrice.value, 50.0);
      expect(controller.carTypeName.value, 'Car / Van');
      expect(controller.carTypeId.value, 2);
      expect(controller.calculatedTotalPrice.value, greaterThan(initialPrice));

      // Test payment method selection
      expect(controller.selectedPaymentMethod.value, 'cash');
      controller.selectPaymentMethod('chapa');
      expect(controller.selectedPaymentMethod.value, 'chapa');
      controller.selectPaymentMethod('wallet');
      expect(controller.selectedPaymentMethod.value, 'wallet');
    });
  });

  group('Courier Service Dio HTTP Endpoint Mock Tests', () {
    late DioAdapter dioAdapter;

    setUp(() async {
      DioConfig.isTestMode = true;
      DioConfig.resetDio();
      final dio = await DioConfig.dio();
      dioAdapter = DioAdapter(dio: dio);
    });

    tearDown(() {
      DioConfig.resetDio();
    });

    test('GET /courirer_delivery_option parses vehicle options and km_price', () async {
      dioAdapter.onGet(
        ApiEndpoints.courierDeliveryOptions,
        (server) => server.reply(200, {
          'message': 'delviery option retrieved successfully',
          'data': [
            {
              'id': 10,
              'image': 'https://api.amnplc.com/assets/images%20(78).jpeg',
              'name': 'MoterBick',
              'km_price': '13'
            },
            {
              'id': 11,
              'image': 'https://api.amnplc.com/assets/car.jpeg',
              'name': 'Mini Van',
              'km_price': '25'
            }
          ]
        }),
      );

      final list = await CourierService.fetchCourierDeliveryOptions();
      expect(list.length, 2);
      expect(list[0].id, 10);
      expect(list[0].name, 'MoterBick');
      expect(list[0].kmPrice, 13.0);
      expect(list[1].id, 11);
      expect(list[1].name, 'Mini Van');
      expect(list[1].kmPrice, 25.0);
    });

    test('POST /courirer-pay-on-chapa sends request and resolves checkout_url', () async {
      dioAdapter.onPost(
        ApiEndpoints.courierPayOnChapa,
        (server) => server.reply(200, {
          'message': 'Hosted Link',
          'status': 'success',
          'data': {
            'checkout_url': 'https://checkout.chapa.co/checkout/payment/courier-test-999',
          },
        }),
        data: {
          'user_id': 5,
          'amount': 350.0,
          'date': '2026-10-19',
          'order_id': 1,
        },
      );

      String? retrievedUrl;
      await CourierService.payCourierOnChapa(
        userId: 5,
        amount: 350.0,
        date: '2026-10-19',
        orderId: 1,
        onSuccess: (url, msg) => retrievedUrl = url,
        onFailure: (err) => fail(err),
      );

      expect(retrievedUrl, 'https://checkout.chapa.co/checkout/payment/courier-test-999');
    });

    test('POST /courirer-pay-on-wallet sends request and handles response', () async {
      dioAdapter.onPost(
        ApiEndpoints.courierPayOnWallet,
        (server) => server.reply(200, {
          'message': 'Payment successful',
          'status': 'success',
        }),
        data: {
          'user_id': 5,
          'amount': 350.0,
          'date': '2026-10-19',
          'order_id': 1,
        },
      );

      bool walletSuccess = false;
      await CourierService.payCourierOnWallet(
        userId: 5,
        amount: 350.0,
        date: '2026-10-19',
        orderId: 1,
        onSuccess: (data) => walletSuccess = true,
        onFailure: (err) => fail(err),
      );

      expect(walletSuccess, isTrue);
    });
  });
}
