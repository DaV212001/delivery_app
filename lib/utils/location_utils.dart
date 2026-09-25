import 'dart:math' as math;
import 'package:get/get.dart';

class LocationUtils {
  /// Default center coordinates for Addis Ababa, Ethiopia
  static const double defaultLatitude = 9.0209;
  static const double defaultLongitude = 38.7469;

  /// Calculate distance between two lat/lng coordinates in kilometers using Haversine formula
  static double calculateDistanceInKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;

  /// Formats distance into a badge label (e.g. "Around 1.2km" or "Around 850m")
  static String formatDistanceBadge(double km) {
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '${'around'.tr} ${meters}m';
    }
    return '${'around'.tr} ${km.toStringAsFixed(1)}km';
  }

  /// Formats distance into a clean string (e.g. "1.2 km" or "850 m")
  static String formatDistanceKm(double km) {
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '$meters m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
}
