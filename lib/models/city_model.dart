class CityModel {
  final int id;
  final String name;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  const CityModel({
    required this.id,
    required this.name,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId =
        rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    return CityModel(
      id: parsedId,
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (status != null) 'status': status,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CityModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$name (ID: $id)';
}
