import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/controllers/auth_controller.dart';
import 'package:delivery_app/controllers/cart_controller.dart';
import 'package:delivery_app/controllers/order_controller.dart';
import 'package:delivery_app/models/order.dart';
import 'package:delivery_app/models/store.dart';
import 'package:delivery_app/screens/tracking/order_tracking_screen.dart';
import 'package:delivery_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Order Acceptance & Driver Visibility Logic', () {
    test('OrderProgressStatus.hasDriverAccepted returns correct values', () {
      expect(OrderProgressStatus.placed.hasDriverAccepted, isFalse);
      expect(OrderProgressStatus.placed.isAcceptedOrBeyond, isFalse);

      expect(OrderProgressStatus.accepted.hasDriverAccepted, isTrue);
      expect(OrderProgressStatus.accepted.isAcceptedOrBeyond, isTrue);

      expect(OrderProgressStatus.driverToShop.hasDriverAccepted, isTrue);
      expect(OrderProgressStatus.driverToYou.hasDriverAccepted, isTrue);
      expect(OrderProgressStatus.delivered.hasDriverAccepted, isTrue);

      expect(OrderProgressStatus.cancelled.hasDriverAccepted, isFalse);
    });

    test('OrderModel.fromOrderDetailJson suppresses driver when order is pending acceptance (status 0)', () {
      final json = {
        'id': 101,
        'status': '0',
        'driver_id': '1',
        'driver_f_name': 'Abebe',
        'driver_l_name': 'Kebede',
        'driver_phone': '+251911223344',
        'driver_vehicle': 'Toyota Vitz',
        'driver_plate': 'A12345',
      };

      final order = OrderModel.fromOrderDetailJson(
        statusJson: json,
        itemsList: [],
        orderId: '101',
      );

      expect(order.status, equals(OrderProgressStatus.placed));
      expect(order.hasDriverAccepted, isFalse);
      expect(order.isAccepted, isFalse);
      expect(order.driver, isNull, reason: 'Driver must be null when status is placed (0)');
    });

    test('OrderModel.fromOrderDetailJson populates driver when order is accepted (status 1)', () {
      final json = {
        'id': 101,
        'status': '1',
        'driver_id': '1',
        'driver_f_name': 'Abebe',
        'driver_l_name': 'Kebede',
        'driver_phone': '+251911223344',
        'driver_vehicle': 'Toyota Vitz',
        'driver_plate': 'A12345',
      };

      final order = OrderModel.fromOrderDetailJson(
        statusJson: json,
        itemsList: [],
        orderId: '101',
      );

      expect(order.status, equals(OrderProgressStatus.accepted));
      expect(order.hasDriverAccepted, isTrue);
      expect(order.isAccepted, isTrue);
      expect(order.driver, isNotNull);
      expect(order.driver!.name, equals('Abebe Kebede'));
      expect(order.driver!.vehicle, equals('Toyota Vitz'));
      expect(order.driver!.plateNumber, equals('A12345'));
    });

    test('NotificationService emits order status notifications via onOrderStatusNotification', () async {
      final received = <Map<String, dynamic>>[];
      final sub = NotificationService.instance.onOrderStatusNotification.listen((data) {
        received.add(data);
      });

      NotificationService.instance.emitNotificationForTesting({
        'order_id': '999',
        'status': '1',
        'title': 'Order Accepted',
        'body': 'Driver accepted your order',
      });

      await Future.delayed(const Duration(milliseconds: 50));
      expect(received.length, equals(1));
      expect(received.first['order_id'], equals('999'));
      expect(received.first['status'], equals('1'));

      await sub.cancel();
    });
  });

  group('OrderTrackingScreen Driver Card Widget Tests', () {
    setUp(() async {
      Get.testMode = true;
      DioConfig.isTestMode = true;
      SharedPreferences.setMockInitialValues({
        'user_id': 1,
        'access_token': 'mock_token_1',
      });
      await ConfigPreference.init();
      Get.reset();
      Get.put(AuthController());
      Get.put(CartController());
    });

    tearDown(() {
      DioConfig.isTestMode = false;
      Get.reset();
    });

    testWidgets('Driver card is NOT displayed when order has not yet been accepted (status = placed)', (tester) async {
      final placedOrder = OrderModel(
        orderId: 'AMN-100',
        storeName: 'TRACTOR SPARE PARTS',
        storeImageUrl: '',
        orderDate: DateTime(2026, 11, 4),
        items: [],
        subtotal: 300,
        deliveryFee: 250,
        taxAndFees: 0,
        total: 550,
        deliveryAddress: 'Bole Road, Addis Ababa',
        status: OrderProgressStatus.placed,
        estimatedArrival: 'Waiting for driver to accept',
        storeType: StoreType.restaurant,
        // Even if driver info was attached, pending status should hide the card
        driver: const DriverInfo(
          name: 'Abebe Kebede',
          vehicle: 'Toyota Vitz',
          plateNumber: 'A12345',
          rating: 4.9,
          photoUrl: '',
          phone: '+251911223344',
        ),
      );

      final orderCtrl = Get.put(OrderController());
      orderCtrl.activeOrder.value = placedOrder;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: '/tracking',
          getPages: [
            GetPage(
              name: '/tracking',
              page: () => const OrderTrackingScreen(),
              arguments: placedOrder,
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(OrderTrackingScreen), findsOneWidget);
      expect(find.text('Order Placed', skipOffstage: false), findsOneWidget);

      // Driver info should NOT be in the widget tree
      expect(find.text('Abebe Kebede', skipOffstage: false), findsNothing);
      expect(find.text('Toyota Vitz • A12345', skipOffstage: false), findsNothing);
      expect(find.byIcon(Icons.call_rounded, skipOffstage: false), findsNothing);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded, skipOffstage: false), findsNothing);
    });

    testWidgets('Driver card IS displayed when order has been accepted by driver (status = accepted)', (tester) async {
      final acceptedOrder = OrderModel(
        orderId: 'AMN-100',
        storeName: 'TRACTOR SPARE PARTS',
        storeImageUrl: '',
        orderDate: DateTime(2026, 11, 4),
        items: [],
        subtotal: 300,
        deliveryFee: 250,
        taxAndFees: 0,
        total: 550,
        deliveryAddress: 'Bole Road, Addis Ababa',
        status: OrderProgressStatus.accepted,
        estimatedArrival: '25 mins',
        storeType: StoreType.restaurant,
        driver: const DriverInfo(
          name: 'Abebe Kebede',
          vehicle: 'Toyota Vitz',
          plateNumber: 'A12345',
          rating: 4.9,
          photoUrl: '',
          phone: '+251911223344',
        ),
      );

      final orderCtrl = Get.put(OrderController());
      orderCtrl.activeOrder.value = acceptedOrder;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: '/tracking',
          getPages: [
            GetPage(
              name: '/tracking',
              page: () => const OrderTrackingScreen(),
              arguments: acceptedOrder,
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(OrderTrackingScreen), findsOneWidget);

      // Driver card MUST be in the tree
      expect(find.text('Abebe Kebede', skipOffstage: false), findsOneWidget);
      expect(find.text('Toyota Vitz • A12345', skipOffstage: false), findsOneWidget);
      expect(find.byIcon(Icons.call_rounded, skipOffstage: false), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded, skipOffstage: false), findsOneWidget);
    });

    testWidgets('Driver card displays vehicle name without trailing dot when plate is empty', (tester) async {
      final acceptedOrder = OrderModel(
        orderId: 'AMN-101',
        storeName: 'TRACTOR SPARE PARTS',
        storeImageUrl: '',
        orderDate: DateTime(2026, 11, 4),
        items: [],
        subtotal: 300,
        deliveryFee: 250,
        taxAndFees: 0,
        total: 550,
        deliveryAddress: 'Bole Road, Addis Ababa',
        status: OrderProgressStatus.accepted,
        estimatedArrival: '25 mins',
        storeType: StoreType.restaurant,
        driver: const DriverInfo(
          name: 'Dawit Yohannes',
          vehicle: 'Motorbike',
          plateNumber: '',
          rating: 5.0,
          photoUrl: '',
          phone: '+251922334455',
        ),
      );

      final orderCtrl = Get.put(OrderController());
      orderCtrl.activeOrder.value = acceptedOrder;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: '/tracking',
          getPages: [
            GetPage(
              name: '/tracking',
              page: () => const OrderTrackingScreen(),
              arguments: acceptedOrder,
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Dawit Yohannes', skipOffstage: false), findsOneWidget);
      expect(find.text('Motorbike', skipOffstage: false), findsOneWidget);
      expect(find.text('Motorbike • ', skipOffstage: false), findsNothing);
    });
  });
}
