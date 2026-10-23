class CompanyModel {
  final int id;
  final String name;
  final String description;

  const CompanyModel({
    required this.id,
    required this.name,
    this.description = '',
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}

class CompanyBranchModel {
  final int id;
  final String branchName;
  final String friendlyLocation;
  final double? latitude;
  final double? longitude;
  final String? description;

  const CompanyBranchModel({
    required this.id,
    required this.branchName,
    required this.friendlyLocation,
    this.latitude,
    this.longitude,
    this.description,
  });

  factory CompanyBranchModel.fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse(json['latitude']?.toString() ?? '');
    final lng = double.tryParse(
      json['longtude']?.toString() ?? json['longitude']?.toString() ?? '',
    );

    return CompanyBranchModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      branchName: json['branch_name']?.toString() ?? '',
      friendlyLocation: json['friendly_location']?.toString() ?? '',
      latitude: lat,
      longitude: lng,
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'branch_name': branchName,
        'friendly_location': friendlyLocation,
        'latitude': latitude?.toString(),
        'longtude': longitude?.toString(),
        'description': description,
      };
}

class CorporateItemModel {
  final int id;
  final String name;

  const CorporateItemModel({
    required this.id,
    required this.name,
  });

  factory CorporateItemModel.fromJson(Map<String, dynamic> json) {
    return CorporateItemModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class CompanyDeliveryOptionModel {
  final int id;
  final String carName;
  final double kmPrice;

  const CompanyDeliveryOptionModel({
    required this.id,
    required this.carName,
    required this.kmPrice,
  });

  factory CompanyDeliveryOptionModel.fromJson(Map<String, dynamic> json) {
    return CompanyDeliveryOptionModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      carName: json['car_name']?.toString() ?? '',
      kmPrice: double.tryParse(json['km_price']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'car_name': carName,
        'km_price': kmPrice,
      };
}

class CompanyOrderModel {
  final int id;
  final String status;
  final String? fromBranch;
  final String? toBranch;
  final String? fromFriendlyLocation;
  final String? toFriendlyLocation;
  final String? item;
  final String? senderFName;
  final String? senderLName;
  final String? senderPhone;
  final String? receiverFName;
  final String? receiverLName;
  final String? receiverPhone;
  final String? driverFName;
  final String? driverLName;
  final String? driverPhone;
  final String? carType;
  final double kmPrice;
  final double totalKm;
  final double totalPrice;
  final String? dateTime;

  const CompanyOrderModel({
    required this.id,
    required this.status,
    this.fromBranch,
    this.toBranch,
    this.fromFriendlyLocation,
    this.toFriendlyLocation,
    this.item,
    this.senderFName,
    this.senderLName,
    this.senderPhone,
    this.receiverFName,
    this.receiverLName,
    this.receiverPhone,
    this.driverFName,
    this.driverLName,
    this.driverPhone,
    this.carType,
    this.kmPrice = 0.0,
    this.totalKm = 0.0,
    this.totalPrice = 0.0,
    this.dateTime,
  });

  factory CompanyOrderModel.fromJson(Map<String, dynamic> json) {
    return CompanyOrderModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '0',
      fromBranch: json['from_branch']?.toString(),
      toBranch: json['to_branch']?.toString(),
      fromFriendlyLocation: json['from_friendly_location']?.toString(),
      toFriendlyLocation: json['to_friendly_location']?.toString(),
      item: json['item']?.toString(),
      senderFName: json['sender_f_name']?.toString(),
      senderLName: json['sender_l_name']?.toString(),
      senderPhone: json['sender_phone']?.toString(),
      receiverFName: json['receiver_f_name']?.toString(),
      receiverLName: json['receiver_l_name']?.toString(),
      receiverPhone: json['receiver_phone']?.toString(),
      driverFName: json['driver_f_name']?.toString(),
      driverLName: json['driver_l_name']?.toString(),
      driverPhone: json['driver_phone']?.toString(),
      carType: json['car_type']?.toString(),
      kmPrice: double.tryParse(json['km_price']?.toString() ?? '0') ?? 0.0,
      totalKm: double.tryParse(json['total_km']?.toString() ?? '0') ?? 0.0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      dateTime: json['date_time']?.toString(),
    );
  }

  String get senderFullName {
    final f = senderFName?.trim() ?? '';
    final l = senderLName?.trim() ?? '';
    final full = '$f $l'.trim();
    return full.isNotEmpty ? full : 'Sender';
  }

  String get receiverFullName {
    final f = receiverFName?.trim() ?? '';
    final l = receiverLName?.trim() ?? '';
    final full = '$f $l'.trim();
    return full.isNotEmpty ? full : 'Receiver';
  }

  String? get driverFullName {
    final f = driverFName?.trim() ?? '';
    final l = driverLName?.trim() ?? '';
    final full = '$f $l'.trim();
    return full.isNotEmpty ? full : null;
  }

  bool get hasDriver => driverFullName != null && driverFullName!.isNotEmpty;

  bool get isPending => status == '0';
  bool get isFinished => status != '0';
}
