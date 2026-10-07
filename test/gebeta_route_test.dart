import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/constants/pages.dart';
import 'package:delivery_app/controllers/cart_controller.dart';
import 'package:delivery_app/controllers/order_controller.dart';
import 'package:delivery_app/data/mock_data.dart';
import 'package:delivery_app/models/gebeta_route.dart';
import 'package:delivery_app/models/order.dart';
import 'package:delivery_app/screens/orders/order_history_screen.dart';
import 'package:delivery_app/screens/tracking/order_tracking_screen.dart';
import 'package:delivery_app/services/gebeta_location_service.dart';
import 'package:delivery_app/widgets/map/gebeta_route_map.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'access_token': 'test_token_123',
      'user_id': 1,
    });
    await ConfigPreference.init();
    DioConfig.isTestMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
  });

  tearDown(() {
    Get.reset();
    DioConfig.isTestMode = false;
  });

  group('GebetaRoute Model and Calculations', () {
    test('formats distance and duration properly', () {
      final route1 = GebetaRoute(
        points: const [LatLng(9.0210, 38.7850), LatLng(9.0054, 38.7636)],
        totalDistanceMeters: 4508.0,
        timeTakenSeconds: 720.0,
      );

      expect(route1.formattedDistance, '4.5 km');
      expect(route1.formattedDuration, '12 mins');

      final routeShort = GebetaRoute(
        points: const [LatLng(9.0100, 38.7500), LatLng(9.0110, 38.7510)],
        totalDistanceMeters: 450.0,
        timeTakenSeconds: 45.0,
      );

      expect(routeShort.formattedDistance, '450 m');
      expect(routeShort.formattedDuration, '< 1 min');
    });

    test('calculates route center and bounding box correctly', () {
      final pts = const [
        LatLng(9.0000, 38.7000),
        LatLng(9.0200, 38.7500),
        LatLng(9.0400, 38.8000),
      ];
      final route = GebetaRoute(
        points: pts,
        totalDistanceMeters: 5000,
        timeTakenSeconds: 600,
      );

      expect(route.center.latitude, closeTo(9.0200, 0.001));
      expect(route.center.longitude, closeTo(38.7500, 0.001));

      final bounds = route.bounds;
      expect(bounds.southwest.latitude, lessThan(9.0000));
      expect(bounds.northeast.latitude, greaterThan(9.0400));
      expect(bounds.southwest.longitude, lessThan(38.7000));
      expect(bounds.northeast.longitude, greaterThan(38.8000));
    });

    test('interpolates progress accurately along the path', () {
      final pts = const [
        LatLng(9.0000, 38.7000),
        LatLng(9.0200, 38.7500),
        LatLng(9.0400, 38.8000),
      ];
      final route = GebetaRoute(
        points: pts,
        totalDistanceMeters: 5000,
        timeTakenSeconds: 600,
      );

      // 0.0 -> origin
      expect(route.positionAtProgress(0.0).latitude, closeTo(9.0000, 0.0001));
      expect(route.positionAtProgress(0.0).longitude, closeTo(38.7000, 0.0001));

      // 0.5 -> midpoint
      expect(route.positionAtProgress(0.5).latitude, closeTo(9.0200, 0.001));
      expect(route.positionAtProgress(0.5).longitude, closeTo(38.7500, 0.001));

      // 1.0 -> destination
      expect(route.positionAtProgress(1.0).latitude, closeTo(9.0400, 0.0001));
      expect(route.positionAtProgress(1.0).longitude, closeTo(38.8000, 0.0001));
    });

    test('generateFallbackRoute produces valid road coordinates', () {
      final fallback = GebetaRoute.generateFallbackRoute(
        originLat: 9.0210,
        originLng: 38.7850,
        destLat: 9.0054,
        destLng: 38.7636,
      );

      expect(fallback.points.length, greaterThan(10));
      expect(fallback.totalDistanceMeters, greaterThan(1000));
      expect(fallback.points.first.latitude, closeTo(9.0210, 0.001));
      expect(fallback.points.last.latitude, closeTo(9.0054, 0.001));
    });
  });

  group('GebetaLocationService Route Integration', () {
    test('getRoute returns cached or fallback route in test mode', () async {
      final route = await GebetaLocationService.getRoute(
        originLat: 9.0210,
        originLng: 38.7850,
        destLat: 9.0054,
        destLng: 38.7636,
      );

      expect(route.points.isNotEmpty, isTrue);
      expect(route.totalDistanceMeters, greaterThan(0));

      // Repeated call should retrieve cached result
      final cached = await GebetaLocationService.getRoute(
        originLat: 9.0210,
        originLng: 38.7850,
        destLat: 9.0054,
        destLng: 38.7636,
      );
      expect(identical(route, cached), isTrue);
    });
  });

  group('OrderModel Coordinates', () {
    test('effectiveStoreLatitude and effectiveDeliveryLatitude resolve accurately', () {
      final orderWithCoords = OrderModel(
        orderId: '#AMN-9999',
        storeName: 'Custom Store',
        storeImageUrl: 'https://example.com/logo.png',
        orderDate: DateTime.now(),
        items: const [],
        subtotal: 100,
        deliveryFee: 50,
        taxAndFees: 10,
        total: 160,
        deliveryAddress: 'Bole Olympia',
        status: OrderProgressStatus.onTheWay,
        estimatedArrival: '15 mins',
        storeLatitude: 9.0250,
        storeLongitude: 38.7650,
        deliveryLatitude: 9.0100,
        deliveryLongitude: 38.7500,
      );

      expect(orderWithCoords.effectiveStoreLatitude, 9.0250);
      expect(orderWithCoords.effectiveStoreLongitude, 38.7650);
      expect(orderWithCoords.effectiveDeliveryLatitude, 9.0100);
      expect(orderWithCoords.effectiveDeliveryLongitude, 38.7500);

      // Known store lookup fallback
      final orderWithLookup = OrderModel(
        orderId: '#AMN-8888',
        storeName: 'TechHub Express',
        storeImageUrl: 'https://example.com/logo.png',
        orderDate: DateTime.now(),
        items: const [],
        subtotal: 100,
        deliveryFee: 50,
        taxAndFees: 10,
        total: 160,
        deliveryAddress: 'Bole Olympia',
        status: OrderProgressStatus.onTheWay,
        estimatedArrival: '15 mins',
      );

      expect(orderWithLookup.effectiveStoreLatitude, 9.0210);
      expect(orderWithLookup.effectiveStoreLongitude, 38.7850);
    });
  });

  group('Order Detail Screen & GebetaRouteMap Widget', () {
    testWidgets('GebetaRouteMap renders smoothly for active order', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GebetaRouteMap(
              order: MockData.activeOrder,
              height: 250,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GebetaRouteMap), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('Gebeta Maps'), findsNothing);
    });

    testWidgets('GebetaRouteMap location button renders and handles tap cleanly', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: GebetaRouteMap(order: MockData.activeOrder),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final locationBtn = find.byIcon(Icons.my_location_rounded);
      expect(locationBtn, findsOneWidget);

      await tester.tap(locationBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('OrderTrackingScreen renders GebetaRouteMap and active order details', (tester) async {
      Get.put(OrderController());
      Get.put(CartController());

      await tester.pumpWidget(
        GetMaterialApp(
          home: const OrderTrackingScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GebetaRouteMap), findsOneWidget);
      expect(find.text('TechHub Express'), findsWidgets);
      expect(find.text('Bole Olympia, Addis Ababa'), findsWidgets);
      expect(find.text('Gebeta Maps'), findsNothing);
    });

    testWidgets('OrderTrackingScreen renders delivered past order as detail screen', (tester) async {
      Get.put(OrderController());
      Get.put(CartController());

      final deliveredOrder = MockData.pastOrders.first;

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(
              name: '/',
              page: () => const Scaffold(body: Text('Home')),
            ),
            GetPage(
              name: AppRoutes.orderDetail,
              page: () => const OrderTrackingScreen(),
            ),
          ],
        ),
      );

      Get.toNamed(AppRoutes.orderDetail, arguments: deliveredOrder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(GebetaRouteMap), findsOneWidget);
      expect(find.text(deliveredOrder.restaurantName), findsWidgets);
      expect(find.text('Delivered'), findsWidgets);
      expect(find.text('Reorder'), findsOneWidget);
    });

    testWidgets('OrderHistoryScreen past orders have route chip and navigate to details', (tester) async {
      Get.put(OrderController());
      Get.put(CartController());

      await tester.pumpWidget(
        GetMaterialApp(
          home: const OrderHistoryScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to Past Orders tab
      final pastTab = find.text('Past Orders');
      expect(pastTab, findsOneWidget);
      await tester.tap(pastTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('FreshMart Organics'), findsOneWidget);
      expect(find.text('Route'), findsWidgets);
    });
  });
}
