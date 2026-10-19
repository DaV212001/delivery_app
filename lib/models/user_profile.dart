import '../constants/app_assets.dart';

class UserProfile {
  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String avatarUrl;
  final String tagline;
  final double rating;
  final int totalOrders;
  final String defaultAddress;
  final double walletAmount;
  final String type;
  final String haveProperty;
  final String companyId;
  final String branchId;

  const UserProfile({
    required this.id,
    required this.name,
    this.firstName = '',
    this.lastName = '',
    required this.email,
    this.phone = '',
    required this.avatarUrl,
    required this.tagline,
    required this.rating,
    required this.totalOrders,
    required this.defaultAddress,
    this.walletAmount = 0.0,
    this.type = '0',
    this.haveProperty = '0',
    this.companyId = '0',
    this.branchId = '0',
  });

  bool get isCorporateUser {
    final t = type.trim();
    final c = companyId.trim();
    final b = branchId.trim();
    return t == '1' &&
        c.isNotEmpty &&
        c != '0' &&
        b.isNotEmpty &&
        b != '0';
  }

  factory UserProfile.fromJson(Map<String, dynamic> rawJson) {
    final json = (rawJson['user'] is Map<String, dynamic>)
        ? rawJson['user'] as Map<String, dynamic>
        : (rawJson['data'] is Map<String, dynamic>
            ? rawJson['data'] as Map<String, dynamic>
            : rawJson);

    var firstName = json['f_name']?.toString() ?? rawJson['f_name']?.toString() ?? '';
    var lastName = json['l_name']?.toString() ?? rawJson['l_name']?.toString() ?? '';
    final rawName = json['name']?.toString() ?? rawJson['name']?.toString() ?? '';

    if (firstName.isEmpty && lastName.isEmpty && rawName.isNotEmpty) {
      final parts = rawName.trim().split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        firstName = parts.first;
        if (parts.length > 1) {
          lastName = parts.sublist(1).join(' ');
        }
      }
    }

    final fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : (rawName.isNotEmpty ? rawName : 'User');

    final photo = json['profile_picture']?.toString() ??
        json['profile_image']?.toString() ??
        json['avatarUrl']?.toString() ??
        rawJson['profile_picture']?.toString() ??
        rawJson['profile_image']?.toString() ??
        '';

    final wallet = double.tryParse(json['wallet_amount']?.toString() ??
            rawJson['wallet_amount']?.toString() ??
            '0') ??
        0.0;

    final id = json['id']?.toString() ??
        rawJson['id']?.toString() ??
        json['user_id']?.toString() ??
        rawJson['user_id']?.toString() ??
        '';

    final type = json['type']?.toString() ?? rawJson['type']?.toString() ?? '0';
    final haveProperty = json['have_property']?.toString() ?? rawJson['have_property']?.toString() ?? '0';
    final companyId = json['company_id']?.toString() ?? rawJson['company_id']?.toString() ?? '0';
    final branchId = json['branch_id']?.toString() ?? rawJson['branch_id']?.toString() ?? '0';

    return UserProfile(
      id: id,
      name: fullName,
      firstName: firstName,
      lastName: lastName,
      email: json['email']?.toString() ?? rawJson['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? rawJson['phone']?.toString() ?? '',
      avatarUrl: photo.isNotEmpty ? photo : AppAssets.userAvatar,
      tagline: json['tagline']?.toString() ?? 'AMN Delivery Customer',
      rating: double.tryParse(json['rating']?.toString() ?? '4.9') ?? 4.9,
      totalOrders: int.tryParse(json['total_orders']?.toString() ?? '0') ?? 0,
      defaultAddress: json['default_address']?.toString() ?? 'Addis Ababa, Ethiopia',
      walletAmount: wallet,
      type: type,
      haveProperty: haveProperty,
      companyId: companyId,
      branchId: branchId,
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? tagline,
    double? rating,
    int? totalOrders,
    String? defaultAddress,
    double? walletAmount,
    String? type,
    String? haveProperty,
    String? companyId,
    String? branchId,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      tagline: tagline ?? this.tagline,
      rating: rating ?? this.rating,
      totalOrders: totalOrders ?? this.totalOrders,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      walletAmount: walletAmount ?? this.walletAmount,
      type: type ?? this.type,
      haveProperty: haveProperty ?? this.haveProperty,
      companyId: companyId ?? this.companyId,
      branchId: branchId ?? this.branchId,
    );
  }
}
