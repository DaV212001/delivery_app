import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/controllers/auth_controller.dart';
import 'package:delivery_app/controllers/profile_controller.dart';
import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:delivery_app/models/wallet_model.dart';
import 'package:delivery_app/screens/wallet/wallet_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WalletScreen renders Guest Mode when user is not logged in', (tester) async {
    DioConfig.isTestMode = true;
    DioConfig.resetDio();
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();

    Get.reset();
    Get.put(AuthController());
    Get.put(ProfileController());

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const WalletScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('AMN Wallet'), findsOneWidget);
    expect(find.text('Access Your Wallet'), findsOneWidget);
    expect(find.text('Sign In / Register'), findsOneWidget);
    expect(find.text('AMN PAY WALLET'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets('WalletScreen renders Authenticated Mode with balance, stats, and filters', (tester) async {
    DioConfig.isTestMode = true;
    DioConfig.resetDio();
    SharedPreferences.setMockInitialValues({
      'user_id': 2,
      'access_token': 'mock_token_2',
      'user_name': 'Abebe Bikila',
    });
    await ConfigPreference.init();

    Get.reset();
    Get.put(AuthController());
    final profileController = Get.put(ProfileController());

    // Populate wallet balance and mock transactions
    profileController.walletBalance.value = const WalletBalance(amount: 1450.0);
    profileController.transactions.assignAll([
      WalletTransaction(
        id: 101,
        amount: 1000.0,
        type: 'topup',
        title: 'Wallet Topup',
        description: 'Chapa direct top-up',
        paymentStatus: '1',
        rawDate: '2025-11-22',
        date: DateTime(2025, 11, 22),
      ),
      WalletTransaction(
        id: 102,
        amount: 50.0,
        type: 'bonus',
        title: 'Welcome Bonus',
        description: 'Special promo bonus',
        paymentStatus: '1',
        rawDate: '2025-11-20',
        date: DateTime(2025, 11, 20),
      ),
      WalletTransaction(
        id: 103,
        amount: 400.0,
        type: 'topup',
        title: 'Bank Transfer Topup',
        description: 'Pending verification',
        paymentStatus: '0',
        rawDate: '2025-11-23',
        date: DateTime(2025, 11, 23),
      ),
    ]);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const WalletScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Verify Header & Balance Card
    expect(find.text('AMN Wallet'), findsOneWidget);
    expect(find.text('AMN PAY WALLET'), findsOneWidget);
    expect(find.text('1450.00 Br'), findsOneWidget);
    expect(find.text('Top Up Wallet'), findsWidgets);

    // Verify Quick Stats
    expect(find.text('Total Records'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Completed'), findsWidgets);
    expect(find.text('2'), findsOneWidget);

    // Verify Filters
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Top-ups'), findsOneWidget);
    expect(find.text('Bonuses'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);

    // Verify Transactions list
    expect(find.text('Wallet Topup'), findsOneWidget);
    expect(find.text('Welcome Bonus'), findsOneWidget);
    expect(find.text('Bank Transfer Topup'), findsOneWidget);
    expect(find.text('+1000.00 Br'), findsOneWidget);
    expect(find.text('+50.00 Br'), findsOneWidget);
    expect(find.text('+400.00 Br'), findsOneWidget);

    // Filter by Bonuses
    await tester.tap(find.text('Bonuses'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Welcome Bonus'), findsOneWidget);
    expect(find.text('Wallet Topup'), findsNothing);

    // Filter by Pending
    await tester.tap(find.text('Pending').first);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Bank Transfer Topup'), findsOneWidget);
    expect(find.text('Welcome Bonus'), findsNothing);

    // Tap transaction to open detail sheet
    await tester.tap(find.text('Bank Transfer Topup'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Transaction ID'), findsOneWidget);
    expect(find.text('#103'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    // Close detail sheet
    Get.back();
    await tester.pumpAndSettle();

    // Open Top Up Dialog
    await tester.tap(find.text('Top Up Wallet').first);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Top Up Wallet'), findsWidgets);
    expect(find.text('+250 Br'), findsOneWidget);
    expect(find.text('Proceed to Pay'), findsOneWidget);

    // Select preset +250 Br
    await tester.tap(find.text('+250 Br'));
    await tester.pump(const Duration(milliseconds: 100));

    // Cancel dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Top Up Wallet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
