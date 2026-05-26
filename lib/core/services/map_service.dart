import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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

class MapService {
  static const _configChannel = MethodChannel('smart_room_iot_app/config');
  static const _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
  static String? _cachedNativeGoogleMapsApiKey;

  static Future<bool> hasGoogleMapsApiKey() async {
    return (await googleMapsApiKey()).isNotEmpty;
  }

  static Future<String> googleMapsApiKey() async {
    if (_googleMapsApiKey.isNotEmpty) return _googleMapsApiKey;
    if (_cachedNativeGoogleMapsApiKey != null) {
      return _cachedNativeGoogleMapsApiKey!;
    }

    try {
      final key = await _configChannel.invokeMethod<String>(
        'googleMapsApiKey',
      );
      _cachedNativeGoogleMapsApiKey = key?.trim() ?? '';
    } on PlatformException {
      _cachedNativeGoogleMapsApiKey = '';
    } on MissingPluginException {
      _cachedNativeGoogleMapsApiKey = '';
    }

    return _cachedNativeGoogleMapsApiKey!;
  }

  Future<MapLocationResult?> geocodeAddress(String address) async {
    final trimmedAddress = address.trim();
    final apiKey = await googleMapsApiKey();
    if (trimmedAddress.isEmpty || apiKey.isEmpty) return null;

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

    if (bestResult != null) return bestResult;
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
    final params = <String, String>{
      'address': query,
      'language': 'vi',
      'region': 'vn',
      'components': 'country:VN',
      'key': apiKey,
    };

    if (_isDaNangQuery(originalAddress)) {
      params['bounds'] = '15.75,107.8|16.35,108.55';
    }

    return Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      params,
    );
  }

  static List<String> _addressQueries(String address) {
    final normalized = _normalize(address);
    final queries = <String>[
      address,
      '$address, Viet Nam',
    ];

    if (_isDaNangQuery(address)) {
      queries.insert(0, '$address, Da Nang, Viet Nam');
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
    var score = 0;

    if (_isDaNangQuery(originalAddress)) {
      score += _isInDaNangArea(result.latitude, result.longitude) ? 1000 : -1000;
      if (normalizedAddress.contains('da nang')) score += 200;
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

  static bool _isDaNangQuery(String address) {
    final normalized = _normalize(address);
    return normalized.contains('da nang') ||
        normalized.contains('ngu hanh son') ||
        normalized.contains('ngu hanh');
  }

  static bool _isInDaNangArea(double latitude, double longitude) {
    return latitude >= 15.75 &&
        latitude <= 16.35 &&
        longitude >= 107.8 &&
        longitude <= 108.55;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(
          RegExp('[\\u00E0\\u00E1\\u1EA1\\u1EA3\\u00E3'
              '\\u00E2\\u1EA7\\u1EA5\\u1EAD\\u1EA9\\u1EAB'
              '\\u0103\\u1EB1\\u1EAF\\u1EB7\\u1EB3\\u1EB5]'),
          'a',
        )
        .replaceAll(
          RegExp('[\\u00E8\\u00E9\\u1EB9\\u1EBB\\u1EBD'
              '\\u00EA\\u1EC1\\u1EBF\\u1EC7\\u1EC3\\u1EC5]'),
          'e',
        )
        .replaceAll(
          RegExp('[\\u00EC\\u00ED\\u1ECB\\u1EC9\\u0129]'),
          'i',
        )
        .replaceAll(
          RegExp('[\\u00F2\\u00F3\\u1ECD\\u1ECF\\u00F5'
              '\\u00F4\\u1ED3\\u1ED1\\u1ED9\\u1ED5\\u1ED7'
              '\\u01A1\\u1EDD\\u1EDB\\u1EE3\\u1EDF\\u1EE1]'),
          'o',
        )
        .replaceAll(
          RegExp('[\\u00F9\\u00FA\\u1EE5\\u1EE7\\u0169'
              '\\u01B0\\u1EEB\\u1EE9\\u1EF1\\u1EED\\u1EEF]'),
          'u',
        )
        .replaceAll(
          RegExp('[\\u1EF3\\u00FD\\u1EF5\\u1EF7\\u1EF9]'),
          'y',
        )
        .replaceAll(RegExp('[\\u0111]'), 'd');
  }
}
