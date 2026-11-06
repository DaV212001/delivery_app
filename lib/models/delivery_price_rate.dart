class DeliveryPriceRate {
  final int id;
  final int cityId;
  final int currencyId;
  final int carTypeId;
  final double propertyStartPrice;
  final double propertyKmPrice;
  final double courierStartPrice;
  final double courierKmPrice;
  final double pickupStartPrice;
  final double pickupKmPrice;

  const DeliveryPriceRate({
    required this.id,
    required this.cityId,
    required this.currencyId,
    required this.carTypeId,
    required this.propertyStartPrice,
    required this.propertyKmPrice,
    required this.courierStartPrice,
    required this.courierKmPrice,
    required this.pickupStartPrice,
    required this.pickupKmPrice,
  });

  factory DeliveryPriceRate.fromJson(Map<String, dynamic> json) {
    return DeliveryPriceRate(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      cityId: int.tryParse(json['city_id']?.toString() ?? '1') ?? 1,
      currencyId: int.tryParse(json['currency_id']?.toString() ?? '1') ?? 1,
      carTypeId: int.tryParse(json['car_type_id']?.toString() ?? '1') ?? 1,
      propertyStartPrice:
          double.tryParse(json['property_start_price']?.toString() ?? '0') ?? 0.0,
      propertyKmPrice:
          double.tryParse(json['property_km_price']?.toString() ?? '0') ?? 0.0,
      courierStartPrice:
          double.tryParse(json['courirer_start_price']?.toString() ?? '0') ?? 0.0,
      courierKmPrice:
          double.tryParse(json['courirer_km_price']?.toString() ?? '0') ?? 0.0,
      pickupStartPrice:
          double.tryParse(json['pickup_start_price']?.toString() ?? '0') ?? 0.0,
      pickupKmPrice:
          double.tryParse(json['pickup_km_price']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'city_id': cityId,
        'currency_id': currencyId,
        'car_type_id': carTypeId,
        'property_start_price': propertyStartPrice,
        'property_km_price': propertyKmPrice,
        'courirer_start_price': courierStartPrice,
        'courirer_km_price': courierKmPrice,
        'pickup_start_price': pickupStartPrice,
        'pickup_km_price': pickupKmPrice,
      };

  /// Calculates total price for property/restaurant/store deliveries:
  /// Formula A: start_price + (distance_km * km_price)
  double calculatePropertyPrice(double distanceKm) {
    final dist = distanceKm > 0 ? distanceKm : 0.0;
    return double.parse((propertyStartPrice + (dist * propertyKmPrice)).toStringAsFixed(2));
  }

  /// Calculates total price for courier deliveries:
  /// Formula A: start_price + (distance_km * km_price)
  double calculateCourierPrice(double distanceKm) {
    final dist = distanceKm > 0 ? distanceKm : 0.0;
    return double.parse((courierStartPrice + (dist * courierKmPrice)).toStringAsFixed(2));
  }
}
