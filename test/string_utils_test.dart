import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/utils/string_utils.dart';

void main() {
  group('StringUtils.normalizeCategoryTitle Tests', () {
    test('normalizes ALL CAPS single word to Title Case', () {
      expect(StringUtils.normalizeCategoryTitle('BURGER'), equals('Burger'));
      expect(StringUtils.normalizeCategoryTitle('PIZZA'), equals('Pizza'));
      expect(StringUtils.normalizeCategoryTitle('MART'), equals('Mart'));
      expect(StringUtils.normalizeCategoryTitle('ETHIOPOST'), equals('Ethiopost'));
    });

    test('normalizes ALL CAPS multi-word titles with connector words', () {
      expect(
        StringUtils.normalizeCategoryTitle('CHINESE CUISINE'),
        equals('Chinese Cuisine'),
      );
      expect(
        StringUtils.normalizeCategoryTitle('SHAKES AND SMOOTHIES'),
        equals('Shakes and Smoothies'),
      );
      expect(
        StringUtils.normalizeCategoryTitle('FASTING SPECIALS'),
        equals('Fasting Specials'),
      );
      expect(
        StringUtils.normalizeCategoryTitle('HEALTHY CHOICE'),
        equals('Healthy Choice'),
      );
    });

    test('handles punctuation and symbols correctly', () {
      expect(StringUtils.normalizeCategoryTitle('BAKERY.'), equals('Bakery.'));
      expect(
        StringUtils.normalizeCategoryTitle('CAKES & DESSERTS'),
        equals('Cakes & Desserts'),
      );
    });

    test('replaces internal newlines with space', () {
      expect(
        StringUtils.normalizeCategoryTitle('Fasting\nSpecials'),
        equals('Fasting Specials'),
      );
      expect(
        StringUtils.normalizeCategoryTitle('FASTING\nSPECIALS'),
        equals('Fasting Specials'),
      );
    });

    test('preserves mixed case and non-Latin text without distortion', () {
      expect(
        StringUtils.normalizeCategoryTitle('Burgers & Fast Food'),
        equals('Burgers & Fast Food'),
      );
      expect(
        StringUtils.normalizeCategoryTitle('Werka Coffee | Fiyel Bet'),
        equals('Werka Coffee | Fiyel Bet'),
      );
      expect(
        StringUtils.normalizeCategoryTitle('ትኩስ ምግብ'),
        equals('ትኩስ ምግብ'),
      );
    });

    test('handles empty and whitespace strings gracefully', () {
      expect(StringUtils.normalizeCategoryTitle(''), equals(''));
      expect(StringUtils.normalizeCategoryTitle('   '), equals(''));
    });
  });
}
