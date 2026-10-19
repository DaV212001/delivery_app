import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/controllers/auth_controller.dart';
import 'package:delivery_app/controllers/corporate_controller.dart';
import 'package:delivery_app/models/corporate_model.dart';
import 'package:delivery_app/screens/home/widgets/home_corporate_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();
    DioConfig.isTestMode = true;
    Get.reset();
    Get.put(AuthController());
  });

  tearDown(() {
    Get.reset();
  });

  group('HomeCorporateSection Widget Tests', () {
    testWidgets('Renders section title, BUSINESS badge, and spacious card layout',
        (tester) async {
      final corp = Get.put(CorporateController());
      corp.company.value = const CompanyModel(
        id: 1,
        name: 'Abel Commercial Logistics',
      );
      corp.branches.assignAll([
        const CompanyBranchModel(
          id: 2,
          branchName: 'Bole HQ Branch',
          friendlyLocation: 'Bole Medhanialem',
          latitude: 9.02,
          longitude: 38.74,
        ),
      ]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: HomeCorporateSection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Corporate Service'), findsOneWidget);
      expect(find.text('BUSINESS'), findsOneWidget);
      expect(find.text('CORPORATE DELIVERY'), findsOneWidget);
      expect(find.text('Abel Commercial Logistics'), findsOneWidget);
      expect(find.text('Bole HQ Branch • Inter-branch dispatch'), findsOneWidget);
      expect(find.byType(CorporateIllustration), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('Renders properly without overflow on narrow screens (320px width)',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final corp = Get.put(CorporateController());
      corp.company.value = const CompanyModel(
        id: 1,
        name: 'Enterprise Logistics Group PLC',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: HomeCorporateSection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('CORPORATE DELIVERY'), findsOneWidget);
      expect(find.text('Enterprise Logistics Group PLC'), findsOneWidget);
    });
  });
}
