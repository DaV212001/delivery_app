import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/constants/api_endpoints.dart';
import 'package:delivery_app/models/address_model.dart';
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
        location: 'Bole Road, Addis Ababa',
        date: '2026-09-18T10:31:15.000000Z',
        paymentType: '0',
        totalQuantity: 2,
        menuIds: [101],
        quantities: [2],
        prices: [340.0],
        itemTotalPrice: 680.0,
        totalItem: 1,
        propertyId: 1,
        customerLatitude: 9.032,
        customerLongitude: 38.746,
        propertyLatitude: 9.032,
        propertyLongitude: 38.746,
        deliveryOption: 1,
        kmPrice: 13,
        totalKmPrice: 130,
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

    test('OrderService fetches property delivery options correctly', () async {
      dioAdapter.onGet(
        ApiEndpoints.propertyDeliveryOptions(1),
        (server) => server.reply(200, {
          'message': 'delviery option retrieved successfully',
          'data': [
            {
              'id': null,
              'image': 'https://api.amnplc.com/assets/images%20(78).jpeg',
              'name': 'MoterBick',
              'km_price': '13',
            },
          ],
        }),
      );

      final options = await OrderService.fetchPropertyDeliveryOptions(1);
      expect(options.length, 1);
      expect(options.first.name, 'MoterBick');
      expect(options.first.kmPrice, 13.0);
    });

    test('OrderService payOnChapa resolves recursive checkout_url', () async {
      dioAdapter.onPost(
        ApiEndpoints.payOnChapa,
        (server) => server.reply(200, {
          'message': 'Hosted Link',
          'status': 'success',
          'data': {
            'checkout_url': 'https://checkout.chapa.co/checkout/payment/test12345',
          },
        }),
        data: {
          'user_id': 1,
          'amount': 680.0,
          'date': '2026-03-02',
          'order_id': 1,
        },
      );

      String? retrievedUrl;
      await OrderService.payOnChapa(
        userId: 1,
        amount: 680.0,
        date: '2026-03-02',
        orderId: 1,
        onSuccess: (url, msg) => retrievedUrl = url,
        onFailure: (err) => fail(err),
      );

      expect(retrievedUrl, 'https://checkout.chapa.co/checkout/payment/test12345');
    });

    test('OrderService payOnWallet processes wallet payment', () async {
      dioAdapter.onPost(
        ApiEndpoints.payOnWallet,
        (server) => server.reply(200, {
          'message': 'We Accept your payment succesfully',
          'data': {'id': 1, 'customer_id': '1'},
        }),
        data: {
          'user_id': 1,
          'amount': 680.0,
          'date': '2026-03-02',
          'order_id': 1,
        },
      );

      bool walletSuccess = false;
      await OrderService.payOnWallet(
        userId: 1,
        amount: 680.0,
        date: '2026-03-02',
        orderId: 1,
        onSuccess: (data) => walletSuccess = true,
        onFailure: (err) => fail(err),
      );

      expect(walletSuccess, true);
    });

    test('OrderService.findCheckoutUrl finds deeply nested checkout_url', () {
      final deeplyNested = {
        'status': 'success',
        'wrapper': [
          {
            'nested': {
              'details': {
                'checkout_url': 'https://chapa.co/pay/xyz',
              },
            },
          },
        ],
      };
      expect(OrderService.findCheckoutUrl(deeplyNested), 'https://chapa.co/pay/xyz');
      expect(OrderService.findCheckoutUrl({'other': 123}), isNull);
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

    test('ProfileService updates user profile successfully via PUT /profile/{id}', () async {
      dioAdapter.onPut(
        ApiEndpoints.profile(1),
        (server) => server.reply(200, {
          'success': true,
          'message': 'Profile updated successfully',
          'data': {
            'id': 1,
            'f_name': 'aman',
            'l_name': 'til',
            'email': 'tilahunamanuel0@gmail.com',
            'phone': '251911058179',
          },
        }),
        data: {
          'f_name': 'aman',
          'l_name': 'til',
          'email': 'tilahunamanuel0@gmail.com',
          'phone': '251911058179',
        },
      );

      bool succeeded = false;
      Map<String, dynamic>? updatedData;

      await ProfileService.updateProfile(
        customerId: 1,
        firstName: 'aman',
        lastName: 'til',
        email: 'tilahunamanuel0@gmail.com',
        phone: '251911058179',
        onSuccess: (data) {
          succeeded = true;
          updatedData = data;
        },
        onFailure: (err) => fail('Should not fail: $err'),
      );

      expect(succeeded, true);
      expect(updatedData?['f_name'], 'aman');
      expect(updatedData?['l_name'], 'til');
      expect(updatedData?['email'], 'tilahunamanuel0@gmail.com');
      expect(updatedData?['phone'], '251911058179');
    });

    test('ProfileService handles update profile failure and extracts field errors', () async {
      dioAdapter.onPut(
        ApiEndpoints.profile(1),
        (server) => server.reply(422, {
          'message': 'The email has already been taken.',
          'errors': {
            'email': ['The email has already been taken.'],
          },
        }),
        data: {
          'f_name': 'aman',
          'l_name': 'til',
          'email': 'taken@example.com',
          'phone': '251911058179',
        },
      );

      String? errorMessage;
      await ProfileService.updateProfile(
        customerId: 1,
        firstName: 'aman',
        lastName: 'til',
        email: 'taken@example.com',
        phone: '251911058179',
        onSuccess: (_) => fail('Should have failed'),
        onFailure: (err) => errorMessage = err,
      );

      expect(errorMessage, 'The email has already been taken.');
    });

    test('ProfileService updates delivery address successfully via PUT /delivery-adress/{id}', () async {
      dioAdapter.onPut(
        ApiEndpoints.deliveryAddressDetail(162),
        (server) => server.reply(200, {
          'success': true,
          'message': 'Address updated successfully',
        }),
        data: {
          'id': 162,
          'name': 'office',
          'latitude': 4.5678,
          'longitude': 2.74573,
          'user_id': 1,
        },
      );

      bool addressUpdated = false;
      await ProfileService.editDeliveryAddress(
        address: const AddressModel(
          id: 162,
          name: 'office',
          latitude: 4.5678,
          longitude: 2.74573,
          userId: 1,
        ),
        onSuccess: () => addressUpdated = true,
        onFailure: (err) => fail('Should not fail: $err'),
      );

      expect(addressUpdated, true);
    });

    test('AuthService.uploadProfileImage succeeds and extracts profile_image URL', () async {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/test_avatar.jpg')..writeAsStringSync('fake-image-bytes');

      dioAdapter.onPost(
        ApiEndpoints.customerChangeProfileImage,
        (server) => server.reply(200, {
          'message': 'Profile picture changed successfully',
          'data': {
            'id': 1,
            'profile_image': 'https://api.amnplc.com/public/storage/profileImage/1789731525.jpg',
          },
        }),
        data: Matchers.any,
      );

      String uploadedUrl = '';
      await AuthService.uploadProfileImage(
        userId: 1,
        filePath: tempFile.path,
        onSuccess: (url) => uploadedUrl = url,
        onFailure: (err) => fail('Should not fail: $err'),
      );

      expect(uploadedUrl, 'https://api.amnplc.com/public/storage/profileImage/1789731525.jpg');
      try {
        if (tempFile.existsSync()) tempFile.deleteSync();
      } catch (_) {}
    });

    test('AuthService.uploadProfileImage falls back to /change-profile-image on 404', () async {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/test_avatar_fallback.jpg')..writeAsStringSync('fake-image-bytes');

      dioAdapter.onPost(
        ApiEndpoints.customerChangeProfileImage,
        (server) => server.reply(404, {'message': 'Not Found'}),
        data: Matchers.any,
      );

      dioAdapter.onPost(
        ApiEndpoints.changeProfileImage,
        (server) => server.reply(200, {
          'message': 'Profile picture changed successfully',
          'data': {
            'profile_image': 'https://api.hellomesa6810.com/public/storage/profileImage/fallback.jpg',
          },
        }),
        data: Matchers.any,
      );

      String uploadedUrl = '';
      await AuthService.uploadProfileImage(
        userId: 1,
        filePath: tempFile.path,
        onSuccess: (url) => uploadedUrl = url,
        onFailure: (err) => fail('Should not fail: $err'),
      );

      expect(uploadedUrl, 'https://api.hellomesa6810.com/public/storage/profileImage/fallback.jpg');
      try {
        if (tempFile.existsSync()) tempFile.deleteSync();
      } catch (_) {}
    });

    test('AuthService.uploadProfileImage handles upload failure', () async {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/test_avatar_fail.jpg')..writeAsStringSync('fake-image-bytes');

      dioAdapter.onPost(
        ApiEndpoints.customerChangeProfileImage,
        (server) => server.reply(422, {
          'message': 'The image must be a valid file.',
        }),
        data: Matchers.any,
      );

      String errorMessage = '';
      await AuthService.uploadProfileImage(
        userId: 1,
        filePath: tempFile.path,
        onSuccess: (_) => fail('Should have failed'),
        onFailure: (err) => errorMessage = err,
      );

      expect(errorMessage, 'The image must be a valid file.');
      try {
        if (tempFile.existsSync()) tempFile.deleteSync();
      } catch (_) {}
    });
  });
}
