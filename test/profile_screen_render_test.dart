import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/controllers/auth_controller.dart';
import 'package:delivery_app/controllers/cart_controller.dart';
import 'package:delivery_app/controllers/order_controller.dart';
import 'package:delivery_app/controllers/profile_controller.dart';
import 'package:delivery_app/controllers/restaurant_controller.dart';
import 'package:delivery_app/core/theme/theme_controller.dart';
import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:delivery_app/screens/main_navigation.dart';
import 'package:delivery_app/screens/profile/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ProfileScreen renders Guest Mode correctly when not logged in', (tester) async {
    DioConfig.isTestMode = true;
    DioConfig.resetDio();
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();

    Get.reset();
    Get.put(ThemeController());
    Get.put(AuthController());
    Get.put(ProfileController());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const ProfileScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Verify Guest Mode UI
    expect(find.text('Welcome, Guest'), findsOneWidget);
    expect(find.text('Sign In or Register'), findsOneWidget);
    // Wallet card and Top Up should NOT be visible in guest mode
    expect(find.text('Top Up'), findsNothing);
    expect(find.text('AMN Wallet Balance'), findsNothing);
    expect(find.text('Log Out'), findsNothing);

    // Preferences & Support should still be accessible
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Help Center'), findsOneWidget);
    expect(find.text('Privacy & Terms'), findsOneWidget);

    final exception = tester.takeException();
    expect(exception, isNull);
  });

  testWidgets('ProfileScreen renders Authenticated Mode when logged in', (tester) async {
    DioConfig.isTestMode = true;
    DioConfig.resetDio();
    SharedPreferences.setMockInitialValues({
      'user_id': 1,
      'access_token': 'mock_token_1',
      'user_name': 'Abel Tesfaye',
      'user_phone': '+251911234567',
    });
    await ConfigPreference.init();

    Get.reset();
    Get.put(ThemeController());
    Get.put(AuthController());
    Get.put(ProfileController());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const ProfileScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Verify Authenticated Mode UI
    expect(find.text('Welcome, Guest'), findsNothing);
    expect(find.text('AMN Wallet Balance'), findsOneWidget);
    expect(find.text('Top Up'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);

    // Tap "Top Up" button
    final topUpFinder = find.text('Top Up');
    await tester.tap(topUpFinder);
    await tester.pump(const Duration(milliseconds: 100));

    // Check dialog appeared
    expect(find.text('Top Up Wallet'), findsOneWidget);
    // Tap Cancel
    final cancelFinder = find.text('Cancel');
    expect(cancelFinder, findsOneWidget);
    await tester.tap(cancelFinder);
    await tester.pump(const Duration(milliseconds: 100));

    final exception = tester.takeException();
    expect(exception, isNull);
  });

  testWidgets('MainNavigationScreen switch to Profile tab', (tester) async {
    DioConfig.isTestMode = true;
    DioConfig.resetDio();
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();

    Get.reset();
    Get.put(ThemeController());
    Get.put(AuthController());
    Get.put(RestaurantController());
    Get.put(CartController());
    Get.put(OrderController());
    Get.put(ProfileController());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const MainNavigationScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Profile tab
    final profileTabFinder = find.text('Profile');
    expect(profileTabFinder, findsOneWidget);
    await tester.tap(profileTabFinder);
    await tester.pump(const Duration(milliseconds: 100));

    final exception = tester.takeException();
    if (exception != null) {
      // ignore: avoid_print
      print('CAUGHT EXCEPTION IN MAIN NAV PROFILE: $exception');
    }
    expect(exception, isNull, reason: 'Switching to Profile tab threw: $exception');
  });

  testWidgets('ProfileScreen with empty avatarUrl or null-like fields', (tester) async {
    DioConfig.isTestMode = true;
    DioConfig.resetDio();
    SharedPreferences.setMockInitialValues({
      'user_id': 1,
      'access_token': 'mock_token_1',
    });
    await ConfigPreference.init();

    Get.reset();
    Get.put(ThemeController());
    final auth = Get.put(AuthController());
    Get.put(ProfileController());

    // Set avatarUrl to empty string
    auth.user = auth.user.copyWith(avatarUrl: '');

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const ProfileScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final exception = tester.takeException();
    if (exception != null) {
      // ignore: avoid_print
      print('CAUGHT EXCEPTION WITH EMPTY AVATAR: $exception');
    }
    expect(exception, isNull);
  });
}
