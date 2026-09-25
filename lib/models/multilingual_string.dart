import '../utils/parsing_translator.dart';

class MultiLangString {
  final String en;
  final String? am;
  final String? orm;
  final String? tg;
  final String? so;

  const MultiLangString({
    required this.en,
    this.am,
    this.orm,
    this.tg,
    this.so,
  });

  /// Safely parse from dynamic JSON which could be a Map or a plain String.
  factory MultiLangString.fromJson(dynamic json) {
    if (json == null) {
      return const MultiLangString(en: '');
    }
    if (json is String) {
      return MultiLangString(en: json);
    }
    if (json is Map) {
      final en = json['en']?.toString() ??
          json['am']?.toString() ??
          json['or']?.toString() ??
          '';
      return MultiLangString(
        en: en,
        am: json['am']?.toString(),
        orm: json['or']?.toString(),
        tg: json['tg']?.toString(),
        so: json['so']?.toString(),
      );
    }
    return MultiLangString(en: json.toString());
  }

  /// Return display text based on active locale or fallback to en
  String get text {
    final lang = parsingTranslator();
    if (lang == 'am' && am != null && am!.isNotEmpty) return am!;
    if (lang == 'or' && orm != null && orm!.isNotEmpty) return orm!;
    if (lang == 'tg' && tg != null && tg!.isNotEmpty) return tg!;
    if (lang == 'so' && so != null && so!.isNotEmpty) return so!;
    return en.isNotEmpty ? en : (am ?? orm ?? tg ?? so ?? '');
  }

  Map<String, dynamic> toJson() => {
        'en': en,
        if (am != null) 'am': am,
        if (orm != null) 'or': orm,
        if (tg != null) 'tg': tg,
        if (so != null) 'so': so,
      };

  @override
  String toString() => text;
}
