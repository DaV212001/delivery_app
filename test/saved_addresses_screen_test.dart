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
import 'package:delivery_app/controllers/profile_controller.dart';
import 'package:delivery_app/routes/app_pages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioAdapter dioAdapter;

  setUp(() async {
    DioConfig.isTestMode = true;
    DioConfig.resetDio();
    final dio = await DioConfig.dio();
    dioAdapter = DioAdapter(dio: dio);

    dioAdapter.onGet(
      ApiEndpoints.faq,
      (server) => server.reply(200, {'data': []}),
    );
    dioAdapter.onGet(
      ApiEndpoints.privacy,
      (server) => server.reply(200, {'data': {'content': 'Privacy'}}),
    );
    dioAdapter.onGet(
      ApiEndpoints.termsAndConditions,
      (server) => server.reply(200, {'data': {'content': 'Terms'}}),
    );
    dioAdapter.onGet(
      ApiEndpoints.walletAmount(1),
      (server) => server.reply(200, {'data': '0'}),
    );
    dioAdapter.onGet(
      ApiEndpoints.walletTransactions(1),
      (server) => server.reply(200, {'data': []}),
    );
    dioAdapter.onGet(
      ApiEndpoints.profile(1),
      (server) => server.reply(200, {
        'data': {
          'id': 1,
          'f_name': 'Aman',
          'l_name': 'Til',
          'email': 'tilahunamanuel0@gmail.com',
          'phone': '251911058179',
        },
      }),
    );

    SharedPreferences.setMockInitialValues({
      'user_id': 1,
      'access_token': 'mock_token',
      'access_token_expiry': DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
    });
    await ConfigPreference.init();
    Get.reset();
  });

  tearDown(() {
    Get.reset();
    DioConfig.resetDio();
  });

  group('SavedAddressesScreen Widget Tests', () {
    testWidgets('renders empty state when no saved addresses exist', (tester) async {
      dioAdapter.onGet(
        ApiEndpoints.deliveryAddresses(1),
        (server) => server.reply(200, {'data': []}),
      );

      Get.put(ProfileController());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.savedAddresses,
          getPages: AppPages.routes,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved Addresses'), findsOneWidget);
      expect(find.text('No saved addresses yet'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders address items with coordinates, default badge, edit and delete buttons', (tester) async {
      dioAdapter.onGet(
        ApiEndpoints.deliveryAddresses(1),
        (server) => server.reply(200, {
          'data': [
            {
              'id': 101,
              'name': 'Home Apartment',
              'latitude': '9.0209',
              'longitude': '38.7469',
              'user_id': 1,
            },
            {
              'id': 102,
              'name': 'Tech Office',
              'latitude': '9.0300',
              'longitude': '38.7600',
              'user_id': 1,
            },
          ],
        }),
      );

      Get.put(ProfileController());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.savedAddresses,
          getPages: AppPages.routes,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home Apartment'), findsOneWidget);
      expect(find.text('Tech Office'), findsOneWidget);
      expect(find.text('DEFAULT'), findsOneWidget);
      expect(find.text('9.0209, 38.7469'), findsOneWidget);
      expect(find.text('9.0300, 38.7600'), findsOneWidget);

      // Edit icons for both items
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.edit_outlined && w.size == 20,
        ),
        findsNWidgets(2),
      );

      // Delete icons for both items
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.delete_outline && w.size == 20,
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('tapping an address selects it and updates selectedAddress', (tester) async {
      dioAdapter.onGet(
        ApiEndpoints.deliveryAddresses(1),
        (server) => server.reply(200, {
          'data': [
            {
              'id': 101,
              'name': 'Home Apartment',
              'latitude': '9.0209',
              'longitude': '38.7469',
              'user_id': 1,
            },
            {
              'id': 102,
              'name': 'Tech Office',
              'latitude': '9.0300',
              'longitude': '38.7600',
              'user_id': 1,
            },
          ],
        }),
      );

      final profileController = Get.put(ProfileController());
      Get.put(AuthController());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.savedAddresses,
          getPages: AppPages.routes,
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Tech Office
      await tester.tap(find.text('Tech Office'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(profileController.selectedAddress.value?.id, 102);
      expect(profileController.selectedAddress.value?.name, 'Tech Office');
    });

    testWidgets('tapping delete button shows confirmation dialog', (tester) async {
      dioAdapter.onGet(
        ApiEndpoints.deliveryAddresses(1),
        (server) => server.reply(200, {
          'data': [
            {
              'id': 101,
              'name': 'Home Apartment',
              'latitude': '9.0209',
              'longitude': '38.7469',
              'user_id': 1,
            },
          ],
        }),
      );

      Get.put(ProfileController());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: AppRoutes.savedAddresses,
          getPages: AppPages.routes,
        ),
      );
      await tester.pumpAndSettle();

      final deleteIcon = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.delete_outline && w.size == 20,
      );
      expect(deleteIcon, findsOneWidget);

      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Are you sure you want to remove "Home Apartment" from your saved addresses?'), findsOneWidget);
    });
  });
}
