import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/constants/api_endpoints.dart';
import 'package:delivery_app/services/order_notification_retry_service.dart';

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

  late MockHttpClientAdapter mockAdapter;
  late Dio testDio;
  final service = OrderNotificationRetryService.instance;

  Future<void> waitForRequests(int targetCount, {Duration timeout = const Duration(seconds: 2)}) async {
    final stopWatch = Stopwatch()..start();
    while (mockAdapter.capturedRequests.length < targetCount && stopWatch.elapsed < timeout) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();
    Get.testMode = true;

    mockAdapter = MockHttpClientAdapter();
    testDio = Dio()..httpClientAdapter = mockAdapter;
    service.dioClient = testDio;
    service.checkInterval = const Duration(milliseconds: 20);
    service.maxRetries = 2;
    service.statusCheckOverride = null;
    service.clearAllTrackers();
  });

  tearDown(() {
    service.clearAllTrackers();
    service.statusCheckOverride = null;
    service.dioClient = null;
    service.checkInterval = const Duration(minutes: 2);
    Get.reset();
  });

  group('Order Notification Retry Endpoints & Formats', () {
    test('ApiEndpoints defines all collection endpoints correctly', () {
      expect(ApiEndpoints.pushNewOrder, 'https://notification.amnplc.com/api/push/new-order');
      expect(ApiEndpoints.pushCorporateOrder, 'https://notification.amnplc.com/api/push/corporate-order');
      expect(ApiEndpoints.pushCourierOrder, 'https://notification.amnplc.com/api/push/courirer-order');
    });

    test('formatPayment properly formats integers and floating values with Birr currency suffix', () {
      expect(OrderNotificationRetryService.formatPayment(231.0), '231 Birr');
      expect(OrderNotificationRetryService.formatPayment(231.5), '231.50 Birr');
      expect(OrderNotificationRetryService.formatPayment(0.0), '0 Birr');
    });
  });

  group('Normal Order Notification Retries', () {
    test('sends retry notification twice when status does not change to 1 and then stops', () async {
      service.statusCheckOverride = (type, orderId, userId) async => false;

      service.trackNormalOrder(
        orderId: 101,
        amount: 231.0,
        storeName: 'Abebe Store',
        destination: 'Welo Sefer',
        cityId: 1,
      );

      expect(service.isTracking(101), isTrue);
      expect(mockAdapter.capturedRequests.isEmpty, isTrue);

      // Wait for 1st retry check
      await waitForRequests(1);
      expect(mockAdapter.capturedRequests.length, 1);
      final req1 = mockAdapter.capturedRequests[0];
      expect(req1.path, ApiEndpoints.pushNewOrder);
      expect(req1.data['order_id'], 101);
      expect(req1.data['title'], 'New Order Received');
      expect(req1.data['payment'], '231 Birr');
      expect(req1.data['from'], 'Abebe Store');
      expect(req1.data['to'], 'Welo Sefer');
      expect(req1.data['city_id'], 1);
      expect(service.getRetryCount(101), 1);

      // Wait for 2nd retry check
      await waitForRequests(2);
      expect(mockAdapter.capturedRequests.length, 2);
      expect(service.isTracking(101), isFalse); // Max retries (2) reached, tracking stopped

      // Wait more time to ensure no 3rd call is ever sent
      await Future.delayed(const Duration(milliseconds: 60));
      expect(mockAdapter.capturedRequests.length, 2);
    });

    test('cancels retry without sending notification if status changes to 1 at first check', () async {
      service.statusCheckOverride = (type, orderId, userId) async => true;

      service.trackNormalOrder(
        orderId: 102,
        amount: 150.0,
        storeName: 'Burger Joint',
        destination: 'Bole',
      );

      expect(service.isTracking(102), isTrue);

      await Future.delayed(const Duration(milliseconds: 60));
      // Status changed to 1, so no notification should have been sent
      expect(mockAdapter.capturedRequests.isEmpty, isTrue);
      expect(service.isTracking(102), isFalse);
    });

    test('sends 1st retry, then cancels 2nd retry when status changes to 1 before 2nd check', () async {
      int checkCallCount = 0;
      service.statusCheckOverride = (type, orderId, userId) async {
        checkCallCount++;
        // Check 1: status is 0 (not accepted)
        // Check 2: status changed to 1 (accepted)
        return checkCallCount > 1;
      };

      service.trackNormalOrder(
        orderId: 103,
        amount: 300.0,
        storeName: 'Pizza Inn',
        destination: 'Kazanchis',
      );

      // 1st check
      await waitForRequests(1);
      expect(mockAdapter.capturedRequests.length, 1);
      expect(service.isTracking(103), isTrue);

      // 2nd check: status becomes 1
      await Future.delayed(const Duration(milliseconds: 60));
      expect(mockAdapter.capturedRequests.length, 1);
      expect(service.isTracking(103), isFalse);
    });
  });

  group('Corporate Order Notification Retries', () {
    test('sends corporate notification with correct payload and retries up to 2 times', () async {
      service.statusCheckOverride = (type, orderId, userId) async => false;

      service.trackCorporateOrder(
        orderId: 201,
        userId: 55,
        amount: 500.0,
        fromBranch: 'Bole Branch',
        toBranch: 'Summit Branch',
        cityId: 1,
      );

      expect(service.isTracking(201), isTrue);

      // Wait for 1st retry
      await waitForRequests(1);
      expect(mockAdapter.capturedRequests.length, 1);
      final req = mockAdapter.capturedRequests.first;
      expect(req.path, ApiEndpoints.pushCorporateOrder);
      expect(req.data['order_id'], 201);
      expect(req.data['title'], 'New Corporate Order');
      expect(req.data['city_id'], 1);
      expect(req.data['payment'], '500 Birr');
      expect(req.data['from'], 'Bole Branch');
      expect(req.data['to'], 'Summit Branch');

      // Wait for 2nd retry
      await waitForRequests(2);
      expect(mockAdapter.capturedRequests.length, 2);
      expect(service.isTracking(201), isFalse);
    });
  });

  group('Courier Order Notification Retries', () {
    test('sends courier notification with correct payload and retries up to 2 times', () async {
      service.statusCheckOverride = (type, orderId, userId) async => false;

      service.trackCourierOrder(
        orderId: 301,
        userId: 77,
        amount: 180.0,
        fromAddress: 'Piazza',
        toAddress: 'Sarbet',
        cityId: '1',
      );

      expect(service.isTracking(301), isTrue);

      // Wait for 1st retry
      await waitForRequests(1);
      expect(mockAdapter.capturedRequests.length, 1);
      final req = mockAdapter.capturedRequests.first;
      expect(req.path, ApiEndpoints.pushCourierOrder);
      expect(req.data['order_id'], 301);
      expect(req.data['title'], 'New Courirre Order');
      expect(req.data['payment'], '180 Birr');
      expect(req.data['from'], 'Piazza');
      expect(req.data['to'], 'Sarbet');
      expect(req.data['city_id'], '1');

      // Wait for 2nd retry
      await waitForRequests(2);
      expect(mockAdapter.capturedRequests.length, 2);
      expect(service.isTracking(301), isFalse);
    });
  });

  group('Error & Duplication Tolerance', () {
    test('ignores duplicate warning or non-200 responses without throwing', () async {
      service.statusCheckOverride = (type, orderId, userId) async => false;
      mockAdapter.statusCodeToReturn = 409;
      mockAdapter.dataToReturn = {'message': 'skipped because of duplication'};

      service.trackNormalOrder(
        orderId: 401,
        amount: 100.0,
        storeName: 'Test Store',
        destination: 'Test Destination',
      );

      // 1st retry
      await waitForRequests(1);
      expect(mockAdapter.capturedRequests.length, 1);
      expect(service.isTracking(401), isTrue);

      // 2nd retry
      await waitForRequests(2);
      expect(mockAdapter.capturedRequests.length, 2);
      expect(service.isTracking(401), isFalse);
    });

    test('manual cancelTracking immediately aborts scheduled retries', () async {
      service.statusCheckOverride = (type, orderId, userId) async => false;

      service.trackNormalOrder(
        orderId: 501,
        amount: 250.0,
        storeName: 'Cancel Store',
        destination: 'Cancel Dest',
      );

      expect(service.isTracking(501), isTrue);
      service.cancelTracking(501);
      expect(service.isTracking(501), isFalse);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(mockAdapter.capturedRequests.isEmpty, isTrue);
    });
  });
}
