import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/constants/pages.dart';
import 'package:delivery_app/controllers/profile_controller.dart';
import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:delivery_app/models/faq_model.dart';
import 'package:delivery_app/models/multilingual_string.dart';
import 'package:delivery_app/routes/app_pages.dart';
import 'package:delivery_app/screens/profile/faq_screen.dart';
import 'package:delivery_app/screens/profile/privacy_policy_screen.dart';
import 'package:delivery_app/screens/profile/terms_and_conditions_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    DioConfig.isTestMode = true;
    DioConfig.resetDio();
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('PrivacyPolicyScreen Tests', () {
    testWidgets('renders header, hero card, and fallback sections when privacy policy is empty', (tester) async {
      final profileController = Get.put(ProfileController());
      profileController.privacyPolicy.value = '';

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightTheme,
          home: const PrivacyPolicyScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Privacy Policy'), findsWidgets);
      expect(find.text('1. Information We Collect'), findsOneWidget);
      expect(find.text('2. Location & Tracking Data'), findsOneWidget);
      expect(find.text('3. How We Use Information'), findsOneWidget);
      expect(find.text('4. Data Protection & Security'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('renders custom privacy policy text when provided', (tester) async {
      final profileController = Get.put(ProfileController());
      profileController.privacyPolicy.value = 'Custom AMN Privacy Policy for Ethiopia delivery operations.';

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightTheme,
          home: const PrivacyPolicyScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Custom AMN Privacy Policy for Ethiopia delivery operations.'), findsOneWidget);
      expect(find.text('1. Information We Collect'), findsNothing);
    });
  });

  group('TermsAndConditionsScreen Tests', () {
    testWidgets('renders header, hero card, and fallback sections when terms are empty', (tester) async {
      final profileController = Get.put(ProfileController());
      profileController.termsAndConditions.value = '';

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightTheme,
          home: const TermsAndConditionsScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Terms & Conditions'), findsWidgets);
      expect(find.text('1. Acceptance of Terms'), findsOneWidget);
      expect(find.text('2. User Accounts & Registration'), findsOneWidget);
      expect(find.text('3. Orders & Merchant Availability'), findsOneWidget);
      expect(find.text('4. Payments, Pricing & Wallet'), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('renders custom terms text when provided', (tester) async {
      final profileController = Get.put(ProfileController());
      profileController.termsAndConditions.value = 'Custom AMN Terms of Service agreement details.';

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightTheme,
          home: const TermsAndConditionsScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Custom AMN Terms of Service agreement details.'), findsOneWidget);
      expect(find.text('1. Acceptance of Terms'), findsNothing);
    });
  });

  group('FaqScreen Tests', () {
    testWidgets('renders fallback FAQs, search bar, category chips, and allows expansion', (tester) async {
      final profileController = Get.put(ProfileController());
      profileController.faqs.clear();

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightTheme,
          home: const FaqScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('FAQs'), findsOneWidget);
      expect(find.text('How do I place an order on AMN Delivery?'), findsOneWidget);
      expect(find.text('What payment methods are accepted?'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Payment & Wallet'), findsOneWidget);

      // Tap on an expansion tile
      await tester.tap(find.text('What payment methods are accepted?'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Telebirr, Chapa'), findsOneWidget);

      // Test search filter
      await tester.enterText(find.byType(TextField), 'Wallet');
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('How does the AMN In-App Wallet work?'), findsOneWidget);
      expect(find.text('How do I place an order on AMN Delivery?'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('How do I place an order on AMN Delivery?'), findsOneWidget);
    });

    testWidgets('renders custom faqs assigned to ProfileController', (tester) async {
      final profileController = Get.put(ProfileController());
      profileController.faqs.assignAll([
        const FaqItem(
          id: 99,
          question: MultiLangString(en: 'Can I order groceries from AMN?'),
          answer: MultiLangString(en: 'Yes, AMN offers complete supermarket grocery delivery.'),
        ),
      ]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightTheme,
          home: const FaqScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Can I order groceries from AMN?'), findsOneWidget);

      await tester.tap(find.text('Can I order groceries from AMN?'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Yes, AMN offers complete supermarket grocery delivery.'), findsOneWidget);
    });
  });

  group('Routes Navigation Tests', () {
    testWidgets('AppRoutes opens dedicated screens properly', (tester) async {
      Get.put(ProfileController());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          defaultTransition: Transition.noTransition,
          initialRoute: AppRoutes.faq,
          getPages: AppPages.routes,
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FaqScreen), findsOneWidget);

      Get.toNamed(AppRoutes.privacyPolicy);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);

      Get.toNamed(AppRoutes.termsAndConditions);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TermsAndConditionsScreen), findsOneWidget);
    });
  });
}
