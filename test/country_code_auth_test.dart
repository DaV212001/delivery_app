import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/constants/api_endpoints.dart';
import 'package:delivery_app/controllers/auth_controller.dart';
import 'package:delivery_app/models/country_code.dart';
import 'package:delivery_app/screens/auth/login_screen.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioAdapter dioAdapter;
  late AuthController authController;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();

    DioConfig.isTestMode = true;
    DioConfig.resetDio();
    final dio = await DioConfig.dio();
    dioAdapter = DioAdapter(dio: dio);

    Get.reset();
    Get.testMode = true;
    authController = Get.put(AuthController());
  });

  tearDown(() {
    DioConfig.resetDio();
    DioConfig.isTestMode = false;
    Get.reset();
  });

  group('CountryCode Model Tests', () {
    test('Default country is Ethiopia (+251, ET)', () {
      expect(CountryCode.defaultCountry.name, 'Ethiopia');
      expect(CountryCode.defaultCountry.code, 'ET');
      expect(CountryCode.defaultCountry.dialCode, '+251');
      expect(CountryCode.defaultCountry.flag, isNotEmpty);
    });

    test('Contains major countries across continents', () {
      expect(CountryCode.allCountries.length, greaterThan(200));

      final us = CountryCode.allCountries.firstWhere((c) => c.code == 'US');
      expect(us.name, 'United States');
      expect(us.dialCode, '+1');

      final ke = CountryCode.allCountries.firstWhere((c) => c.code == 'KE');
      expect(ke.name, 'Kenya');
      expect(ke.dialCode, '+254');

      final gb = CountryCode.allCountries.firstWhere((c) => c.code == 'GB');
      expect(gb.name, 'United Kingdom');
      expect(gb.dialCode, '+44');

      final ae = CountryCode.allCountries.firstWhere((c) => c.code == 'AE');
      expect(ae.name, 'United Arab Emirates');
      expect(ae.dialCode, '+971');
    });

    test('Search filters by country name, code, or dial code', () {
      final ethiopiaResults = CountryCode.search('ethiopia');
      expect(ethiopiaResults.any((c) => c.code == 'ET'), isTrue);

      final dial254 = CountryCode.search('+254');
      expect(dial254.any((c) => c.code == 'KE'), isTrue);

      final codeUs = CountryCode.search('US');
      expect(codeUs.any((c) => c.code == 'US'), isTrue);
    });

    test('findByPhoneNumber identifies country from international number', () {
      final keCountry = CountryCode.findByPhoneNumber('+254712345678');
      expect(keCountry?.code, 'KE');

      final usCountry = CountryCode.findByPhoneNumber('+12025550123');
      expect(usCountry?.code, 'US');

      final etCountry = CountryCode.findByPhoneNumber('251911058179');
      expect(etCountry?.code, 'ET');
    });
  });

  group('AuthController - Country Code & Phone Sanitization Tests', () {
    test('Ethiopian backward compatibility is preserved without dial code parameter', () {
      expect(AuthController.sanitizePhone('0911058179'), '251911058179');
      expect(AuthController.sanitizePhone('911058179'), '251911058179');
      expect(AuthController.sanitizePhone('+251911058179'), '251911058179');
      expect(AuthController.sanitizePhone('251 911 058 179'), '251911058179');
    });

    test('Formats international numbers with provided country dial codes', () {
      // Kenya (+254) with trunk prefix 0 stripped
      expect(AuthController.sanitizePhone('0712345678', '+254'), '254712345678');
      expect(AuthController.sanitizePhone('712345678', '+254'), '254712345678');
      expect(AuthController.sanitizePhone('+254712345678', '+254'), '254712345678');

      // United States (+1)
      expect(AuthController.sanitizePhone('2025550123', '+1'), '12025550123');
      expect(AuthController.sanitizePhone('+12025550123', '+1'), '12025550123');

      // United Kingdom (+44) with trunk prefix 0 stripped
      expect(AuthController.sanitizePhone('07911123456', '+44'), '447911123456');

      // United Arab Emirates (+971)
      expect(AuthController.sanitizePhone('501234567', '+971'), '971501234567');
    });

    test('Preserves explicit + international numbers even without dial code', () {
      expect(AuthController.sanitizePhone('+1 415 555 2671'), '14155552671');
      expect(AuthController.sanitizePhone('+44 20 7946 0991'), '442079460991');
    });

    test('register forwards sanitized international phone number to backend', () async {
      dioAdapter.onPost(
        ApiEndpoints.customerRegister,
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'id': 99,
            'token': 'mock-jwt-token',
            'f_name': 'John',
            'l_name': 'Doe',
            'phone': '254712345678',
            'email': 'john@example.com',
          },
        }),
        data: Matchers.any,
      );

      dioAdapter.onPost(
        ApiEndpoints.customerSendOtp,
        (server) => server.reply(200, {
          'success': true,
          'message': 'OTP sent',
        }),
        data: Matchers.any,
      );

      await authController.register(
        firstName: 'John',
        lastName: 'Doe',
        phone: '0712345678',
        email: 'john@example.com',
        password: '1234',
        countryCode: '+254',
      );

      expect(authController.user.phone, '254712345678');
    });
  });

  group('LoginScreen & Country Picker Widget Tests', () {
    testWidgets('LoginScreen displays default country code (+251) and allows picking country', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en'),
          home: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check that Ethiopia +251 is shown in prefix
      expect(find.text('+251'), findsOneWidget);

      // Tap on the country code picker button
      await tester.tap(find.text('+251'));
      await tester.pumpAndSettle();

      // Bottom sheet should be open with search and country list
      expect(find.byType(TextField), findsAtLeastNWidgets(1));

      // Search for Kenya
      await tester.enterText(find.byType(TextField).last, 'Kenya');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Kenya'), findsOneWidget);
      expect(find.text('+254'), findsOneWidget);

      // Select Kenya
      await tester.tap(find.widgetWithText(ListTile, 'Kenya'));
      await tester.pumpAndSettle();

      // Now prefix should display +254
      expect(find.text('+254'), findsOneWidget);
    });
  });
}
