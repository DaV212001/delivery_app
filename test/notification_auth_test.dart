import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/constants/api_endpoints.dart';
import 'package:delivery_app/controllers/auth_controller.dart';
import 'package:delivery_app/services/notification_service.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  final List<RequestOptions> capturedRequests = [];
  int statusCodeToReturn = 200;
  dynamic dataToReturn = {'status': 'success'};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedRequests.add(options);
    final jsonStr = jsonEncode(dataToReturn);
    return ResponseBody.fromString(
      jsonStr,
      statusCodeToReturn,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
    NotificationService.instance.dioClient = null;
  });

  group('Push Notification API Endpoints', () {
    test('ApiEndpoints defines all collection endpoints correctly', () {
      expect(ApiEndpoints.notificationBaseUrl, 'https://notification.amnplc.com/api');
      expect(ApiEndpoints.customerTokens, 'https://notification.amnplc.com/api/customer-tokens');
      expect(
        ApiEndpoints.deleteCustomerToken('test-token-123'),
        'https://notification.amnplc.com/api/customer-tokens/test-token-123',
      );
      expect(
        ApiEndpoints.pushCustomersBulk,
        'https://notification.amnplc.com/api/push/customers-bulk',
      );
      expect(
        ApiEndpoints.pushCustomerOrderStatus,
        'https://notification.amnplc.com/api/push/customer-order-status',
      );
    });
  });

  group('NotificationService FCM Token Registration & Deletion', () {
    test('registerDeviceToken sends POST request with customer_id, fcm_token, and platform', () async {
      final mockAdapter = MockHttpClientAdapter();
      final testDio = Dio()..httpClientAdapter = mockAdapter;
      NotificationService.instance.dioClient = testDio;

      final result = await NotificationService.instance.registerDeviceToken(
        customerId: 42,
        token: 'sample_fcm_token_xyz',
      );

      expect(result, isTrue);
      expect(mockAdapter.capturedRequests.length, 1);
      final req = mockAdapter.capturedRequests.first;
      expect(req.method, 'POST');
      expect(req.path, ApiEndpoints.customerTokens);
      expect(req.data['customer_id'], 42);
      expect(req.data['fcm_token'], 'sample_fcm_token_xyz');
      expect(req.data['platform'], isNotEmpty);
    });

    test('registerDeviceToken returns false when customerId is invalid', () async {
      final mockAdapter = MockHttpClientAdapter();
      final testDio = Dio()..httpClientAdapter = mockAdapter;
      NotificationService.instance.dioClient = testDio;

      final result = await NotificationService.instance.registerDeviceToken(
        customerId: 0,
        token: 'sample_fcm_token_xyz',
      );

      expect(result, isFalse);
      expect(mockAdapter.capturedRequests.isEmpty, isTrue);
    });

    test('unregisterDeviceToken sends DELETE request to customer-tokens/{fcm_token}', () async {
      final mockAdapter = MockHttpClientAdapter();
      final testDio = Dio()..httpClientAdapter = mockAdapter;
      NotificationService.instance.dioClient = testDio;
      NotificationService.instance.fcmToken.value = 'token_to_remove';

      final result = await NotificationService.instance.unregisterDeviceToken(
        token: 'token_to_remove',
      );

      expect(result, isTrue);
      expect(mockAdapter.capturedRequests.length, 1);
      final req = mockAdapter.capturedRequests.first;
      expect(req.method, 'DELETE');
      expect(req.path, ApiEndpoints.deleteCustomerToken('token_to_remove'));
      expect(NotificationService.instance.fcmToken.value, isNull);
    });
  });

  group('AuthController Logout & Progress State', () {
    test('logout unregisters FCM token and resets isLoggingOut reactive flag', () async {
      final mockAdapter = MockHttpClientAdapter();
      final testDio = Dio()..httpClientAdapter = mockAdapter;
      NotificationService.instance.dioClient = testDio;

      await ConfigPreference.setUserId(101);
      await ConfigPreference.updateTokens('access-token', 'refresh-token', 3600);

      final authController = AuthController();
      Get.put<AuthController>(authController);

      expect(authController.isLoggedIn, isTrue);
      expect(authController.isLoggingOut.value, isFalse);

      NotificationService.instance.fcmToken.value = 'token_for_user_101';

      await authController.logout();

      expect(authController.isLoggingOut.value, isFalse);
      expect(authController.isLoggedIn, isFalse);
      expect(ConfigPreference.getUserId(), isNull);
      expect(NotificationService.instance.fcmToken.value, isNull);

      // Verify DELETE was triggered on the notification endpoint
      final deleteReq = mockAdapter.capturedRequests.firstWhere(
        (r) => r.method == 'DELETE' && r.path.contains('/customer-tokens/'),
        orElse: () => RequestOptions(path: ''),
      );
      expect(deleteReq.path, isNotEmpty);
      expect(deleteReq.path, contains('token_for_user_101'));
    });

    test('isLoggingOut flag is true while logout async operation is active', () async {
      final mockAdapter = MockHttpClientAdapter();
      final testDio = Dio()..httpClientAdapter = mockAdapter;
      NotificationService.instance.dioClient = testDio;

      await ConfigPreference.setUserId(202);
      final authController = AuthController();
      Get.put<AuthController>(authController);

      expect(authController.isLoggingOut.value, isFalse);

      final logoutFuture = authController.logout();
      expect(authController.isLoggingOut.value, isTrue);

      await logoutFuture;
      expect(authController.isLoggingOut.value, isFalse);
    });
  });
}
