import 'dart:io';
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
import 'package:delivery_app/controllers/restaurant_controller.dart';
import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:delivery_app/core/theme/theme_controller.dart';
import 'package:delivery_app/models/address_model.dart';
import 'package:delivery_app/models/user_profile.dart';
import 'package:delivery_app/routes/app_pages.dart';
import 'package:delivery_app/screens/profile/edit_profile_screen.dart';
import 'package:delivery_app/screens/profile/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioAdapter dioAdapter;

  setUp(() async {
    DioConfig.isTestMode = true;
    DioConfig.resetDio();
    final dio = await DioConfig.dio();
    dioAdapter = DioAdapter(dio: dio);

    SharedPreferences.setMockInitialValues({
      'user_id': 1,
      'access_token': 'mock_token',
      'access_token_expiry': DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
      'user_name': 'Aman Til',
      'user_email': 'tilahunamanuel0@gmail.com',
      'user_phone': '251911058179',
    });
    await ConfigPreference.init();

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
      ApiEndpoints.deliveryAddresses(1),
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

    Get.reset();
    Get.testMode = true;
    Get.put(ThemeController());
    final auth = Get.put(AuthController());
    auth.user = const UserProfile(
      id: '1',
      name: 'Aman Til',
      firstName: 'Aman',
      lastName: 'Til',
      email: 'tilahunamanuel0@gmail.com',
      phone: '251911058179',
      avatarUrl: '',
      tagline: 'AMN Customer',
      rating: 5.0,
      totalOrders: 3,
      defaultAddress: 'Bole, Addis Ababa',
    );
    Get.put(ProfileController());
    Get.put(RestaurantController());
  });

  tearDown(() {
    Get.reset();
    DioConfig.resetDio();
  });

  group('Edit Profile Integration & UI Tests', () {
    testWidgets('EditProfileScreen pre-populates fields with user data', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightTheme,
          getPages: AppPages.routes,
          home: const EditProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Aman'), findsOneWidget);
      expect(find.text('Til'), findsOneWidget);
      expect(find.text('tilahunamanuel0@gmail.com'), findsOneWidget);
      expect(find.text('251911058179'), findsOneWidget);
    });

    testWidgets('EditProfileScreen validates required fields and invalid email', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightTheme,
          getPages: AppPages.routes,
          home: const EditProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Clear first name field
      final firstNameField = find.widgetWithText(TextFormField, 'Aman');
      await tester.enterText(firstNameField, '');

      // Enter invalid email
      final emailField = find.widgetWithText(TextFormField, 'tilahunamanuel0@gmail.com');
      await tester.enterText(emailField, 'invalid-email');

      // Tap Save Changes
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Check validation error messages appear
      expect(find.text('Please enter first name'), findsOneWidget);
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('EditProfileScreen submits PUT request and updates controller state', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      dioAdapter.onPut(
        ApiEndpoints.profile(1),
        (server) => server.reply(200, {
          'success': true,
          'message': 'Profile updated successfully',
          'data': {
            'id': 1,
            'f_name': 'Amanuel',
            'l_name': 'Tilahun',
            'email': 'amanuel@gmail.com',
            'phone': '251911058179',
          },
        }),
        data: {
          'f_name': 'Amanuel',
          'l_name': 'Tilahun',
          'email': 'amanuel@gmail.com',
          'phone': '251911058179',
        },
      );

      // Mock the background GET /profile/1 refresh
      dioAdapter.onGet(
        ApiEndpoints.profile(1),
        (server) => server.reply(200, {
          'data': {
            'id': 1,
            'f_name': 'Amanuel',
            'l_name': 'Tilahun',
            'email': 'amanuel@gmail.com',
            'phone': '251911058179',
          },
        }),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightTheme,
          getPages: AppPages.routes,
          home: const EditProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter new first and last name and email
      final firstNameField = find.widgetWithText(TextFormField, 'Aman');
      await tester.enterText(firstNameField, 'Amanuel');

      final lastNameField = find.widgetWithText(TextFormField, 'Til');
      await tester.enterText(lastNameField, 'Tilahun');

      final emailField = find.widgetWithText(TextFormField, 'tilahunamanuel0@gmail.com');
      await tester.enterText(emailField, 'amanuel@gmail.com');

      // Tap Save Changes
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));

      final auth = Get.find<AuthController>();
      expect(auth.user.firstName, 'Amanuel');
      expect(auth.user.lastName, 'Tilahun');
      expect(auth.user.name, 'Amanuel Tilahun');
      expect(auth.user.email, 'amanuel@gmail.com');

      expect(ConfigPreference.getUserName(), 'Amanuel Tilahun');
      expect(ConfigPreference.getUserEmail(), 'amanuel@gmail.com');
    });

    testWidgets('ProfileScreen displays Edit Profile button and navigates to edit screen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.profile,
          getPages: AppPages.routes,
        ),
      );
      await tester.pumpAndSettle();

      // Check Edit Profile button is present
      final editProfileButtonFinder = find.widgetWithText(OutlinedButton, 'Edit Profile');
      expect(editProfileButtonFinder, findsOneWidget);

      // Check Edit Profile settings tile is also present
      expect(find.text('Update name, email and phone number'), findsOneWidget);

      // Tap the Edit Profile button
      await tester.tap(editProfileButtonFinder);
      await tester.pumpAndSettle();

      // Now we should be on EditProfileScreen
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('Saved addresses bottom sheet contains Edit button and opens edit dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final profileController = Get.find<ProfileController>();
      profileController.addresses.assignAll([
        const AddressModel(
          id: 162,
          name: 'office',
          latitude: 4.5678,
          longitude: 2.74573,
          userId: 1,
        ),
      ]);
      profileController.selectedAddress.value = profileController.addresses.first;

      dioAdapter.onPut(
        ApiEndpoints.deliveryAddressDetail(162),
        (server) => server.reply(200, {
          'success': true,
          'message': 'Address updated successfully',
        }),
        data: {
          'id': 162,
          'name': 'Head Office',
          'latitude': 4.5678,
          'longitude': 2.74573,
          'user_id': 1,
        },
      );

      dioAdapter.onGet(
        ApiEndpoints.deliveryAddresses(1),
        (server) => server.reply(200, {
          'data': [
            {
              'id': 162,
              'name': 'Head Office',
              'latitude': '4.5678',
              'longitude': '2.74573',
              'user_id': '1',
            },
          ],
        }),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightTheme,
          getPages: AppPages.routes,
          home: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap saved addresses tile
      final savedAddressesTile = find.text('Saved Addresses');
      await tester.ensureVisible(savedAddressesTile);
      await tester.tap(savedAddressesTile);
      await tester.pumpAndSettle();

      // Edit icon button should be visible in the bottom sheet
      final editIconFinder = find.byWidgetPredicate(
        (widget) => widget is Icon && widget.icon == Icons.edit_outlined && widget.size == 20,
      );
      expect(editIconFinder, findsOneWidget);

      await tester.tap(editIconFinder);
      await tester.pumpAndSettle();

      // Dialog should open
      expect(find.text('Edit Address'), findsOneWidget);

      // Update the address label
      final nameInput = find.widgetWithText(TextField, 'office');
      await tester.enterText(nameInput, 'Head Office');

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('EditProfileScreen displays camera badge and opens photo source sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightTheme,
          getPages: AppPages.routes,
          home: const EditProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Camera badge icon should be visible
      final cameraBadge = find.byIcon(Icons.camera_alt_rounded);
      expect(cameraBadge, findsOneWidget);

      // Tap on the camera badge
      await tester.tap(cameraBadge);
      await tester.pumpAndSettle();

      // Bottom sheet should show "Change Profile Photo", "Take Photo", "Choose from Gallery"
      expect(find.text('Change Profile Photo'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });

    test('ProfileController.uploadProfileImage updates user avatar and preferences', () async {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/test_upload_avatar.jpg')..writeAsStringSync('dummy');

      dioAdapter.onPost(
        ApiEndpoints.customerChangeProfileImage,
        (server) => server.reply(200, {
          'message': 'Success',
          'data': {
            'profile_image': 'https://api.amnplc.com/public/storage/profileImage/new_photo.jpg',
          },
        }),
        data: Matchers.any,
      );

      final profileCtrl = Get.find<ProfileController>();
      final authCtrl = Get.find<AuthController>();

      final result = await profileCtrl.uploadProfileImage(tempFile.path);

      expect(result, true);
      expect(authCtrl.user.avatarUrl, 'https://api.amnplc.com/public/storage/profileImage/new_photo.jpg');
      expect(ConfigPreference.getUserAvatar(), 'https://api.amnplc.com/public/storage/profileImage/new_photo.jpg');

      try {
        if (tempFile.existsSync()) tempFile.deleteSync();
      } catch (_) {}
    });
  });
}
