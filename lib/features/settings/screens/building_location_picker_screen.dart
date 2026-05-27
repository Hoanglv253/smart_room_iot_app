import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/map_service.dart';

class BuildingLocationPickerScreen extends StatefulWidget {
  const BuildingLocationPickerScreen({
    required this.initialAddress,
    required this.initialLocation,
    super.key,
  });

  final String initialAddress;
  final Map<String, dynamic> initialLocation;

  @override
  State<BuildingLocationPickerScreen> createState() =>
      _BuildingLocationPickerScreenState();
}

class _BuildingLocationPickerScreenState
    extends State<BuildingLocationPickerScreen> {
  static const _defaultPosition = LatLng(10.7769, 106.7009);
  static const _daNangPosition = LatLng(16.0471, 108.2068);
  static const _nguHanhSonPosition = LatLng(16.0037, 108.2648);

  final _addressController = TextEditingController();
  final _mapService = MapService();

  GoogleMapController? _mapController;
  late LatLng _selectedPosition;
  String _formattedAddress = '';
  String _placeId = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();

    _addressController.text = widget.initialAddress.trim();
    _formattedAddress = _text(widget.initialLocation['formattedAddress'], '');
    _placeId = _text(widget.initialLocation['placeId'], '');

    final lat = _readDouble(widget.initialLocation['lat']);
    final lng = _readDouble(widget.initialLocation['lng']);
    _selectedPosition = lat != null && lng != null
        ? LatLng(lat, lng)
        : _suggestedPositionForAddress(widget.initialAddress);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _searchAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      _showSnack('Hay nhap dia chi de tim.');
      return;
    }

    final hasGoogleMapsApiKey = await MapService.hasGoogleMapsApiKey();
    if (!mounted) return;

    if (!hasGoogleMapsApiKey) {
      _showSnack(
        'Chua cau hinh GOOGLE_MAPS_API_KEY cho tim dia chi. Em van co the cham tren ban do de chon vi tri.',
      );
      return;
    }

    setState(() => _isSearching = true);

    MapLocationResult? result;
    try {
      result = await _mapService.geocodeAddress(address);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      if (_isGoogleApiConfigurationError(error)) {
        await _moveToSuggestedArea();
      }
      _showSnack(_formatSearchError(error));
      return;
    }

    setState(() => _isSearching = false);

    if (result == null) {
      _showSnack('Khong tim thay dia chi nay.');
      return;
    }

    final location = result;
    var target = LatLng(location.latitude, location.longitude);
    var formattedAddress = location.formattedAddress;
    var placeId = location.placeId;

    if (_expectsDaNang(address) && !_isInDaNangArea(target)) {
      target = _suggestedPositionForAddress(address);
      formattedAddress = address;
      placeId = '';
      _showSnack(
        'Google tra ve sai khu vuc, da dua ban do ve Da Nang. Hay cham dung vi tri toa nha roi luu.',
      );
    }

    setState(() {
      _selectedPosition = target;
      _formattedAddress = formattedAddress;
      _placeId = placeId;
      _addressController.text = location.address;
    });

    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 17),
      ),
    );
  }

  void _selectPosition(LatLng position) {
    setState(() {
      _selectedPosition = position;
      _placeId = '';
      if (_formattedAddress.isEmpty) {
        _formattedAddress = _addressController.text.trim();
      }
    });
  }

  Future<void> _moveToSuggestedArea() async {
    final target = _suggestedPositionForAddress(_addressController.text);
    setState(() {
      _selectedPosition = target;
      _placeId = '';
      if (_formattedAddress.trim().isEmpty) {
        _formattedAddress = _addressController.text.trim();
      }
    });

    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: target == _defaultPosition ? 12 : 15,
        ),
      ),
    );
  }

  void _saveSelection() {
    final address = _addressController.text.trim();
    Navigator.of(context).pop({
      'address': address,
      'formattedAddress': _formattedAddress.trim().isEmpty
          ? address
          : _formattedAddress.trim(),
      'lat': _selectedPosition.latitude,
      'lng': _selectedPosition.longitude,
      'placeId': _placeId,
      'source': 'manual_map_picker',
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatSearchError(Object error) {
    final message = error.toString();
    if (message.contains('REQUEST_DENIED') &&
        message.contains('not activated')) {
      return 'Chua bat Geocoding API tren Google Cloud nen chua tim duoc dia chi.';
    }

    if (message.contains('REQUEST_DENIED')) {
      return 'Google tu choi API key. Kiem tra Geocoding API va gioi han API key.';
    }

    return 'Khong tim duoc dia chi. Kiem tra Google Maps API key va mang.';
  }

  bool _isGoogleApiConfigurationError(Object error) {
    final message = error.toString();
    return message.contains('REQUEST_DENIED') ||
        message.contains('not activated');
  }

  @override
  Widget build(BuildContext context) {
    final marker = Marker(
      markerId: const MarkerId('building_location'),
      position: _selectedPosition,
      infoWindow: const InfoWindow(title: 'Vi tri toa nha'),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chon vi tri toa nha'),
        actions: [
          TextButton(
            onPressed: _saveSelection,
            child: const Text('Luu'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchAddress(),
                    decoration: const InputDecoration(
                      labelText: 'Tim dia chi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSearching ? null : _searchAddress,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  tooltip: 'Tim tren ban do',
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedPosition,
                zoom: _selectedPosition == _defaultPosition ? 12 : 17,
              ),
              markers: {marker},
              onMapCreated: (controller) {
                _mapController = controller;
                Future<void>.delayed(
                  const Duration(milliseconds: 350),
                  () {
                    if (!mounted) return;
                    controller.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: _selectedPosition,
                          zoom: _selectedPosition == _defaultPosition ? 12 : 17,
                        ),
                      ),
                    );
                  },
                );
              },
              onTap: _selectPosition,
              mapType: MapType.normal,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Da chon: ${_selectedPosition.latitude.toStringAsFixed(6)}, ${_selectedPosition.longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formattedAddress.trim().isEmpty
                        ? 'Cham vao ban do de dat dung vi tri toa nha.'
                        : _formattedAddress,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  TextButton.icon(
                    onPressed: _moveToSuggestedArea,
                    icon: const Icon(Icons.my_location_outlined),
                    label: const Text('Ve khu vuc theo dia chi'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saveSelection,
                    icon: const Icon(Icons.check),
                    label: const Text('Dung vi tri nay'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static LatLng _suggestedPositionForAddress(String address) {
    final normalized = _normalize(address);
    if (normalized.contains('ngu hanh son')) return _nguHanhSonPosition;
    if (normalized.contains('da nang')) return _daNangPosition;
    return _defaultPosition;
  }

  static bool _expectsDaNang(String address) {
    final normalized = _normalize(address);
    return normalized.contains('da nang') ||
        normalized.contains('ngu hanh son') ||
        normalized.contains('ngu hanh');
  }

  static bool _isInDaNangArea(LatLng position) {
    return position.latitude >= 15.75 &&
        position.latitude <= 16.35 &&
        position.longitude >= 107.8 &&
        position.longitude <= 108.55;
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

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
