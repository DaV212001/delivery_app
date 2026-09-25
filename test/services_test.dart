import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/constants/api_endpoints.dart';
import 'package:delivery_app/models/order.dart';
import 'package:delivery_app/services/auth_service.dart';
import 'package:delivery_app/services/info_service.dart';
import 'package:delivery_app/services/order_service.dart';
import 'package:delivery_app/services/profile_service.dart';
import 'package:delivery_app/services/property_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioAdapter dioAdapter;

  setUp(() async {
    DioConfig.isTestMode = true;
    DioConfig.resetDio();
    final dio = await DioConfig.dio();
    dioAdapter = DioAdapter(dio: dio);
  });

  tearDown(() {
    DioConfig.resetDio();
    DioConfig.isTestMode = false;
  });

  group('Service Layer Integration Tests', () {
    test('AuthService login successfully processes valid response', () async {
      dioAdapter.onPost(
        ApiEndpoints.customerLogin,
        (server) => server.reply(200, {
          'success': true,
          'message': 'Login successfully',
          'data': {
            'id': 1,
            'f_name': 'aman',
            'l_name': 'til',
            'phone': '251911058179',
            'token': 'bearer_mock_123',
          },
        }),
        data: {
          'phone': '251911058179',
          'password': '1224',
        },
      );

      bool succeeded = false;
      await AuthService.customerLogin(
        phone: '251911058179',
        password: '1224',
        onSuccess: (data) {
          succeeded = true;
          expect(data['id'], 1);
        },
        onFailure: (err) => fail('Should not fail: $err'),
      );

      expect(succeeded, true);
    });

    test('PropertyService fetches categories and handles multilingual names', () async {
      dioAdapter.onGet(
        ApiEndpoints.categories,
        (server) => server.reply(200, {
          'data': [
            {
              'id': 1,
              'image': 'https://erp.amnplc.com/cat1.jpg',
              'name': {'en': 'Bar and Restaurant'},
            },
          ],
        }),
      );

      final categories = await PropertyService.fetchCategories();
      expect(categories.length, 1);
      expect(categories.first.id, 1);
      expect(categories.first.displayName, 'Bar and Restaurant');
    });

    test('PropertyService fetches featured stores and property detail', () async {
      dioAdapter.onGet(
        ApiEndpoints.featureStores,
        (server) => server.reply(200, {
          'data': [
            {
              'id': 1,
              'property_name': 'AMN Restaurant',
              'property_logo': 'https://erp.amnplc.com/logo.jpg',
              'property_cover_image': 'https://erp.amnplc.com/cover.jpg',
              'property_frendly_location': 'Summit',
              'delviery_time': '30 min',
              'categroy_name': {'en': 'Bar and Restaurant'},
            },
          ],
        }),
      );

      final stores = await PropertyService.fetchFeaturedStores();
      expect(stores.length, 1);
      expect(stores.first.name, 'AMN Restaurant');
      expect(stores.first.deliveryTime, '30 min');

      dioAdapter.onGet(
        ApiEndpoints.propertyDetail(1),
        (server) => server.reply(200, {
          'data': {
            'property': {
              'id': 1,
              'property_name': 'AMN Restaurant',
              'property_frendly_location': 'Summit',
            },
            'menus': [
              {
                'id': 101,
                'name': 'checkebvsa',
                'price': '340',
                'desacriprion': 'Delicious local special',
              },
            ],
            'menu_categories': [
              {'id': 1, 'name': 'Breakfast'},
            ],
          },
        }),
      );

      final detail = await PropertyService.fetchPropertyDetail(1);
      expect(detail, isNotNull);
      expect(detail!.name, 'AMN Restaurant');
      expect(detail.items.length, 1);
      expect(detail.items.first.name, 'checkebvsa');
      expect(detail.categories, contains('Breakfast'));
    });

    test('OrderService creates order and fetches active orders', () async {
      final req = OrderCreateRequest(
        customerId: 1,
        menuIds: [101],
        location: 'Bole Road, Addis Ababa',
        date: '2026-09-18',
        quantities: [2],
        totalQuantity: 2,
        prices: [340.0],
        totalPrice: 680.0,
        totalItem: 1,
        propertyId: 1,
        latitude: 9.032,
        longitude: 38.746,
      );

      dioAdapter.onPost(
        ApiEndpoints.order,
        (server) => server.reply(200, {'message': 'Order placed'}),
        data: req.toJson(),
      );

      bool orderCreated = false;
      await OrderService.createOrder(
        request: req,
        onSuccess: (_) => orderCreated = true,
        onFailure: (err) => fail(err),
      );
      expect(orderCreated, true);

      dioAdapter.onGet(
        ApiEndpoints.activeOrders(1),
        (server) => server.reply(200, {
          'data': [
            {
              'id': 12,
              'customer_id': '1',
              'location': 'Bole Road',
              'status': '0',
              'total_price': '680',
              'total_item': '1',
            },
          ],
        }),
      );

      final activeList = await OrderService.fetchActiveOrders(1);
      expect(activeList.length, 1);
      expect(activeList.first.orderId, '#AMN-12');
    });

    test('ProfileService fetches wallet amount and delivery addresses', () async {
      dioAdapter.onGet(
        ApiEndpoints.walletAmount(1),
        (server) => server.reply(200, {'data': '330'}),
      );

      final balance = await ProfileService.fetchWalletAmount(1);
      expect(balance.amount, 330.0);

      dioAdapter.onGet(
        ApiEndpoints.deliveryAddresses(1),
        (server) => server.reply(200, {
          'data': [
            {
              'id': 3,
              'name': 'Home',
              'latitude': '9.0209',
              'longitude': '38.6773',
              'user_id': '1',
            },
          ],
        }),
      );

      final addresses = await ProfileService.fetchDeliveryAddresses(1);
      expect(addresses.length, 1);
      expect(addresses.first.name, 'Home');

      dioAdapter.onPost(
        ApiEndpoints.walletPayment,
        (server) => server.reply(200, {
          'message': 'Hosted Link',
          'status': 'success',
          'data': {
            'checkout_url': 'https://checkout.chapa.co/checckout/payment/123',
          },
        }),
        data: {
          'user_id': 1,
          'amount': 150.0,
          'date': '2026-09-23',
        },
      );

      String? retrievedUrl;
      await ProfileService.topupWallet(
        userId: 1,
        amount: 150.0,
        date: '2026-09-23',
        onSuccess: (checkoutUrl, msg) => retrievedUrl = checkoutUrl,
        onFailure: (err) => fail(err),
      );
      expect(retrievedUrl, 'https://checkout.chapa.co/checckout/payment/123');
    });

    test('InfoService fetches FAQs and Privacy Policy', () async {
      dioAdapter.onGet(
        ApiEndpoints.faq,
        (server) => server.reply(200, {
          'data': [
            {
              'question': {'en': 'How does delivery work?'},
              'answer': {'en': 'Fast local drivers deliver to your door.'},
            },
          ],
        }),
      );

      final faqs = await InfoService.fetchFaqs();
      expect(faqs.length, 1);
      expect(faqs.first.questionText, 'How does delivery work?');
    });
  });
}
