import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';

/// Request body for creating a courier delivery order: POST /courirer-order
class CourierOrderCreateRequest {
  final double fromLatitude;
  final double fromLongitude;
  final double toLatitude;
  final double toLongitude;
  final int senderUserId;
  final String receiverName;
  final String receiverPhone;
  final int carTypeId;
  final double kmPrice;
  final double totalPrice;
  final String paymentType;
  final String? description;
  final String? fromAddress;
  final String? toAddress;

  const CourierOrderCreateRequest({
    required this.fromLatitude,
    required this.fromLongitude,
    required this.toLatitude,
    required this.toLongitude,
    required this.senderUserId,
    required this.receiverName,
    required this.receiverPhone,
    this.carTypeId = 1,
    this.kmPrice = 35.0,
    required this.totalPrice,
    this.paymentType = '0',
    this.description,
    this.fromAddress,
    this.toAddress,
  });

  Map<String, dynamic> toJson() => {
        'from_latitude': fromLatitude,
        'from_longtude': fromLongitude,
        'to_latitude': toLatitude,
        'to_longtude': toLongitude,
        'sender_user_id': senderUserId,
        'reciver_name': receiverName,
        'reciver_phone': receiverPhone,
        'car_type_id': carTypeId,
        'km_price': kmPrice,
        'total_price': totalPrice,
        'payment_type': paymentType,
        if (description != null && description!.trim().isNotEmpty)
          'description': description!.trim(),
      };
}

/// Representation of an active or past courier order from AMN Delivery API
class CourierOrderModel {
  final int id;
  final String status;
  final double fromLatitude;
  final double fromLongitude;
  final double toLatitude;
  final double toLongitude;
  final String? fromAddress;
  final String? toAddress;
  final String? senderFName;
  final String? senderLName;
  final String? senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String? driverFName;
  final String? driverLName;
  final String? driverPhone;
  final String carType;
  final double kmPrice;
  final double totalKm;
  final double totalPrice;
  final String? dateTime;
  final String? description;

  const CourierOrderModel({
    required this.id,
    required this.status,
    required this.fromLatitude,
    required this.fromLongitude,
    required this.toLatitude,
    required this.toLongitude,
    this.fromAddress,
    this.toAddress,
    this.senderFName,
    this.senderLName,
    this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    this.driverFName,
    this.driverLName,
    this.driverPhone,
    this.carType = 'Motorbike',
    this.kmPrice = 35.0,
    this.totalKm = 0.0,
    required this.totalPrice,
    this.dateTime,
    this.description,
  });

  CourierOrderModel copyWith({
    int? id,
    String? status,
    double? fromLatitude,
    double? fromLongitude,
    double? toLatitude,
    double? toLongitude,
    String? fromAddress,
    String? toAddress,
    String? senderFName,
    String? senderLName,
    String? senderPhone,
    String? receiverName,
    String? receiverPhone,
    String? driverFName,
    String? driverLName,
    String? driverPhone,
    String? carType,
    double? kmPrice,
    double? totalKm,
    double? totalPrice,
    String? dateTime,
    String? description,
  }) {
    return CourierOrderModel(
      id: id ?? this.id,
      status: status ?? this.status,
      fromLatitude: fromLatitude ?? this.fromLatitude,
      fromLongitude: fromLongitude ?? this.fromLongitude,
      toLatitude: toLatitude ?? this.toLatitude,
      toLongitude: toLongitude ?? this.toLongitude,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      senderFName: senderFName ?? this.senderFName,
      senderLName: senderLName ?? this.senderLName,
      senderPhone: senderPhone ?? this.senderPhone,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      driverFName: driverFName ?? this.driverFName,
      driverLName: driverLName ?? this.driverLName,
      driverPhone: driverPhone ?? this.driverPhone,
      carType: carType ?? this.carType,
      kmPrice: kmPrice ?? this.kmPrice,
      totalKm: totalKm ?? this.totalKm,
      totalPrice: totalPrice ?? this.totalPrice,
      dateTime: dateTime ?? this.dateTime,
      description: description ?? this.description,
    );
  }

  factory CourierOrderModel.fromJson(Map<String, dynamic> json) {
    final fromLat = double.tryParse(json['from_latitude']?.toString() ?? '') ?? 0.0;
    final fromLng = double.tryParse(
          json['from_longtude']?.toString() ?? json['from_longitude']?.toString() ?? '',
        ) ??
        0.0;
    final toLat = double.tryParse(json['to_latitude']?.toString() ?? '') ?? 0.0;
    final toLng = double.tryParse(
          json['to_longtude']?.toString() ?? json['to_longitude']?.toString() ?? '',
        ) ??
        0.0;

    return CourierOrderModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '0',
      fromLatitude: fromLat,
      fromLongitude: fromLng,
      toLatitude: toLat,
      toLongitude: toLng,
      fromAddress: json['from_address']?.toString(),
      toAddress: json['to_address']?.toString(),
      senderFName: json['sender_f_name']?.toString(),
      senderLName: json['sender_l_name']?.toString(),
      senderPhone: json['sender_phone']?.toString(),
      receiverName: json['receiver_name']?.toString() ??
          json['reciver_name']?.toString() ??
          '',
      receiverPhone: json['receiver_phone']?.toString() ??
          json['reciver_phone']?.toString() ??
          '',
      driverFName: json['driver_f_name']?.toString(),
      driverLName: json['driver_l_name']?.toString(),
      driverPhone: json['driver_phone']?.toString(),
      carType: json['car_type']?.toString() ?? 'Motorbike',
      kmPrice: double.tryParse(json['km_price']?.toString() ?? '35') ?? 35.0,
      totalKm: double.tryParse(json['total_km']?.toString() ?? '0') ?? 0.0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      dateTime: json['date_time']?.toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'from_latitude': fromLatitude,
        'from_longtude': fromLongitude,
        'to_latitude': toLatitude,
        'to_longtude': toLongitude,
        'sender_f_name': senderFName,
        'sender_l_name': senderLName,
        'sender_phone': senderPhone,
        'receiver_name': receiverName,
        'receiver_phone': receiverPhone,
        'driver_f_name': driverFName,
        'driver_l_name': driverLName,
        'driver_phone': driverPhone,
        'car_type': carType,
        'km_price': kmPrice,
        'total_km': totalKm,
        'total_price': totalPrice,
        'date_time': dateTime,
        'description': description,
      };

  String get senderFullName {
    final parts = [senderFName, senderLName].where((s) => s != null && s.trim().isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(' ') : 'Sender';
  }

  String get driverFullName {
    final parts = [driverFName, driverLName].where((s) => s != null && s.trim().isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(' ') : 'Rider Pending Assignment';
  }

  bool get hasDriverAssigned => driverFName != null && driverFName!.trim().isNotEmpty;

  String get statusTitle {
    switch (status) {
      case '0':
        return 'Pending Rider';
      case '1':
        return 'Rider Assigned';
      case '2':
        return 'In Transit';
      case '3':
      case '4':
        return 'Delivered';
      case '5':
      case '-1':
        return 'Cancelled';
      default:
        return 'In Progress';
    }
  }

  Color get statusColor {
    switch (status) {
      case '0':
        return const Color(0xFFF59E0B); // Amber
      case '1':
        return AppColors.primary;
      case '2':
        return const Color(0xFF0284C7); // Sky blue
      case '3':
        return const Color(0xFF6366F1); // Indigo
      case '4':
        return const Color(0xFF10B981); // Emerald green
      case '5':
      case '-1':
        return const Color(0xFFEF4444); // Red
      default:
        return AppColors.primary;
    }
  }

  /// Formats date_time into clean, human-readable words (e.g. "Today at 7:25 PM", "Yesterday at 3:15 PM")
  String get formattedDateTime {
    if (dateTime == null || dateTime!.trim().isEmpty) return '';
    try {
      final normalized = dateTime!.trim().replaceAll('/', '-');
      final parsed = DateTime.tryParse(normalized);
      if (parsed == null) return dateTime!;

      final now = DateTime.now();
      final difference = now.difference(parsed);

      final timeStr = DateFormat('h:mm a').format(parsed);

      final isToday =
          parsed.year == now.year && parsed.month == now.month && parsed.day == now.day;
      if (isToday) {
        if (difference.inMinutes < 1) return 'Just now';
        if (difference.inMinutes < 60) return '${difference.inMinutes} mins ago';
        return 'Today at $timeStr';
      }

      final yesterday = now.subtract(const Duration(days: 1));
      final isYesterday = parsed.year == yesterday.year &&
          parsed.month == yesterday.month &&
          parsed.day == yesterday.day;
      if (isYesterday) {
        return 'Yesterday at $timeStr';
      }

      if (parsed.year == now.year) {
        return DateFormat('MMM d, h:mm a').format(parsed);
      }

      return DateFormat('MMM d, yyyy • h:mm a').format(parsed);
    } catch (_) {
      return dateTime!;
    }
  }
}
