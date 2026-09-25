import 'multilingual_string.dart';

class FaqItem {
  final int? id;
  final MultiLangString question;
  final MultiLangString answer;

  const FaqItem({
    this.id,
    required this.question,
    required this.answer,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      question: MultiLangString.fromJson(json['question']),
      answer: MultiLangString.fromJson(json['answer']),
    );
  }

  String get questionText => question.text;
  String get answerText => answer.text;
}
