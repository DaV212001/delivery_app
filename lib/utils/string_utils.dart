/// Utility functions for string formatting and normalization.
class StringUtils {
  /// Normalizes category titles.
  /// If the text is ALL CAPS, transforms it into clean Title Case
  /// (e.g. "BURGER" -> "Burger", "CHINESE CUISINE" -> "Chinese Cuisine",
  /// "SHAKES AND SMOOTHIES" -> "Shakes and Smoothies").
  /// Replaces internal newlines with spaces and trims extra whitespace.
  /// Preserves non-Latin scripts (Amharic, Tigrinya, etc.) and mixed-case text intact.
  static String normalizeCategoryTitle(String rawTitle) {
    if (rawTitle.isEmpty) return '';
    final cleaned = rawTitle.replaceAll('\n', ' ').trim();

    // Check if the string has Latin letters and is entirely uppercase
    final latinLetters = cleaned.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    final isAllUpper = latinLetters.isNotEmpty && latinLetters == latinLetters.toUpperCase();

    if (!isAllUpper) {
      return cleaned;
    }

    // Minor connector words kept lowercase unless at position 0
    const minorWords = {'and', 'or', 'for', 'of', 'in', 'on', 'at', 'to', 'a', 'an'};

    final words = cleaned.split(RegExp(r'\s+'));
    final result = <String>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;

      final lower = word.toLowerCase();
      if (i > 0 && minorWords.contains(lower)) {
        result.add(lower);
      } else {
        // Capitalize first letter, keep remainder lowercase
        if (word.length == 1) {
          result.add(word.toUpperCase());
        } else {
          result.add(word[0].toUpperCase() + word.substring(1).toLowerCase());
        }
      }
    }

    return result.join(' ');
  }
}
