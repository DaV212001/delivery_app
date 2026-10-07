import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gebeta_gl/gebeta_gl.dart';
import '../config/dio_config.dart';
import '../models/gebeta_route.dart';

class GebetaLocationService {
  static const String apiKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb21wYW55bmFtZSI6IkFtYW51ZWwiLCJkZXNjcmlwdGlvbiI6IjgyMGIyYzY2LThjOWYtNDAxOS1hZjljLWYxNjU5M2U0ZWEyNyIsImlkIjoiYjIwNTliNDktMTQ2OC00YzZhLWI5YjktMjJhNjljZDNjNTA1IiwidXNlcm5hbWUiOiJhbWFudWVsdGlsYWh1biJ9.TPBHHhfOYMcHNO8Y8h52SCivIROcXAdmiAgHBOapkeQ';

  /// Configure native MapLibre HTTP engine with required Origin and Authorization headers
  /// so that vector tiles from https://tiles.gebeta.app succeed with 200 OK.
  static Future<void> configureMapHeaders() async {
    try {
      await setHttpHeaders({
        'Origin': 'https://gebeta.app',
        'Authorization': 'Bearer $apiKey',
      });
    } catch (_) {}
  }

  /// In-memory cache for coordinates to reverse-geocoded addresses
  static final Map<String, String> _addressCache = {};

  /// Get current GPS position with permission and system prompt handling.
  /// Prompts for permission if denied, and triggers the Android/iOS system prompt
  /// to turn on device location if location services are turned off.
  static Future<Position?> getCurrentPosition({bool promptIfDeniedForever = false}) async {
    if (DioConfig.isTestMode) {
      return Position(
        latitude: 9.0104,
        longitude: 38.7617,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 2355.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      // Always request permission if currently denied (automatic system prompt when user opens app)
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (promptIfDeniedForever && Get.context != null) {
          _showLocationSettingsDialog();
        }
        return null;
      }

      // Do NOT abort if location services are off; calling getCurrentPosition()
      // triggers the OS / Google Play Services native system resolution prompt
      // ("To continue, turn on device location" [No thanks] [OK]).
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } on LocationServiceDisabledException {
        // User declined the native system prompt ("No thanks")
        if (promptIfDeniedForever) {
          await Geolocator.openLocationSettings();
        }
        return null;
      } catch (_) {
        return await Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      return null;
    }
  }

  static void _showLocationSettingsDialog() {
    if (Get.context == null) return;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'location_permission'.tr.isNotEmpty ? 'location_permission'.tr : 'Location Permission',
        ),
        content: Text(
          'location_permission_needed'.tr.isNotEmpty
              ? 'location_permission_needed'.tr
              : 'AMN Delivery requires your location to calculate distance to nearby restaurants. Please enable it in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Geolocator.openAppSettings();
            },
            child: Text(
              'open_settings'.tr.isNotEmpty ? 'open_settings'.tr : 'Open Settings',
            ),
          ),
        ],
      ),
    );
  }

  /// Reverse geocode latitude and longitude using Gebeta Maps API
  static Future<String> reverseGeocode(double lat, double lng) async {
    final cacheKey = '${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}';
    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey]!;
    }

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final url =
          'https://mapapi.gebeta.app/api/v1/route/revgeocoding?lat=$lat&lon=$lng&apiKey=$apiKey';

      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is List && data.isNotEmpty) {
          final first = data.first;
          final name = first['name']?.toString() ?? '';
          final city = first['City']?.toString() ?? '';
          final country = first['Country']?.toString() ?? '';

          final parts = [name, city, country]
              .where((s) => s.trim().isNotEmpty)
              .toList();

          if (parts.isNotEmpty) {
            final formatted = parts.join(', ');
            _addressCache[cacheKey] = formatted;
            return formatted;
          }
        }
      }
    } catch (_) {}

    final fallback = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)} (Addis Ababa)';
    _addressCache[cacheKey] = fallback;
    return fallback;
  }

  /// In-memory cache for Gebeta Maps routes
  static final Map<String, GebetaRoute> _routeCache = {};

  /// Convenience method: fetches current location and returns reverse geocoded address
  static Future<String?> fetchCurrentLocationAddress({bool promptIfDeniedForever = false}) async {
    final pos = await getCurrentPosition(promptIfDeniedForever: promptIfDeniedForever);
    if (pos == null) return null;
    return await reverseGeocode(pos.latitude, pos.longitude);
  }

  /// Fetch road route between origin and destination coordinates using Gebeta Maps Directions API.
  /// Falls back gracefully to realistic interpolated polyline if offline, API error, or in test mode.
  static Future<GebetaRoute> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final cacheKey =
        '${originLat.toStringAsFixed(4)}_${originLng.toStringAsFixed(4)}_${destLat.toStringAsFixed(4)}_${destLng.toStringAsFixed(4)}';
    if (_routeCache.containsKey(cacheKey)) {
      return _routeCache[cacheKey]!;
    }

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final url =
          'https://mapapi.gebeta.app/api/route/direction/?origin=$originLat,$originLng&destination=$destLat,$destLng&apiKey=$apiKey';

      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final rawDirection = data['direction'];
        final totalDist = double.tryParse(data['totalDistance']?.toString() ?? '0') ?? 0.0;
        final timeTaken = double.tryParse(data['timetaken']?.toString() ?? '0') ?? 0.0;

        if (rawDirection is List && rawDirection.isNotEmpty) {
          final pts = <LatLng>[];
          for (final item in rawDirection) {
            if (item is List && item.length >= 2) {
              final lat = double.tryParse(item[0]?.toString() ?? '');
              final lng = double.tryParse(item[1]?.toString() ?? '');
              if (lat != null && lng != null) {
                pts.add(LatLng(lat, lng));
              }
            }
          }

          if (pts.isNotEmpty) {
            final route = GebetaRoute(
              points: pts,
              totalDistanceMeters: totalDist > 0 ? totalDist : pts.length * 50.0,
              timeTakenSeconds: timeTaken > 0 ? timeTaken : 600.0,
            );
            _routeCache[cacheKey] = route;
            return route;
          }
        }
      }
    } catch (_) {}

    final fallback = GebetaRoute.generateFallbackRoute(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );
    _routeCache[cacheKey] = fallback;
    return fallback;
  }
}
