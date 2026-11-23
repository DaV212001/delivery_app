import '../utils/currency_utils.dart';

class PropertyDeliveryOption {
  final dynamic id;
  final String image;
  final String name;
  final double kmPrice;
  final double startPrice;
  final String? currency;

  const PropertyDeliveryOption({
    this.id,
    required this.image,
    required this.name,
    required this.kmPrice,
    this.startPrice = 0.0,
    this.currency,
  });

  String get displayCurrency => CurrencyUtils.resolveCode(currency);

  factory PropertyDeliveryOption.fromJson(Map<String, dynamic> json) {
    return PropertyDeliveryOption(
      id: json['id'],
      image: json['image']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      kmPrice: double.tryParse(
              json['km_price']?.toString() ??
              json['courirer_km_price']?.toString() ??
              json['courier_km_price']?.toString() ??
              json['property_km_price']?.toString() ??
              '0') ??
          0.0,
      startPrice: double.tryParse(
              json['start_price']?.toString() ??
              json['courirer_start_price']?.toString() ??
              json['courier_start_price']?.toString() ??
              json['property_start_price']?.toString() ??
              '0') ??
          0.0,
      currency: json['currency']?.toString() ??
          json['currency_code']?.toString() ??
          json['currency_id']?.toString(),
    );
  }

  PropertyDeliveryOption copyWith({
    dynamic id,
    String? image,
    String? name,
    double? kmPrice,
    double? startPrice,
    String? currency,
  }) {
    return PropertyDeliveryOption(
      id: id ?? this.id,
      image: image ?? this.image,
      name: name ?? this.name,
      kmPrice: kmPrice ?? this.kmPrice,
      startPrice: startPrice ?? this.startPrice,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'image': image,
        'name': name,
        'km_price': kmPrice,
        'start_price': startPrice,
        if (currency != null) 'currency': currency,
      };

  /// Calculates delivery price using Formula A: start_price + (distance_km * km_price)
  double calculateTotal(double distanceKm) {
    final dist = distanceKm > 0 ? distanceKm : 0.0;
    return double.parse((startPrice + (kmPrice * dist)).toStringAsFixed(2));
  }
}
