import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/constants/pages.dart';
import 'package:delivery_app/controllers/auth_controller.dart';
import 'package:delivery_app/controllers/courier_controller.dart';
import 'package:delivery_app/controllers/profile_controller.dart';
import 'package:delivery_app/screens/courier/courier_history_screen.dart';
import 'package:delivery_app/screens/courier/courier_screen.dart';
import 'package:delivery_app/screens/home/widgets/home_courier_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();
    DioConfig.isTestMode = true;
    Get.reset();
    Get.put(AuthController());
    Get.put(ProfileController());
  });

  tearDown(() {
    Get.reset();
  });

  group('Courier Feature Widget Tests', () {
    testWidgets('HomeCourierSection renders banner title, COURIER text, and subtext',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: HomeCourierSection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thinking of sending anything?'), findsOneWidget);
      expect(find.text('COURIER'), findsOneWidget);
      expect(find.text('send and receive with courier'), findsOneWidget);
      expect(find.byType(CourierIllustration), findsOneWidget);
    });

    testWidgets('CourierScreen renders all sections, address fields, and continue button',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.courier,
          getPages: [
            GetPage(name: AppRoutes.courier, page: () => const CourierScreen()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Check Header
      expect(find.text('Courier Delivery'), findsOneWidget);

      // Check Address Cards
      expect(find.text('Pick-up Address'), findsOneWidget);
      expect(find.text('Drop-off Address'), findsOneWidget);

      // Check Sections
      expect(find.text('Sender Information'), findsOneWidget);
      expect(find.text('Receiver Information'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);

      // Check Continue button
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('CourierScreen updates receiver phone character counter dynamically',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.courier,
          getPages: [
            GetPage(name: AppRoutes.courier, page: () => const CourierScreen()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Initial counter for receiver phone is 0/9
      expect(find.text('0/9'), findsOneWidget);

      // Enter digits into receiver phone field
      final receiverPhoneFinder = find.widgetWithText(TextField, '+251  9XXXXXXXX');
      expect(receiverPhoneFinder, findsOneWidget);

      await tester.enterText(receiverPhoneFinder, '911223344');
      await tester.pumpAndSettle();

      // Counter should now show 9/9
      expect(find.text('9/9'), findsWidgets);
    });

    testWidgets('CourierScreen shows validation snackbar when fields are missing',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.courier,
          getPages: [
            GetPage(name: AppRoutes.courier, page: () => const CourierScreen()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap Continue without selecting pick-up address
      final continueButton = find.text('Continue');
      await tester.tap(continueButton);
      await tester.pump();

      // Expect snackbar with validation message
      expect(find.text('Please specify pick-up address'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('CourierScreen displays Map selection badges on address cards',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.courier,
          getPages: [
            GetPage(name: AppRoutes.courier, page: () => const CourierScreen()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Check map badges on pick-up and drop-off cards
      expect(find.text('Map'), findsNWidgets(2));
      expect(find.byIcon(Icons.map_rounded), findsNWidgets(2));
    });

    testWidgets('CourierScreen displays distance & fare container when coordinates are set',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.courier,
          getPages: [
            GetPage(name: AppRoutes.courier, page: () => const CourierScreen()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Programmatically set coordinates via CourierController
      final controller = Get.find<CourierController>();
      controller.setLocation(
        isPickup: true,
        lat: 9.02497,
        lng: 38.74689,
        address: 'Bole Medhanialem',
      );
      controller.setLocation(
        isPickup: false,
        lat: 8.98060,
        lng: 38.75780,
        address: 'Sarbet',
      );

      await tester.pumpAndSettle();

      // Check route calculation bar appeared
      expect(find.byIcon(Icons.route_rounded), findsOneWidget);
      expect(find.textContaining('km'), findsWidgets);
      expect(find.textContaining('ETB'), findsWidgets);
    });

    testWidgets('CourierScreen has History AppBar action that opens tabbed CourierHistoryScreen',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.courier,
          getPages: [
            GetPage(name: AppRoutes.courier, page: () => const CourierScreen()),
            GetPage(name: AppRoutes.courierHistory, page: () => const CourierHistoryScreen()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Find AppBar history icon
      final historyIcon = find.byIcon(Icons.history_rounded);
      expect(historyIcon, findsOneWidget);

      // Verify active badge counter shows up
      expect(find.text('1'), findsWidgets);

      // Tap history icon to navigate to CourierHistoryScreen
      await tester.tap(historyIcon);
      await tester.pumpAndSettle();

      // Verify on CourierHistoryScreen
      expect(find.text('My Deliveries'), findsOneWidget);

      // Verify tabs exist: "Active" and "Past Deliveries"
      expect(find.widgetWithText(Tab, 'Past Deliveries'), findsOneWidget);

      // In test mode, active order #CR-1 is loaded in Active tab
      expect(find.text('#CR-1'), findsOneWidget);
      expect(find.text('To: Bluye'), findsOneWidget);

      // Tap on "Past Deliveries" tab
      final pastTab = find.widgetWithText(Tab, 'Past Deliveries');
      await tester.tap(pastTab);
      await tester.pumpAndSettle();

      // Verify past order #CR-99 is loaded
      expect(find.text('#CR-99'), findsOneWidget);
      expect(find.text('To: Kidus'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
    });

    testWidgets('CourierScreen renders Delivery Options and Payment Methods',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.courier,
          getPages: [
            GetPage(name: AppRoutes.courier, page: () => const CourierScreen()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Check delivery options section header
      expect(find.text('Delivery Options'), findsOneWidget);
      expect(find.text('Motorbike'), findsOneWidget);

      // Scroll to find Payment Method section
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      final paymentTitle = find.text('Payment Method');
      expect(paymentTitle, findsOneWidget);
      expect(find.text('Cash on Delivery'), findsOneWidget);
      expect(find.text('Chapa'), findsOneWidget);
      expect(find.text('AMN Wallet'), findsOneWidget);
    });

    testWidgets('Selecting wallet shows Wallet Balance Card with Top-up button',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.courier,
          getPages: [
            GetPage(name: AppRoutes.courier, page: () => const CourierScreen()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Initially Top up button is not shown
      expect(find.text('Top Up'), findsNothing);

      // Scroll and tap AMN Wallet
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      final walletOption = find.text('AMN Wallet');
      expect(walletOption, findsOneWidget);
      await tester.tap(walletOption);
      await tester.pumpAndSettle();

      // Wallet balance card and top up button are now visible
      expect(find.text('Top Up'), findsOneWidget);
    });
  });
}
