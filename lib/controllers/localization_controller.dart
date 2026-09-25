import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/storage_config.dart';
import 'restaurant_controller.dart';

class LanguageOption {
  final String name;
  final String nativeName;
  final String flag;
  final Locale locale;
  final String codeString;

  const LanguageOption({
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.locale,
    required this.codeString,
  });
}

class LocalizationController extends GetxController {
  static final RxString currentLanguageCode = 'en'.obs;

  /// Supported languages using mapped locale codes to ensure GetX and Flutter recognize them:
  /// - English -> en_US
  /// - Amharic -> am
  /// - Oromiffa -> it
  /// - Tigrignya -> en_GB
  /// - Somali -> en_AU
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
      locale: Locale('en', 'US'),
      codeString: 'en',
    ),
    LanguageOption(
      name: 'Amharic',
      nativeName: 'አማርኛ',
      flag: '🇪🇹',
      locale: Locale('am'),
      codeString: 'am',
    ),
    LanguageOption(
      name: 'Oromiffa',
      nativeName: 'Afaan Oromoo',
      flag: '🇪🇹',
      locale: Locale('it'),
      codeString: 'it',
    ),
    LanguageOption(
      name: 'Tigrigna',
      nativeName: 'ትግርኛ',
      flag: '🇪🇹',
      locale: Locale('en', 'GB'),
      codeString: 'en_GB',
    ),
    LanguageOption(
      name: 'Somali',
      nativeName: 'Soomaali',
      flag: '🇸🇴',
      locale: Locale('en', 'AU'),
      codeString: 'en_AU',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    currentLanguageCode.value = ConfigPreference.getLanguage();
  }

  /// Change active app language and update GetX locale
  static Future<void> changeLanguage(Locale newLocale) async {
    await Get.updateLocale(newLocale);

    final String langCode = newLocale.languageCode == 'en'
        ? (newLocale.countryCode == 'GB'
            ? 'en_GB'
            : (newLocale.countryCode == 'AU' ? 'en_AU' : 'en'))
        : newLocale.languageCode;

    currentLanguageCode.value = langCode;
    await ConfigPreference.setLanguage(langCode);

    // Refresh store and catalog data so multilingual models re-render with fresh values
    if (Get.isRegistered<RestaurantController>()) {
      Get.find<RestaurantController>().loadRestaurants();
    }
  }

  /// Return user-friendly name of currently selected language
  static String getLanguageName() {
    final option = supportedLanguages.firstWhere(
      (opt) => opt.codeString == currentLanguageCode.value,
      orElse: () => supportedLanguages.first,
    );
    return option.nativeName;
  }

  /// Resolve stored locale for initial GetMaterialApp configuration
  static Locale getLocale() {
    final code = ConfigPreference.getLanguage();
    final option = supportedLanguages.firstWhere(
      (opt) => opt.codeString == code,
      orElse: () => supportedLanguages.first,
    );
    return option.locale;
  }
}
