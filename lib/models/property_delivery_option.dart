class PropertyDeliveryOption {
  final dynamic id;
  final String image;
  final String name;
  final double kmPrice;

  const PropertyDeliveryOption({
    this.id,
    required this.image,
    required this.name,
    required this.kmPrice,
  });

  factory PropertyDeliveryOption.fromJson(Map<String, dynamic> json) {
    return PropertyDeliveryOption(
      id: json['id'],
      image: json['image']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      kmPrice: double.tryParse(json['km_price']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'image': image,
        'name': name,
        'km_price': kmPrice,
      };
}
