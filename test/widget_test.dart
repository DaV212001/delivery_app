import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/controllers/auth_controller.dart';
import 'package:delivery_app/controllers/cart_controller.dart';
import 'package:delivery_app/controllers/restaurant_controller.dart';
import 'package:delivery_app/data/mock_data.dart';
import 'package:delivery_app/models/delivery_item.dart';
import 'package:delivery_app/controllers/order_controller.dart';
import 'package:delivery_app/screens/category/category_stores_screen.dart';
import 'package:delivery_app/screens/home/home_screen.dart';
import 'package:delivery_app/screens/home/widgets/promotional_carousel_section.dart';
import 'package:delivery_app/screens/orders/order_history_screen.dart';
import 'package:delivery_app/screens/restaurant/restaurant_detail_screen.dart';
import 'package:delivery_app/screens/tracking/order_tracking_screen.dart';
import 'package:delivery_app/widgets/common/app_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AMN Delivery Universal CartController Tests', () {
    late CartController cartController;

    setUp(() {
      cartController = CartController();
      cartController.clearCart();
    });

    test('Initial cart can be cleared', () {
      expect(cartController.items.isEmpty, true);
      expect(cartController.totalItemCount, 0);
      expect(cartController.total, 0.0);
    });

    test('Adding groceries updates count and subtotal', () {
      cartController.addItem(
        item: MockData.organicAvocados,
        quantity: 2,
        selectedVariant: 'Ripe & Ready',
      );

      expect(cartController.items.length, 1);
      expect(cartController.totalItemCount, 2);
      expect(cartController.subtotal, closeTo(9.98, 0.01)); // 2 * 4.99
    });

    test('Adding electronics item with warranty addon calculates correctly', () {
      cartController.addItem(
        item: MockData.ancEarbuds,
        quantity: 1,
        selectedVariant: 'Midnight Black',
        selectedAddons: [
          const CustomizationAddon(id: 'add_warranty', name: '2-Year Protection Plan', price: 14.99),
        ],
      );

      expect(cartController.items.first.unitPrice, closeTo(104.98, 0.01)); // 89.99 + 14.99
      expect(cartController.subtotal, closeTo(104.98, 0.01));
    });

    test('Adding courier delivery item works properly', () {
      cartController.addItem(
        item: MockData.onDemandParcel,
        quantity: 1,
        selectedVariant: 'Small Box (< 3kg)',
        selectedAddons: [
          const CustomizationAddon(id: 'add_fragile', name: 'Fragile Care', price: 3.00),
        ],
      );

      expect(cartController.items.first.unitPrice, closeTo(12.99, 0.01));
    });

    test('Increment and decrement quantity work correctly', () {
      cartController.addItem(
        item: MockData.fastChargingCable,
        quantity: 1,
      );
      final id = cartController.items.first.id;

      cartController.incrementQuantity(id);
      expect(cartController.totalItemCount, 2);

      cartController.decrementQuantity(id);
      expect(cartController.totalItemCount, 1);

      cartController.decrementQuantity(id);
      expect(cartController.totalItemCount, 0);
    });

    test('Promo code AMN applies free delivery', () {
      cartController.addItem(
        item: MockData.foundryClassic,
        quantity: 1,
      );
      expect(cartController.deliveryFee, 2.99);

      cartController.applyPromo('AMN');
      expect(cartController.promoDiscount.value, 2.99);
    });
  });

  group('HomeScreen Tests', () {
    setUp(() {
      DioConfig.isTestMode = true;
      DioConfig.resetDio();
    });

    tearDown(() {
      DioConfig.resetDio();
      DioConfig.isTestMode = false;
    });

    testWidgets('HomeScreen builds and displays circular category row', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await ConfigPreference.init();
      Get.reset();
      Get.put(RestaurantController());
      Get.put(AuthController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Ethiopost'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Electronics'), findsOneWidget);
      expect(find.text('Books'), findsOneWidget);
    });

    testWidgets('HomeScreen renders PromotionalCarouselSection, Special Offers, and All Restaurants Nearby', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await ConfigPreference.init();
      Get.reset();
      Get.put(RestaurantController());
      Get.put(AuthController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 700));

      // Verify PromotionalCarouselSection is present at top
      expect(find.byType(PromotionalCarouselSection), findsOneWidget);

      // Verify translucent pill header elements
      expect(find.text('Delivering to'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);

      // Verify search bar in curved card
      expect(find.text('Search items, stores, essentials...'), findsOneWidget);

      // Verify Special Offers section with discount badges and filter button
      expect(find.text('Special Offers'), findsOneWidget);
      expect(find.text('25.0% OFF'), findsWidgets);
      expect(find.text('J&J Chicken'), findsOneWidget);
      expect(find.text('Injoy Burger | Meskel Flower'), findsWidgets);

      // Verify All Restaurants Nearby section with filter button and cards
      expect(find.text('All Restaurants Nearby'), findsOneWidget);
      expect(find.text('Filter'), findsWidgets);
      expect(find.text('Chanoly Noodles | Olympia'), findsWidgets);
      expect(find.text('Around 1KM'), findsWidgets);
      expect(find.text('Around 41 min'), findsWidgets);
      expect(find.text('Avg 778 Br per person'), findsOneWidget);
      expect(find.text('Delivery Fee starting from 132 Br'), findsOneWidget);
    });

    testWidgets('Tapping circular category navigates to CategoryStoresScreen with Hero animation', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await ConfigPreference.init();
      Get.reset();
      Get.put(RestaurantController());
      Get.put(AuthController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 700));

      // Find Ethiopost circular category
      final ethiopostFinder = find.text('Ethiopost');
      expect(ethiopostFinder, findsOneWidget);

      // Verify Hero widget with category tag exists on HomeScreen
      expect(find.byWidgetPredicate(
        (w) => w is Hero && w.tag == 'category_icon_cat_ethiopost',
      ), findsOneWidget);

      // Tap Ethiopost category
      await tester.tap(ethiopostFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify navigated to CategoryStoresScreen
      expect(find.byType(CategoryStoresScreen), findsOneWidget);
      expect(find.byWidgetPredicate(
        (w) => w is Hero && w.tag == 'category_icon_cat_ethiopost',
      ), findsOneWidget);
      expect(find.text('Search in Ethiopost...'), findsOneWidget);

      // Verify Express Parcel Courier is listed under Ethiopost/courier
      expect(find.text('Express Parcel Courier | Stadium'), findsOneWidget);
    });
  });

  group('Responsive Layout & Overflow Tests', () {
    testWidgets('StoreDetailScreen renders on narrow screen (280px width) without RenderFlex overflow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await ConfigPreference.init();
      Get.reset();
      Get.put(RestaurantController());
      Get.put(CartController());

      // Set physical size to narrow width (280px)
      tester.view.physicalSize = const Size(280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        GetMaterialApp(
          home: RestaurantDetailScreen(
            restaurant: MockData.restaurants.first,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(RestaurantDetailScreen), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Delivery'), findsOneWidget);
    });

    testWidgets('HomeScreen featured card renders on narrow screen (280px width) without RenderFlex overflow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await ConfigPreference.init();
      Get.reset();
      Get.put(RestaurantController());
      Get.put(AuthController());
      Get.put(CartController());

      tester.view.physicalSize = const Size(280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('AppButton with small width (110px/120px) renders without RenderFlex overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                children: [
                  AppButton(
                    width: 120,
                    height: 40,
                    text: 'Track Live',
                  ),
                  AppButton(
                    width: 110,
                    height: 38,
                    text: 'Reorder',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Track Live'), findsOneWidget);
      expect(find.text('Reorder'), findsOneWidget);
    });

    testWidgets('OrderHistoryScreen renders on narrow screen (280px width) without overflow', (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_id': 1,
        'access_token': 'mock_token_1',
      });
      await ConfigPreference.init();
      Get.reset();
      Get.put(AuthController());
      final orderCtrl = Get.put(OrderController());
      orderCtrl.activeOrder.value = MockData.activeOrder;
      Get.put(CartController());

      tester.view.physicalSize = const Size(280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: OrderHistoryScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(OrderHistoryScreen), findsOneWidget);
      expect(find.text('Track Live'), findsOneWidget);
    });

    testWidgets('OrderTrackingScreen renders on narrow screen (280px width) without RenderFlex overflow', (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_id': 1,
        'access_token': 'mock_token_1',
      });
      await ConfigPreference.init();
      Get.reset();
      Get.put(AuthController());
      final orderCtrl = Get.put(OrderController());
      orderCtrl.activeOrder.value = MockData.activeOrder;
      Get.put(CartController());

      tester.view.physicalSize = const Size(280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: OrderTrackingScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(OrderTrackingScreen), findsOneWidget);
      expect(find.text('Order Details'), findsOneWidget);
      expect(find.text('Delivery Address'), findsOneWidget);
    });
  });
}
