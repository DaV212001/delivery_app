class AddressModel {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final int userId;
  final DateTime? createdAt;

  const AddressModel({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.userId,
    this.createdAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '9.020') ?? 9.020,
      longitude: double.tryParse(json['longitude']?.toString() ?? '38.746') ?? 38.746,
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id']?.toString() ?? '1') ?? 1,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'user_id': userId,
      };

  String get formattedLocation => '$name ($latitude, $longitude)';
}
