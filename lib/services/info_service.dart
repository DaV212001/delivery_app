import '../constants/api_endpoints.dart';
import '../models/faq_model.dart';
import '../models/multilingual_string.dart';
import '../utils/templates/dio_template.dart';

class InfoService {
  /// Fetch Privacy Policy
  static Future<String> fetchPrivacyPolicy() async {
    String text = '';
    await DioService.dioGet(
      path: ApiEndpoints.privacy,
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List && (data['data'] as List).isNotEmpty) {
          final first = (data['data'] as List).first;
          if (first is Map) {
            text = MultiLangString.fromJson(first).text;
          }
        }
      },
    );
    return text;
  }

  /// Fetch Terms and Conditions
  static Future<String> fetchTermsAndConditions() async {
    String text = '';
    await DioService.dioGet(
      path: ApiEndpoints.termsAndConditions,
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List && (data['data'] as List).isNotEmpty) {
          final first = (data['data'] as List).first;
          if (first is Map) {
            text = MultiLangString.fromJson(first).text;
          }
        }
      },
    );
    return text;
  }

  /// Fetch FAQs
  static Future<List<FaqItem>> fetchFaqs() async {
    final list = <FaqItem>[];
    await DioService.dioGet(
      path: ApiEndpoints.faq,
      onSuccess: (response) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          for (final item in data['data']) {
            if (item is Map<String, dynamic>) {
              list.add(FaqItem.fromJson(item));
            }
          }
        }
      },
    );
    return list;
  }
}
