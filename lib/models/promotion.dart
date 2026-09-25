class Promotion {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? badge;
  final String? storeId;
  final String? discountText;

  const Promotion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.badge,
    this.storeId,
    this.discountText,
  });
}
