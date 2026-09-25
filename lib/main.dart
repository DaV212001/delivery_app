import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'bindings/initial_binding.dart';
import 'config/storage_config.dart';
import 'config/translations.dart';
import 'controllers/localization_controller.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigPreference.init();
  runApp(const AmnDeliveryApp());
}

class AmnDeliveryApp extends StatelessWidget {
  const AmnDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AMN Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      translations: AppTranslations(),
      locale: LocalizationController.getLocale(),
      fallbackLocale: const Locale('en', 'US'),
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}

typedef FreshBiteApp = AmnDeliveryApp;
