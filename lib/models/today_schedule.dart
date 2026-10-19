import 'package:get/get.dart';

class TodaySchedule {
  final bool isClosed;
  final String? openTime;
  final String? closeTime;

  const TodaySchedule({
    required this.isClosed,
    this.openTime,
    this.closeTime,
  });

  factory TodaySchedule.fromJson(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) {
      return const TodaySchedule(isClosed: false);
    }

    final rawClosed = json['is_closed'];
    final bool closed = rawClosed == true ||
        rawClosed == 1 ||
        rawClosed == '1' ||
        rawClosed == 'true';

    return TodaySchedule(
      isClosed: closed,
      openTime: json['open_time']?.toString(),
      closeTime: json['close_time']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'is_closed': isClosed,
        'open_time': openTime,
        'close_time': closeTime,
      };

  /// Returns true if the store is currently open right now
  bool get isOpenNow {
    if (isClosed) return false;

    if (openTime == null ||
        openTime!.trim().isEmpty ||
        closeTime == null ||
        closeTime!.trim().isEmpty) {
      return true; // No restrictive hours specified
    }

    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;

      final openParts = openTime!.trim().split(':');
      final closeParts = closeTime!.trim().split(':');

      if (openParts.length < 2 || closeParts.length < 2) return true;

      final openHour = int.tryParse(openParts[0]);
      final openMinute = int.tryParse(openParts[1]);
      final closeHour = int.tryParse(closeParts[0]);
      final closeMinute = int.tryParse(closeParts[1]);

      if (openHour == null ||
          openMinute == null ||
          closeHour == null ||
          closeMinute == null) {
        return true;
      }

      final openMinutes = openHour * 60 + openMinute;
      final closeMinutes = closeHour * 60 + closeMinute;

      if (closeMinutes >= openMinutes) {
        // Standard same-day opening (e.g. 08:30 to 17:30)
        return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
      } else {
        // Overnight opening (e.g. 18:00 to 02:00 next day)
        return currentMinutes >= openMinutes || currentMinutes < closeMinutes;
      }
    } catch (_) {
      return true;
    }
  }

  /// Calculates the next DateTime when this store opens
  DateTime get nextOpenDateTime {
    final now = DateTime.now();
    int openHour = 8;
    int openMinute = 30;

    if (openTime != null && openTime!.trim().isNotEmpty) {
      final parts = openTime!.trim().split(':');
      if (parts.length >= 2) {
        openHour = int.tryParse(parts[0]) ?? 8;
        openMinute = int.tryParse(parts[1]) ?? 30;
      }
    }

    final todayOpen = DateTime(now.year, now.month, now.day, openHour, openMinute);

    if (!isClosed && now.isBefore(todayOpen)) {
      return todayOpen;
    }

    // Opens tomorrow at openHour:openMinute
    return todayOpen.add(const Duration(days: 1));
  }

  /// Formatted open time e.g. "08:30 AM"
  String? get formattedOpenTime {
    if (openTime == null || openTime!.trim().isEmpty) return null;
    return _formatTimeString(openTime!);
  }

  /// Formatted close time e.g. "05:30 PM"
  String? get formattedCloseTime {
    if (closeTime == null || closeTime!.trim().isEmpty) return null;
    return _formatTimeString(closeTime!);
  }

  /// User friendly schedule status message
  String get statusMessage {
    if (isClosed) {
      return 'store_closed_today'.tr;
    }

    if (!isOpenNow) {
      if (formattedOpenTime != null) {
        final now = DateTime.now();
        final currentMinutes = now.hour * 60 + now.minute;
        final openParts = openTime!.trim().split(':');
        final openHour = int.tryParse(openParts[0]) ?? 0;
        final openMinute = int.tryParse(openParts[1]) ?? 0;
        final openMinutes = openHour * 60 + openMinute;

        if (currentMinutes < openMinutes) {
          return '${'store_closed_opens_at'.tr} $formattedOpenTime';
        } else {
          return '${'store_closed_opens_tomorrow'.tr} $formattedOpenTime';
        }
      }
      return 'store_currently_closed'.tr;
    }

    if (formattedCloseTime != null) {
      return '${'open_until'.tr} $formattedCloseTime';
    }

    return 'store_open'.tr;
  }

  static String _formatTimeString(String timeStr) {
    final parts = timeStr.trim().split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        final period = hour >= 12 ? 'PM' : 'AM';
        final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final m = minute.toString().padLeft(2, '0');
        return '$h:$m $period';
      }
    }
    return timeStr;
  }
}
