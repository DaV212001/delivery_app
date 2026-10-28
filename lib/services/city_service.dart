import '../config/dio_config.dart';
import '../constants/api_endpoints.dart';
import '../models/city_model.dart';
import '../utils/templates/dio_template.dart';

class CityService {
  /// In-memory cache of cities fetched from https://api.amnplc.com/api/city
  static List<CityModel> _cachedCities = [];
  static DateTime? _lastFetchTime;

  /// Default fallback city id for Addis Ababa if matching cannot find another city
  static const int defaultCityId = 1;

  /// Seed list of known cities from backend for offline/fallback mode
  static final List<CityModel> fallbackCities = [
    const CityModel(id: 1, name: 'Addis Ababa', status: '1'),
    const CityModel(id: 2, name: 'Hawassa', status: '1'),
    const CityModel(id: 4, name: 'Harar', status: '1'),
    const CityModel(id: 5, name: 'Mizan Teferi', status: '1'),
    const CityModel(id: 6, name: 'Dilla', status: '1'),
    const CityModel(id: 7, name: 'united Arab Emirates', status: '1'),
    const CityModel(id: 8, name: 'Turkey', status: '1'),
    const CityModel(id: 9, name: 'Uganda', status: '1'),
    const CityModel(id: 10, name: 'Bahir Dar', status: '1'),
    const CityModel(id: 11, name: 'Debrebirhan', status: '1'),
    const CityModel(id: 12, name: 'shashamene', status: '1'),
    const CityModel(id: 13, name: 'jijiga', status: '1'),
    const CityModel(id: 14, name: 'Dire dewa', status: '1'),
    const CityModel(id: 15, name: 'Adama', status: '1'),
    const CityModel(id: 16, name: 'Bishoftu', status: '1'),
    const CityModel(id: 17, name: 'Djibouti', status: '1'),
  ];

  /// Clear cached cities (useful in unit tests)
  static void clearCache() {
    _cachedCities = [];
    _lastFetchTime = null;
  }

  /// Manually populate cached cities (useful in unit tests)
  static void setCachedCities(List<CityModel> cities) {
    _cachedCities = List.from(cities);
    _lastFetchTime = DateTime.now();
  }

  /// Fetch list of cities from GET /city
  static Future<List<CityModel>> getCities({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedCities.isNotEmpty &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 60) {
      return List.unmodifiable(_cachedCities);
    }

    if (DioConfig.isTestMode) {
      _cachedCities = List.from(fallbackCities);
      _lastFetchTime = DateTime.now();
      return List.unmodifiable(_cachedCities);
    }

    try {
      final cities = <CityModel>[];
      await DioService.dioGet(
        path: ApiEndpoints.city,
        onSuccess: (response) {
          final data = response.data;
          if (data is Map<String, dynamic> && data['data'] is List) {
            for (final item in data['data']) {
              if (item is Map<String, dynamic>) {
                cities.add(CityModel.fromJson(item));
              }
            }
          }
        },
        onFailure: (error, response) {
          // Failure will fall back to cache or predefined list
        },
      );

      if (cities.isNotEmpty) {
        _cachedCities = cities;
        _lastFetchTime = DateTime.now();
      }
    } catch (_) {}

    if (_cachedCities.isEmpty) {
      _cachedCities = List.from(fallbackCities);
    }

    return List.unmodifiable(_cachedCities);
  }

  /// Normalizes a string for fuzzy matching (lowercase, alphanumeric only)
  static String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Match a reverse geocoded text (address, raw Gebeta response text, or place name)
  /// against the city list from https://api.amnplc.com/api/city
  /// and return the corresponding city_id.
  static Future<int> matchCityIdFromGeocode(
    String geocodeText, {
    Map<String, dynamic>? rawGebetaResponse,
  }) async {
    final cities = await getCities();

    // 1. Inspect raw Gebeta response structured fields if available
    final candidateTexts = <String>[];

    if (rawGebetaResponse != null) {
      final address = rawGebetaResponse['address'];
      if (address is Map) {
        for (final key in ['district', 'borough', 'municipality', 'county', 'province']) {
          final field = address[key];
          if (field is Map) {
            if (field['EN'] != null) candidateTexts.add(field['EN'].toString());
            if (field['AM'] != null) candidateTexts.add(field['AM'].toString());
          } else if (field != null) {
            candidateTexts.add(field.toString());
          }
        }
      }

      final dataList = rawGebetaResponse['data'];
      if (dataList is List) {
        for (final item in dataList.take(5)) {
          if (item is Map) {
            if (item['City'] != null) candidateTexts.add(item['City'].toString());
            if (item['name'] != null) candidateTexts.add(item['name'].toString());
          }
        }
      }
    }

    // Include the geocodeText itself
    if (geocodeText.trim().isNotEmpty) {
      candidateTexts.add(geocodeText);
    }

    // Helper aliases for common Ethiopian naming variations
    final aliases = <String, String>{
      'nazret': 'adama',
      'nazreth': 'adama',
      'debreberhan': 'debrebirhan',
      'debre berhan': 'debrebirhan',
      'finfinne': 'addis ababa',
      'finfine': 'addis ababa',
      'diredawa': 'dire dewa',
      'dire dawa': 'dire dewa',
      'hawasa': 'hawassa',
      'shashemene': 'shashamene',
      'jigjiga': 'jijiga',
      'dila': 'dilla',
      'mizan': 'mizan teferi',
      'mizan aman': 'mizan teferi',
    };

    // Check candidate texts against cities
    for (final candidate in candidateTexts) {
      final normCandidate = _normalize(candidate);
      if (normCandidate.isEmpty) continue;

      // Check aliases first
      for (final aliasEntry in aliases.entries) {
        if (normCandidate.contains(_normalize(aliasEntry.key))) {
          final matchedCity = cities.firstWhere(
            (c) => _normalize(c.name) == _normalize(aliasEntry.value),
            orElse: () => const CityModel(id: 0, name: ''),
          );
          if (matchedCity.id > 0) {
            return matchedCity.id;
          }
        }
      }

      // Check direct containment or equality
      for (final city in cities) {
        final normCityName = _normalize(city.name);
        if (normCityName.isEmpty) continue;

        if (normCandidate == normCityName ||
            normCandidate.contains(normCityName) ||
            normCityName.contains(normCandidate)) {
          return city.id;
        }
      }
    }

    // Fallback: check if the geocode text contains any city name directly
    final fullNorm = _normalize(geocodeText);
    for (final city in cities) {
      final normCity = _normalize(city.name);
      if (normCity.isNotEmpty && fullNorm.contains(normCity)) {
        return city.id;
      }
    }

    return defaultCityId;
  }
}
