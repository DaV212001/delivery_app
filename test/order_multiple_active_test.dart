import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/controllers/auth_controller.dart';
import 'package:delivery_app/controllers/cart_controller.dart';
import 'package:delivery_app/controllers/order_controller.dart';
import 'package:delivery_app/models/order.dart';
import 'package:delivery_app/models/store.dart';
import 'package:delivery_app/screens/orders/order_history_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multiple Active Orders Support', () {
    testWidgets('OrderHistoryScreen renders all active orders in activeOrders list', (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_id': 2,
        'access_token': 'mock_token',
      });
      await ConfigPreference.init();

      Get.reset();
      Get.put(AuthController());
      final orderCtrl = Get.put(OrderController());
      Get.put(CartController());

      final order1 = OrderModel(
        orderId: '#AMN-15',
        storeName: 'Burger Palace',
        storeImageUrl: 'https://example.com/burger.jpg',
        orderDate: DateTime(2026, 10, 5),
        items: const [],
        subtotal: 77.09,
        deliveryFee: 0,
        taxAndFees: 0,
        total: 77.09,
        deliveryAddress: 'Office',
        status: OrderProgressStatus.accepted,
        estimatedArrival: '20 mins',
        storeType: StoreType.retail,
      );

      final order2 = OrderModel(
        orderId: '#AMN-24',
        storeName: 'Pizza Heaven',
        storeImageUrl: 'https://example.com/pizza.jpg',
        orderDate: DateTime(2026, 10, 13),
        items: const [],
        subtotal: 21728.39,
        deliveryFee: 0,
        taxAndFees: 0,
        total: 21728.39,
        deliveryAddress: 'niyo',
        status: OrderProgressStatus.driverToShop,
        estimatedArrival: '35 mins',
        storeType: StoreType.retail,
      );

      // Populate multiple active orders
      orderCtrl.activeOrders.assignAll([order1, order2]);
      orderCtrl.activeOrder.value = order1;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const OrderHistoryScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Both orders should be visible on the screen
      expect(find.text('#AMN-15'), findsOneWidget);
      expect(find.text('#AMN-24'), findsOneWidget);
      expect(find.text('Burger Palace'), findsOneWidget);
      expect(find.text('Pizza Heaven'), findsOneWidget);
      expect(find.text('Track Live'), findsNWidgets(2));
    });
  });
}
