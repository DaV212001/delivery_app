import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_app/config/storage_config.dart';
import 'package:delivery_app/config/translations.dart';
import 'package:delivery_app/controllers/localization_controller.dart';
import 'package:delivery_app/models/multilingual_string.dart';
import 'package:delivery_app/utils/parsing_translator.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();
  });

  tearDown(() {
    Get.reset();
  });

  group('ParsingTranslator and MultiLangString Tests', () {
    testWidgets('parsingTranslator maps locales correctly', (tester) async {
      await tester.pumpWidget(GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const Scaffold(),
      ));

      await Get.updateLocale(const Locale('en', 'US'));
      expect(parsingTranslator(), 'en');

      await Get.updateLocale(const Locale('am'));
      expect(parsingTranslator(), 'am');

      // Oromiffa mapped to it
      await Get.updateLocale(const Locale('it'));
      expect(parsingTranslator(), 'or');

      // Tigrignya mapped to en_GB
      await Get.updateLocale(const Locale('en', 'GB'));
      expect(parsingTranslator(), 'tg');

      // Somali mapped to en_AU
      await Get.updateLocale(const Locale('en', 'AU'));
      expect(parsingTranslator(), 'so');
    });

    testWidgets('MultiLangString dynamically returns text based on active locale', (tester) async {
      await tester.pumpWidget(GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const Scaffold(),
      ));

      const multi = MultiLangString(
        en: 'Restaurant',
        am: 'ሬስቶራንት',
        orm: 'Mana Nyaataa',
        tg: 'ቤት ምግቢ',
        so: 'Makhaayad',
      );

      await Get.updateLocale(const Locale('en', 'US'));
      expect(multi.text, 'Restaurant');

      await Get.updateLocale(const Locale('am'));
      expect(multi.text, 'ሬስቶራንት');

      await Get.updateLocale(const Locale('it'));
      expect(multi.text, 'Mana Nyaataa');

      await Get.updateLocale(const Locale('en', 'GB'));
      expect(multi.text, 'ቤት ምግቢ');

      await Get.updateLocale(const Locale('en', 'AU'));
      expect(multi.text, 'Makhaayad');
    });

    testWidgets('MultiLangString falls back to en when translation is missing', (tester) async {
      await tester.pumpWidget(GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const Scaffold(),
      ));

      const multi = MultiLangString(
        en: 'Fallback Title',
      );

      await Get.updateLocale(const Locale('am'));
      expect(multi.text, 'Fallback Title');

      await Get.updateLocale(const Locale('it'));
      expect(multi.text, 'Fallback Title');
    });
  });

  group('GetX Translations Dictionary Tests', () {
    test('All supported languages contain critical keys', () {
      final keys = AppTranslations().keys;

      expect(keys.containsKey('en_US'), isTrue);
      expect(keys.containsKey('am'), isTrue);
      expect(keys.containsKey('it'), isTrue);     // Oromiffa
      expect(keys.containsKey('en_GB'), isTrue);  // Tigrignya
      expect(keys.containsKey('en_AU'), isTrue);  // Somali

      final requiredKeys = [
        'home',
        'orders',
        'cart',
        'wallet',
        'profile',
        'search',
        'place_order',
        'topup_wallet',
        'language',
      ];

      for (final lang in ['en_US', 'am', 'it', 'en_GB', 'en_AU']) {
        for (final k in requiredKeys) {
          expect(keys[lang]!.containsKey(k), isTrue, reason: '$lang is missing key: $k');
        }
      }
    });

    testWidgets('GetX .tr translates reactively across locales', (tester) async {
      await tester.pumpWidget(GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const Scaffold(),
      ));

      await Get.updateLocale(const Locale('en', 'US'));
      expect('home'.tr, 'Home');

      await Get.updateLocale(const Locale('am'));
      expect('home'.tr, 'መነሻ');

      await Get.updateLocale(const Locale('it'));
      expect('home'.tr, 'Mana');

      await Get.updateLocale(const Locale('en', 'GB'));
      expect('home'.tr, 'መበገሲ');

      await Get.updateLocale(const Locale('en', 'AU'));
      expect('home'.tr, 'Guriga');
    });
  });

  group('LocalizationController Tests', () {
    testWidgets('changeLanguage updates locale and persists preference', (tester) async {
      await tester.pumpWidget(GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const Scaffold(),
      ));

      Get.put(LocalizationController());

      await LocalizationController.changeLanguage(const Locale('it'));
      expect(LocalizationController.currentLanguageCode.value, 'it');
      expect(ConfigPreference.getLanguage(), 'it');
      expect(LocalizationController.getLanguageName(), 'Afaan Oromoo');

      await LocalizationController.changeLanguage(const Locale('en', 'GB'));
      expect(LocalizationController.currentLanguageCode.value, 'en_GB');
      expect(ConfigPreference.getLanguage(), 'en_GB');
      expect(LocalizationController.getLanguageName(), 'ትግርኛ');

      await LocalizationController.changeLanguage(const Locale('en', 'AU'));
      expect(LocalizationController.currentLanguageCode.value, 'en_AU');
      expect(ConfigPreference.getLanguage(), 'en_AU');
      expect(LocalizationController.getLanguageName(), 'Soomaali');

      await LocalizationController.changeLanguage(const Locale('am'));
      expect(LocalizationController.currentLanguageCode.value, 'am');
      expect(ConfigPreference.getLanguage(), 'am');
      expect(LocalizationController.getLanguageName(), 'አማርኛ');
    });
  });
}
