import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/controllers/auth_controller.dart';
import 'package:delivery_app/controllers/cart_controller.dart';
import 'package:delivery_app/controllers/order_controller.dart';
import 'package:delivery_app/screens/orders/order_history_screen.dart';
import 'package:delivery_app/screens/tracking/order_tracking_screen.dart';
import 'package:delivery_app/utils/api_call_status.dart';
import 'package:delivery_app/widgets/skeletons/skeleton_loaders.dart';

void main() {
  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({'user_id': 2});
    await ConfigPreference.init();
  });

  group('Order Screens Skeleton Loader Tests', () {
    testWidgets('ShimmerOrderTrackingSkeleton renders without errors or overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShimmerOrderTrackingSkeleton(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ShimmerOrderTrackingSkeleton), findsOneWidget);
      expect(find.byType(ShimmerBox), findsWidgets);
    });

    testWidgets('OrderTrackingScreen displays ShimmerOrderTrackingSkeleton when loading', (tester) async {
      final orderController = Get.put(OrderController());
      orderController.status.value = ApiCallStatus.loading;
      orderController.activeOrder.value = null;
      orderController.activeOrders.clear();
      Get.put(CartController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: OrderTrackingScreen(),
        ),
      );

      await tester.pump();

      // Verify skeleton is displayed while loading
      expect(find.byType(ShimmerOrderTrackingSkeleton), findsOneWidget);
    });

    testWidgets('OrderHistoryScreen displays ShimmerOrderCardSkeleton in active tab when loading', (tester) async {
      Get.put(AuthController());
      final orderController = Get.put(OrderController());
      orderController.status.value = ApiCallStatus.loading;
      orderController.activeOrders.clear();
      orderController.activeOrder.value = null;
      Get.put(CartController());

      await tester.pumpWidget(
        const GetMaterialApp(
          home: OrderHistoryScreen(),
        ),
      );

      await tester.pump();

      // Verify active tab shows ShimmerOrderCardSkeleton
      expect(find.byType(ShimmerOrderCardSkeleton), findsWidgets);
    });
  });
}
