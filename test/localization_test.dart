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
    Get.addTranslations(AppTranslations().keys);
  });

  tearDown(() {
    Get.reset();
  });

  group('ParsingTranslator and MultiLangString Tests', () {
    test('parsingTranslator maps locales correctly', () {
      Get.locale = const Locale('en', 'US');
      expect(parsingTranslator(), 'en');

      Get.locale = const Locale('am');
      expect(parsingTranslator(), 'am');

      // Oromiffa mapped to it
      Get.locale = const Locale('it');
      expect(parsingTranslator(), 'or');

      // Tigrignya mapped to en_GB
      Get.locale = const Locale('en', 'GB');
      expect(parsingTranslator(), 'tg');

      // Somali mapped to en_AU
      Get.locale = const Locale('en', 'AU');
      expect(parsingTranslator(), 'so');

      // Arabic mapped to ar
      Get.locale = const Locale('ar');
      expect(parsingTranslator(), 'ar');
    });

    test('MultiLangString dynamically returns text based on active locale', () {
      const multi = MultiLangString(
        en: 'Restaurant',
        am: 'ሬስቶራንት',
        orm: 'Mana Nyaataa',
        tg: 'ቤት ምግቢ',
        so: 'Makhaayad',
        ar: 'مطعم',
      );

      Get.locale = const Locale('en', 'US');
      expect(multi.text, 'Restaurant');

      Get.locale = const Locale('am');
      expect(multi.text, 'ሬስቶራንት');

      Get.locale = const Locale('it');
      expect(multi.text, 'Mana Nyaataa');

      Get.locale = const Locale('en', 'GB');
      expect(multi.text, 'ቤት ምግቢ');

      Get.locale = const Locale('en', 'AU');
      expect(multi.text, 'Makhaayad');

      Get.locale = const Locale('ar');
      expect(multi.text, 'مطعم');
    });

    test('MultiLangString falls back to en when translation is missing', () {
      const multi = MultiLangString(
        en: 'Fallback Title',
      );

      Get.locale = const Locale('am');
      expect(multi.text, 'Fallback Title');

      Get.locale = const Locale('it');
      expect(multi.text, 'Fallback Title');
    });
  });

  group('GetX Translations Dictionary Tests', () {
    test('All supported languages contain critical keys', () {
      final keys = AppTranslations().keys;

      expect(keys.containsKey('en_US'), isTrue);
      expect(keys.containsKey('am'), isTrue);
      expect(keys.containsKey('it'), isTrue); // Oromiffa
      expect(keys.containsKey('en_GB'), isTrue); // Tigrignya
      expect(keys.containsKey('en_AU'), isTrue); // Somali
      expect(keys.containsKey('ar'), isTrue); // Arabic

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

      for (final lang in ['en_US', 'am', 'it', 'en_GB', 'en_AU', 'ar']) {
        for (final k in requiredKeys) {
          expect(keys[lang]!.containsKey(k), isTrue, reason: '$lang is missing key: $k');
        }
      }
    });

    test('Arabic dictionary has full parity with English dictionary', () {
      final keys = AppTranslations().keys;
      final enKeys = keys['en_US']!.keys.toSet();
      final arKeys = keys['ar']!.keys.toSet();

      final missingInArabic = enKeys.difference(arKeys);
      expect(missingInArabic, isEmpty, reason: 'Keys missing in Arabic: $missingInArabic');
    });

    test('GetX .tr translates reactively across locales', () {
      Get.locale = const Locale('en', 'US');
      expect('home'.tr, 'Home');

      Get.locale = const Locale('am');
      expect('home'.tr, 'መነሻ');

      Get.locale = const Locale('it');
      expect('home'.tr, 'Mana');

      Get.locale = const Locale('en', 'GB');
      expect('home'.tr, 'መበገሲ');

      Get.locale = const Locale('en', 'AU');
      expect('home'.tr, 'Guriga');

      Get.locale = const Locale('ar');
      expect('home'.tr, 'الرئيسية');
    });
  });

  group('LocalizationController Tests', () {
    test('changeLanguage updates locale and persists preference', () async {
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

      await LocalizationController.changeLanguage(const Locale('ar'));
      expect(LocalizationController.currentLanguageCode.value, 'ar');
      expect(ConfigPreference.getLanguage(), 'ar');
      expect(LocalizationController.getLanguageName(), 'العربية');
    });
  });
}
