import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/constants/pages.dart';
import 'package:delivery_app/controllers/auth_controller.dart';
import 'package:delivery_app/controllers/profile_controller.dart';
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
  });
}
