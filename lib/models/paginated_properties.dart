import 'store.dart';

class PaginatedProperties {
  final List<Store> properties;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? nextPageUrl;

  const PaginatedProperties({
    required this.properties,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.nextPageUrl,
  });

  bool get hasMore => currentPage < lastPage;

  factory PaginatedProperties.fromJson(Map<String, dynamic> json) {
    final list = <Store>[];
    final rawData = json['data'];

    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          list.add(Store.fromJson(item));
        }
      }
    }

    return PaginatedProperties(
      properties: list,
      currentPage: int.tryParse(json['current_page']?.toString() ?? '1') ?? 1,
      lastPage: int.tryParse(json['last_page']?.toString() ?? '1') ?? 1,
      total: int.tryParse(json['total']?.toString() ?? '0') ?? list.length,
      nextPageUrl: json['next_page_url']?.toString(),
    );
  }
}
