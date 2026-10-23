import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/constants/api_endpoints.dart';
import 'package:delivery_app/constants/pages.dart';
import 'package:delivery_app/controllers/auth_controller.dart';
import 'package:delivery_app/models/country_code.dart';
import 'package:delivery_app/routes/app_pages.dart';
import 'package:delivery_app/screens/auth/forgot_password_screen.dart';
import 'package:delivery_app/screens/auth/login_screen.dart';
import 'package:delivery_app/screens/auth/otp_screen.dart';
import 'package:delivery_app/widgets/common/country_code_dropdown.dart';
import 'package:delivery_app/widgets/common/country_flag.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioAdapter dioAdapter;
  late AuthController authController;

  setUp(() async {
    Get.testMode = true;
    DioConfig.isTestMode = true;
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();

    final dio = await DioConfig.dio();
    dioAdapter = DioAdapter(dio: dio);

    Get.reset();
    authController = Get.put(AuthController());
  });

  tearDown(() {
    Get.reset();
  });

  group('Update 1: Forgot Password OTP Instructions', () {
    testWidgets('OTP step in ForgotPasswordScreen displays dual phone/email instructions and card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      dioAdapter.onPost(
        ApiEndpoints.customerSendOtp,
        (server) => server.reply(200, {'success': true}),
        data: Matchers.any,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const ForgotPasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '0911058179');
      await tester.tap(find.text('Send Code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Dual-channel header icon (mark_email_read_outlined)
      expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);

      // 2. Instructions card to check both phone SMS and email
      expect(find.text('check_phone_or_email_instructions'.tr), findsOneWidget);

      // 3. Title and subtitle
      expect(find.text('verify_your_number'.tr), findsOneWidget);
      expect(find.text('enter_code_sent_to'.tr), findsOneWidget);

      // 4. Phone chip
      expect(find.text('251911058179'), findsOneWidget);

      authController.clearResetPasswordState();
    });
  });

  group('Update 2: Return to OTP Verification Screen & Interceptor Safety', () {
    test('Pending registration state persists to ConfigPreference and routes to OTP on restart', () async {
      await ConfigPreference.setPendingRegistration(
        userId: 42,
        phone: '251911058179',
        email: 'test@example.com',
        name: 'Abebe Bikila',
        token: 'token-123',
        otp: '9999',
      );

      // App initial route should be AppRoutes.otp
      expect(AppPages.initial, AppRoutes.otp);

      final data = ConfigPreference.getPendingRegistration();
      expect(data, isNotNull);
      expect(data!['userId'], 42);
      expect(data['phone'], '251911058179');
      expect(data['email'], 'test@example.com');

      await ConfigPreference.clearPendingRegistration();
      expect(ConfigPreference.getPendingRegistration(), isNull);
    });

    test('Pending password reset state persists to ConfigPreference', () async {
      await ConfigPreference.setPendingResetPassword(
        phone: '251911058179',
        otp: '1234',
        step: 1,
      );

      final resetData = ConfigPreference.getPendingResetPassword();
      expect(resetData, isNotNull);
      expect(resetData!['phone'], '251911058179');
      expect(resetData['step'], 1);

      await ConfigPreference.clearPendingResetPassword();
      expect(ConfigPreference.getPendingResetPassword(), isNull);
    });

    testWidgets('OtpScreen initializes phone and email from saved pending registration', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await ConfigPreference.setPendingRegistration(
        userId: 101,
        phone: '251911223344',
        email: 'user@domain.com',
        name: 'User Name',
        token: 'some-token',
        otp: '4321',
      );

      // Re-init auth controller so it restores from ConfigPreference
      Get.reset();
      authController = Get.put(AuthController());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const OtpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('251911223344'), findsOneWidget);
      expect(find.text('user@domain.com'), findsOneWidget);
      expect(find.text('check_phone_or_email_instructions'.tr), findsOneWidget);

      await ConfigPreference.clearPendingRegistration();
    });
  });

  group('Update 3: Country Code Dropdown and Flags', () {
    testWidgets('CountryFlag widget renders flag container with border and cache image', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CountryFlag(country: CountryCode.defaultCountry),
          ),
        ),
      );
      expect(find.byType(CountryFlag), findsOneWidget);
    });

    testWidgets('CountryCodeDropdown renders on LoginScreen and opens searchable picker with flags', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // CountryCodeDropdown is displayed
      expect(find.byType(CountryCodeDropdown), findsOneWidget);
      expect(find.text('+251'), findsOneWidget);
      expect(find.byType(CountryFlag), findsOneWidget);

      // Tap on dropdown to open searchable picker
      await tester.tap(find.byType(CountryCodeDropdown));
      await tester.pumpAndSettle();

      // Search bar is visible
      expect(find.byType(TextField), findsAtLeastNWidgets(1));

      // Filter by country name
      await tester.enterText(find.byType(TextField).last, 'United States');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'United States'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);

      // Select United States
      await tester.tap(find.widgetWithText(ListTile, 'United States'));
      await tester.pumpAndSettle();

      // Prefix now reflects +1
      expect(find.text('+1'), findsOneWidget);
    });
  });
}
