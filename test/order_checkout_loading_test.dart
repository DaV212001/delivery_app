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
import 'package:delivery_app/controllers/restaurant_controller.dart';
import 'package:delivery_app/data/mock_data.dart';
import 'package:delivery_app/screens/checkout/cart_screen.dart';
import 'package:delivery_app/widgets/common/app_widgets.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'access_token': 'test_token_123',
      'user_id': 1,
      'user_name': 'Test User',
      'user_phone': '+251911000000',
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

  group('Order Placement Loading Indicator Tests', () {
    test('OrderController.placeOrder sets isPlacingOrder flag and returns success', () async {
      final orderController = Get.put(OrderController());
      expect(orderController.isPlacingOrder.value, false);

      final future = orderController.placeOrder(
        subtotal: 100.0,
        deliveryFee: 20.0,
        taxAndFees: 10.0,
        total: 130.0,
        deliveryAddress: 'Bole Road, Addis Ababa',
      );

      // Verify that while placeOrder is executing, the controller returns true on completion
      final result = await future;
      expect(result, true);
      expect(orderController.isPlacingOrder.value, false);
      expect(orderController.activeOrder.value, isNotNull);
    });

    testWidgets('CartScreen checkout AppButton displays CircularProgressIndicator when isPlacingOrder is true', (tester) async {
      Get.put(AuthController());
      final cartController = Get.put(CartController());
      final orderController = Get.put(OrderController());
      Get.put(RestaurantController());

      // Add an item to the cart so checkout UI renders
      cartController.addItem(
        item: MockData.organicAvocados,
        quantity: 2,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CartScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Initially, button shows text and is not loading
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Set isPlacingOrder to true
      orderController.isPlacingOrder.value = true;
      await tester.pump();

      // CircularProgressIndicator should now be visible inside the button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Reset isPlacingOrder to false
      orderController.isPlacingOrder.value = false;
      await tester.pump();

      // CircularProgressIndicator should disappear
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
