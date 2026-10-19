class PropertyScheduleItem {
  final int? id;
  final int dayOfWeek; // 0 = Sunday, 1 = Monday, 2 = Tuesday, 3 = Wednesday, 4 = Thursday, 5 = Friday, 6 = Saturday
  final bool isClosed;
  final String? openTime; // "HH:mm" e.g. "08:30"
  final String? closeTime; // "HH:mm" e.g. "17:30"

  const PropertyScheduleItem({
    this.id,
    required this.dayOfWeek,
    required this.isClosed,
    this.openTime,
    this.closeTime,
  });

  /// Normalize "08:30:00" or "8:30" to standard "HH:mm"
  static String? normalizeTime(dynamic time) {
    if (time == null) return null;
    final str = time.toString().trim();
    if (str.isEmpty || str == 'null') return null;
    final parts = str.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    return str;
  }

  factory PropertyScheduleItem.fromJson(Map<String, dynamic> json) {
    int parsedDay = 0;
    if (json['day_of_week'] != null) {
      parsedDay = int.tryParse(json['day_of_week'].toString()) ?? 0;
    }

    final rawClosed = json['is_closed'];
    final bool parsedClosed = rawClosed == true ||
        rawClosed == 1 ||
        rawClosed == '1' ||
        rawClosed == 'true';

    return PropertyScheduleItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      dayOfWeek: parsedDay,
      isClosed: parsedClosed,
      openTime: normalizeTime(json['open_time']),
      closeTime: normalizeTime(json['close_time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'is_closed': isClosed,
      'open_time': isClosed ? null : normalizeTime(openTime),
      'close_time': isClosed ? null : normalizeTime(closeTime),
    };
  }

  PropertyScheduleItem copyWith({
    int? id,
    int? dayOfWeek,
    bool? isClosed,
    String? openTime,
    String? closeTime,
  }) {
    return PropertyScheduleItem(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isClosed: isClosed ?? this.isClosed,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 0:
      case 7:
        return 'Sunday';
      default:
        return 'Day $dayOfWeek';
    }
  }

  String get dayKey {
    switch (dayOfWeek) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 0:
      case 7:
        return 'sunday';
      default:
        return 'day';
    }
  }

  /// Whether the given time string is in the daytime (06:00 to 17:59)
  static bool isTimeDay(String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return true;
    final parts = timeStr.split(':');
    final h = int.tryParse(parts[0]) ?? 8;
    return h >= 6 && h < 18;
  }
}
