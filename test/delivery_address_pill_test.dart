import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/controllers/auth_controller.dart';
import 'package:delivery_app/controllers/cart_controller.dart';
import 'package:delivery_app/controllers/restaurant_controller.dart';
import 'package:delivery_app/screens/home/home_screen.dart';
import 'package:delivery_app/screens/home/widgets/delivery_address_pill.dart';
import 'package:delivery_app/services/user_location_service.dart';
import 'package:delivery_app/utils/location_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    DioConfig.isTestMode = true;
    DioConfig.resetDio();
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();
    Get.reset();
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('en', 'US');
  });

  tearDown(() {
    Get.reset();
    DioConfig.isTestMode = false;
  });

  group('Gebeta Address Prettification Tests', () {
    test('prettifyAddress transforms lowercase gebeta output to proper title case', () {
      const raw = 'bole medhane alem, addis ababa, ethiopia';
      final formatted = LocationUtils.prettifyAddress(raw);
      expect(formatted, 'Bole Medhane Alem, Addis Ababa, Ethiopia');
    });

    test('prettifyAddressCompact drops trailing Ethiopia when city exists and keeps primary areas', () {
      const raw = 'bole medhane alem, addis ababa, ethiopia';
      final compact = LocationUtils.prettifyAddressCompact(raw);
      expect(compact, 'Bole Medhane Alem, Addis Ababa');
    });

    test('prettifyAddress capitalizes acronyms like CMC, CBE, ATM', () {
      const raw = 'cmc michael, yeka, addis ababa';
      expect(LocationUtils.prettifyAddress(raw), 'CMC Michael, Yeka, Addis Ababa');

      const rawAtm = 'cbe bank atm, mexico square, kirkos, addis ababa';
      expect(LocationUtils.prettifyAddress(rawAtm), 'CBE Bank ATM, Mexico Square, Kirkos, Addis Ababa');
    });

    test('prettifyAddress standardizes abbreviations like st., rd., ave.', () {
      const raw = 'st. gebriel hospital, 22 mazoria, bole, addis ababa';
      expect(LocationUtils.prettifyAddress(raw), 'St. Gebriel Hospital, 22 Mazoria, Bole, Addis Ababa');
    });

    test('prettifyAddress deduplicates redundant segments', () {
      const raw = 'addis ababa, addis ababa, ethiopia';
      expect(LocationUtils.prettifyAddress(raw), 'Addis Ababa, Ethiopia');
    });

    test('prettifyAddress handles hyphens and numbers gracefully', () {
      const raw = 'bole-arabsa, woreda 03, bole';
      expect(LocationUtils.prettifyAddress(raw), 'Bole-Arabsa, Woreda 03, Bole');
    });

    test('prettifyAddress handles null, empty, and coordinate fallback', () {
      expect(LocationUtils.prettifyAddress(null), '');
      expect(LocationUtils.prettifyAddress('   '), '');
      expect(
        LocationUtils.prettifyAddress('9.0104, 38.7617 (Addis Ababa)'),
        '9.0104, 38.7617 (Addis Ababa)',
      );
    });
  });

  group('DeliveryAddressPill & UserLocationService Tracking Tests', () {
    test('UserLocationService tracking methods start and stop cleanly', () {
      final service = Get.put(UserLocationService());
      expect(service.isTrackingLocation.value, isFalse);

      service.startLocationTracking();
      // In test mode, startLocationTracking returns early to prevent platform channel hanging
      expect(service.isTrackingLocation.value, isFalse);

      service.stopLocationTracking();
      expect(service.isTrackingLocation.value, isFalse);
    });

    testWidgets('DeliveryAddressPill renders reverse-geocoded and prettified address on HomeScreen', (tester) async {
      Get.put(UserLocationService());
      Get.put(RestaurantController());
      Get.put(AuthController());
      final cart = Get.put(CartController());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const HomeScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Verify DeliveryAddressPill exists at top
      expect(find.byType(DeliveryAddressPill), findsOneWidget);

      // By default in test mode, current location defaults to Meskel Square, Addis Ababa
      expect(find.text('Meskel Square, Addis Ababa'), findsOneWidget);

      // Now set delivery address to a lowercase Gebeta address
      cart.deliveryAddress.value = 'bole medhane alem, addis ababa, ethiopia';
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the address inside the pill is immediately prettified and compact
      expect(find.text('Bole Medhane Alem, Addis Ababa'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsWidgets);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    });

    testWidgets('Tapping DeliveryAddressPill opens address selection modal bottom sheet', (tester) async {
      Get.put(UserLocationService());
      Get.put(RestaurantController());
      Get.put(AuthController());
      Get.put(CartController());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const HomeScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Tap on the DeliveryAddressPill
      await tester.tap(find.byType(DeliveryAddressPill));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify bottom sheet title and options are displayed
      expect(find.text('Delivery Address'), findsOneWidget);
      expect(find.text('Use Current Location'), findsOneWidget);
      expect(find.text('Choose on Gebeta Map'), findsOneWidget);
      expect(find.text('Saved Addresses'), findsOneWidget);
      expect(find.text('GPS'), findsOneWidget);
    });

    testWidgets('Selecting Use Current Location in modal triggers location refresh and closes sheet', (tester) async {
      Get.put(UserLocationService());
      Get.put(RestaurantController());
      Get.put(AuthController());
      final cart = Get.put(CartController());
      cart.deliveryAddress.value = 'old custom address';

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const HomeScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Tap pill to open modal
      await tester.tap(find.byType(DeliveryAddressPill));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Use Current Location
      await tester.tap(find.text('Use Current Location'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Modal is dismissed
      expect(find.text('Choose on Gebeta Map'), findsNothing);

      // Cart delivery address was updated
      expect(cart.deliveryAddress.value, contains('Addis Ababa'));
    });

    testWidgets('DeliveryAddressPill is aligned to start (left) on HomeScreen', (tester) async {
      Get.put(UserLocationService());
      Get.put(RestaurantController());
      Get.put(AuthController());
      Get.put(CartController());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const HomeScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Find the Align widget wrapping the pill
      final alignFinder = find.ancestor(
        of: find.byType(DeliveryAddressPill),
        matching: find.byType(Align),
      );
      expect(alignFinder, findsOneWidget);

      final alignWidget = tester.widget<Align>(alignFinder);
      expect(alignWidget.alignment, AlignmentDirectional.centerStart);
    });

    testWidgets('Address selection modal renders on narrow screen (210px width) without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(210 * 3.0, 600 * 3.0);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Get.put(UserLocationService());
      Get.put(RestaurantController());
      Get.put(AuthController());
      Get.put(CartController());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const HomeScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Tap pill to open modal on narrow screen
      await tester.tap(find.byType(DeliveryAddressPill));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify no exceptions were thrown and options render
      expect(find.text('Delivery Address'), findsOneWidget);
      expect(find.text('Use Current Location'), findsOneWidget);
      expect(find.text('GPS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
