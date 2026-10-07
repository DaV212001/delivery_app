class MyMenuCategoryModel {
  final int id;
  final String name;
  final String? propertyName;
  final dynamic propertyId;

  const MyMenuCategoryModel({
    required this.id,
    required this.name,
    this.propertyName,
    this.propertyId,
  });

  factory MyMenuCategoryModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    return MyMenuCategoryModel(
      id: parsedId,
      name: json['name']?.toString() ?? '',
      propertyName: json['property_name']?.toString(),
      propertyId: json['property_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'property_name': propertyName,
    'property_id': propertyId,
  };
}
