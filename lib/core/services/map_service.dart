import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../data/vietnam_admin_units.dart';

class MapLocationResult {
  const MapLocationResult({
    required this.address,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.placeId,
  });

  final String address;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String placeId;

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'formattedAddress': formattedAddress,
      'lat': latitude,
      'lng': longitude,
      'placeId': placeId,
      'source': 'google_geocoding',
    };
  }
}

class _ProvinceSearchHint {
  const _ProvinceSearchHint({
    required this.name,
    this.centerLat,
    this.centerLng,
    this.minLat,
    this.maxLat,
    this.minLng,
    this.maxLng,
    required this.aliases,
  });

  final String name;
  final double? centerLat;
  final double? centerLng;
  final double? minLat;
  final double? maxLat;
  final double? minLng;
  final double? maxLng;
  final List<String> aliases;

  bool matches(String normalizedAddress) {
    return aliases.any(normalizedAddress.contains);
  }

  bool get hasBounds =>
      minLat != null && maxLat != null && minLng != null && maxLng != null;

  bool get hasCenter => centerLat != null && centerLng != null;

  bool contains(double latitude, double longitude) {
    if (!hasBounds) return true;
    return latitude >= minLat! &&
        latitude <= maxLat! &&
        longitude >= minLng! &&
        longitude <= maxLng!;
  }

  String? get bounds {
    if (!hasBounds) return null;
    return '$minLat,$minLng|$maxLat,$maxLng';
  }

  MapLocationResult? fallbackResult(String originalAddress) {
    if (!hasCenter) return null;
    return MapLocationResult(
      address: originalAddress,
      formattedAddress: '$name, Viet Nam',
      latitude: centerLat!,
      longitude: centerLng!,
      placeId: '',
    );
  }
}

class MapService {
  static const _configChannel = MethodChannel('smart_room_iot_app/config');
  static const _googleMapsAndroidApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_ANDROID_API_KEY',
    defaultValue: '',
  );
  static const _legacyGoogleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
  static const _googleGeocodingApiKey = String.fromEnvironment(
    'GOOGLE_GEOCODING_API_KEY',
    defaultValue: '',
  );
  static String? _cachedNativeGoogleMapsApiKey;
  static String? _cachedNativeGoogleGeocodingApiKey;

  static const _provinceSearchHints = <_ProvinceSearchHint>[
    _ProvinceSearchHint(
      name: 'Da Nang',
      centerLat: 16.0471,
      centerLng: 108.2068,
      minLat: 15.75,
      maxLat: 16.35,
      minLng: 107.8,
      maxLng: 108.55,
      aliases: ['da nang', 'ngu hanh son', 'ngu hanh'],
    ),
    _ProvinceSearchHint(
      name: 'Dak Lak',
      centerLat: 12.7100,
      centerLng: 108.2378,
      minLat: 11.85,
      maxLat: 13.45,
      minLng: 107.45,
      maxLng: 109.15,
      aliases: [
        'dak lak',
        'dak lawk',
        'dak lac',
        'dac lak',
        'dac lac',
        'buon ma thuot',
      ],
    ),
  ];

  static final _genericProvinceSearchHints = <_ProvinceSearchHint>[
    for (final province in vietnamProvinces)
      _ProvinceSearchHint(
        name: province.name,
        aliases: _provinceAliases(province.name),
      ),
  ];

  static Future<bool> hasGoogleMapsApiKey() async {
    return (await googleMapsApiKey()).isNotEmpty;
  }

  static Future<bool> hasGoogleGeocodingApiKey() async {
    return (await googleGeocodingApiKey()).isNotEmpty;
  }

  static Future<String> googleMapsApiKey() async {
    if (_googleMapsAndroidApiKey.isNotEmpty) return _googleMapsAndroidApiKey;
    if (_legacyGoogleMapsApiKey.isNotEmpty) return _legacyGoogleMapsApiKey;
    if (_cachedNativeGoogleMapsApiKey != null) {
      return _cachedNativeGoogleMapsApiKey!;
    }

    try {
      final key = await _configChannel.invokeMethod<String>('googleMapsApiKey');
      _cachedNativeGoogleMapsApiKey = key?.trim() ?? '';
    } on PlatformException {
      _cachedNativeGoogleMapsApiKey = '';
    } on MissingPluginException {
      _cachedNativeGoogleMapsApiKey = '';
    }

    return _cachedNativeGoogleMapsApiKey!;
  }

  static Future<String> googleGeocodingApiKey() async {
    if (_googleGeocodingApiKey.isNotEmpty) return _googleGeocodingApiKey;
    if (_cachedNativeGoogleGeocodingApiKey != null) {
      return _cachedNativeGoogleGeocodingApiKey!;
    }

    try {
      final key = await _configChannel.invokeMethod<String>(
        'googleGeocodingApiKey',
      );
      _cachedNativeGoogleGeocodingApiKey = key?.trim() ?? '';
    } on PlatformException {
      _cachedNativeGoogleGeocodingApiKey = '';
    } on MissingPluginException {
      _cachedNativeGoogleGeocodingApiKey = '';
    }

    if (_cachedNativeGoogleGeocodingApiKey!.isNotEmpty) {
      return _cachedNativeGoogleGeocodingApiKey!;
    }

    _cachedNativeGoogleGeocodingApiKey = await googleMapsApiKey();
    return _cachedNativeGoogleGeocodingApiKey!;
  }

  Future<MapLocationResult?> geocodeAddress(String address) async {
    final trimmedAddress = address.trim();
    final apiKey = await googleGeocodingApiKey();
    if (trimmedAddress.isEmpty || apiKey.isEmpty) return null;

    final provinceHint = _provinceHintForAddress(trimmedAddress);
    MapLocationResult? bestResult;
    var bestScore = -1000000;
    String? lastStatus;
    String? lastErrorMessage;

    for (final query in _addressQueries(trimmedAddress)) {
      final response = await http
          .get(_geocodeUri(query, trimmedAddress, apiKey))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Google Maps geocoding qua lau.');
            },
          );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        continue;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) continue;

      lastStatus = decoded['status']?.toString();
      lastErrorMessage = decoded['error_message']?.toString();
      if (lastStatus != 'OK') {
        if (lastStatus == 'ZERO_RESULTS') continue;
        throw Exception(
          'Google Geocoding $lastStatus'
          '${lastErrorMessage == null ? '' : ': $lastErrorMessage'}',
        );
      }

      final results = decoded['results'];
      if (results is! List || results.isEmpty) continue;

      for (final item in results) {
        final result = _readLocationResult(item, trimmedAddress);
        if (result == null) continue;

        final score = _scoreResult(result, trimmedAddress);
        if (score > bestScore) {
          bestScore = score;
          bestResult = result;
        }
      }
    }

    if (bestResult != null) {
      if (provinceHint == null ||
          provinceHint.contains(bestResult.latitude, bestResult.longitude)) {
        return bestResult;
      }

      return provinceHint.fallbackResult(trimmedAddress) ?? bestResult;
    }

    final fallbackResult = provinceHint?.fallbackResult(trimmedAddress);
    if (fallbackResult != null) return fallbackResult;

    if (lastStatus != null && lastStatus != 'ZERO_RESULTS') {
      throw Exception(
        'Google Geocoding $lastStatus'
        '${lastErrorMessage == null ? '' : ': $lastErrorMessage'}',
      );
    }

    return null;
  }

  static Map<String, dynamic> addressOnlyLocation(String address) {
    final trimmedAddress = address.trim();
    if (trimmedAddress.isEmpty) return {};

    return {
      'address': trimmedAddress,
      'query': trimmedAddress,
      'source': 'address_only',
    };
  }

  static bool canOpenDirections(Map<String, dynamic> building) {
    return _destination(building).isNotEmpty;
  }

  static Future<bool> openDirectionsForBuilding(
    Map<String, dynamic> building,
  ) async {
    final destination = _destination(building);
    if (destination.isEmpty) return false;

    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _destination(Map<String, dynamic> building) {
    final location = _readMap(building['location']);
    final lat = _readDouble(location['lat']);
    final lng = _readDouble(location['lng']);

    if (lat != null && lng != null) return '$lat,$lng';

    final locationAddress = location['formattedAddress']?.toString().trim();
    if (locationAddress != null && locationAddress.isNotEmpty) {
      return locationAddress;
    }

    final address = building['address']?.toString().trim() ?? '';
    return address;
  }

  static Map<String, dynamic> _readMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, dynamic value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  static double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static Uri _geocodeUri(String query, String originalAddress, String apiKey) {
    final provinceHint = _provinceHintForAddress(originalAddress);
    final params = <String, String>{
      'address': query,
      'language': 'vi',
      'region': 'vn',
      'components': 'country:VN',
      'key': apiKey,
    };

    final bounds = provinceHint?.bounds;
    if (bounds != null) {
      params['bounds'] = bounds;
    }

    return Uri.https('maps.googleapis.com', '/maps/api/geocode/json', params);
  }

  static List<String> _addressQueries(String address) {
    final normalized = _normalize(address);
    final provinceHint = _provinceHintForAddress(address);
    final queries = <String>[address, '$address, Viet Nam'];

    if (provinceHint != null) {
      queries.insert(0, '${provinceHint.name}, Viet Nam');
      queries.insert(0, '$address, ${provinceHint.name}, Viet Nam');
    }

    if (normalized.contains('ngu hanh son')) {
      queries.insert(0, 'Ngu Hanh Son, Da Nang, Viet Nam');
    }

    return queries.toSet().toList();
  }

  static MapLocationResult? _readLocationResult(
    Object? value,
    String originalAddress,
  ) {
    final item = _readMap(value);
    if (item.isEmpty) return null;

    final geometry = _readMap(item['geometry']);
    final location = _readMap(geometry['location']);
    final latitude = _readDouble(location['lat']);
    final longitude = _readDouble(location['lng']);
    if (latitude == null || longitude == null) return null;

    return MapLocationResult(
      address: originalAddress,
      formattedAddress:
          item['formatted_address']?.toString().trim() ?? originalAddress,
      latitude: latitude,
      longitude: longitude,
      placeId: item['place_id']?.toString().trim() ?? '',
    );
  }

  static int _scoreResult(MapLocationResult result, String originalAddress) {
    final normalizedQuery = _normalize(originalAddress);
    final normalizedAddress = _normalize(result.formattedAddress);
    final provinceHint = _provinceHintForAddress(originalAddress);
    var score = 0;

    if (provinceHint != null) {
      score += provinceHint.contains(result.latitude, result.longitude)
          ? 1000
          : -2000;
      if (normalizedAddress.contains(_normalize(provinceHint.name)) ||
          provinceHint.aliases.any(normalizedAddress.contains)) {
        score += 300;
      }
    }

    if (normalizedQuery.contains('ngu hanh son')) {
      if (normalizedAddress.contains('ngu hanh son')) score += 300;
    }

    for (final token in normalizedQuery.split(RegExp(r'\s+'))) {
      if (token.length < 3) continue;
      if (normalizedAddress.contains(token)) score += 20;
    }

    return score;
  }

  static MapLocationResult? suggestedLocationForAddress(String address) {
    final provinceHint = _provinceHintForAddress(address);
    if (provinceHint == null) return null;
    return provinceHint.fallbackResult(address.trim());
  }

  static bool isOutsideExpectedProvince(
    String address,
    double latitude,
    double longitude,
  ) {
    final provinceHint = _provinceHintForAddress(address);
    if (provinceHint == null || !provinceHint.hasBounds) return false;
    return !provinceHint.contains(latitude, longitude);
  }

  static _ProvinceSearchHint? _provinceHintForAddress(String address) {
    final normalized = _normalize(address);
    for (final hint in _provinceSearchHints) {
      if (hint.matches(normalized)) return hint;
    }
    for (final hint in _genericProvinceSearchHints) {
      if (hint.matches(normalized)) return hint;
    }
    return null;
  }

  static List<String> _provinceAliases(String provinceName) {
    final normalized = _normalize(provinceName);
    final aliases = <String>{normalized};

    for (final prefix in const ['tp ', 'tinh ', 'thanh pho ']) {
      if (normalized.startsWith(prefix)) {
        aliases.add(normalized.substring(prefix.length));
      }
    }

    if (normalized == 'tp ho chi minh') {
      aliases.addAll({
        'ho chi minh',
        'hcm',
        'tp hcm',
        'tphcm',
        'sai gon',
        'saigon',
      });
    }

    return aliases.toList(growable: false);
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(
          RegExp(
            '[\\u00E0\\u00E1\\u1EA1\\u1EA3\\u00E3'
            '\\u00E2\\u1EA7\\u1EA5\\u1EAD\\u1EA9\\u1EAB'
            '\\u0103\\u1EB1\\u1EAF\\u1EB7\\u1EB3\\u1EB5]',
          ),
          'a',
        )
        .replaceAll(
          RegExp(
            '[\\u00E8\\u00E9\\u1EB9\\u1EBB\\u1EBD'
            '\\u00EA\\u1EC1\\u1EBF\\u1EC7\\u1EC3\\u1EC5]',
          ),
          'e',
        )
        .replaceAll(RegExp('[\\u00EC\\u00ED\\u1ECB\\u1EC9\\u0129]'), 'i')
        .replaceAll(
          RegExp(
            '[\\u00F2\\u00F3\\u1ECD\\u1ECF\\u00F5'
            '\\u00F4\\u1ED3\\u1ED1\\u1ED9\\u1ED5\\u1ED7'
            '\\u01A1\\u1EDD\\u1EDB\\u1EE3\\u1EDF\\u1EE1]',
          ),
          'o',
        )
        .replaceAll(
          RegExp(
            '[\\u00F9\\u00FA\\u1EE5\\u1EE7\\u0169'
            '\\u01B0\\u1EEB\\u1EE9\\u1EF1\\u1EED\\u1EEF]',
          ),
          'u',
        )
        .replaceAll(RegExp('[\\u1EF3\\u00FD\\u1EF5\\u1EF7\\u1EF9]'), 'y')
        .replaceAll(RegExp('[\\u0111]'), 'd');
  }
}
