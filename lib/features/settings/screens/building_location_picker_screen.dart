import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  final _addressController = TextEditingController();

  GoogleMapController? _mapController;
  late LatLng _selectedPosition;
  String _formattedAddress = '';
  bool _isLocating = false;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();

    _addressController.text = widget.initialAddress.trim();
    _formattedAddress = _text(widget.initialLocation['formattedAddress'], '');

    final lat = _readDouble(widget.initialLocation['lat']);
    final lng = _readDouble(widget.initialLocation['lng']);
    _selectedPosition = lat != null && lng != null
        ? LatLng(lat, lng)
        : _defaultPosition;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _moveToCurrentLocation({
    bool requestPermission = true,
    bool showError = true,
  }) async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showError) {
          _showSnack('Hay bat dich vu vi tri tren thiet bi.');
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      final denied = permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever;
      if (denied) {
        if (showError) {
          _showSnack('Ban chua cap quyen vi tri cho ung dung.');
        }
        if (mounted) {
          setState(() => _hasLocationPermission = false);
        }
        return;
      }

      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final target = LatLng(current.latitude, current.longitude);
      final locationText = await _addressFromCoordinates(
        target.latitude,
        target.longitude,
      );
      if (!mounted) return;

      setState(() {
        _selectedPosition = target;
        _hasLocationPermission = true;
        _addressController.text = locationText;
        _formattedAddress = locationText;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: 17,
          ),
        ),
      );
    } catch (_) {
      if (showError) {
        _showSnack('Khong lay duoc vi tri hien tai.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _selectPosition(LatLng position) {
    setState(() {
      _selectedPosition = position;
      if (_formattedAddress.trim().isEmpty) {
        _formattedAddress = _addressController.text.trim();
      }
    });
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
      'placeId': '',
      'source': 'manual_map_picker',
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          TextButton(onPressed: _saveSelection, child: const Text('Luu')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Dia chi toa nha',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home_outlined),
              ),
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
                Future<void>.delayed(const Duration(milliseconds: 350), () async {
                  if (!mounted) return;
                  await controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: _selectedPosition,
                        zoom: _selectedPosition == _defaultPosition ? 12 : 17,
                      ),
                    ),
                  );
                  await _moveToCurrentLocation(showError: false);
                });
              },
              onTap: _selectPosition,
              mapType: MapType.normal,
              myLocationEnabled: _hasLocationPermission,
              myLocationButtonEnabled: _hasLocationPermission,
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
                    onPressed: _isLocating ? null : _moveToCurrentLocation,
                    icon: _isLocating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_outlined),
                    label: const Text('Lay vi tri hien tai'),
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

  Future<String> _addressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String?>[
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ]
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList();

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (_) {}

    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
