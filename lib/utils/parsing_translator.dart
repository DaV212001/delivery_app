import 'package:get/get.dart';

/// Maps the active GetX locale to backend multilingual string keys ('en', 'am', 'or', 'tg', 'so').
///
/// Notice:
/// - Oromiffa uses 'it' locale code
/// - Tigrigna uses 'en_GB' locale code
/// - Somali uses 'en_AU' locale code
/// This avoids Flutter/GetX missing localization lookup crashes while supporting Ethiopian regional languages.
String parsingTranslator() {
  final locale = Get.locale?.toString() ?? 'en';
  final langCode = Get.locale?.languageCode ?? 'en';

  if (locale == 'en_GB') return 'tg'; // Tigrigna
  if (locale == 'it') return 'or';    // Oromiffa
  if (locale == 'en_AU') return 'so'; // Somali
  if (langCode == 'am') return 'am';  // Amharic

  return 'en';
}
