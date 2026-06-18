import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/map_service.dart';

class BuildingMapPreview extends StatelessWidget {
  const BuildingMapPreview({
    required this.building,
    this.title = 'Vị trí tòa nhà',
    super.key,
  });

  final Map<String, dynamic> building;
  final String title;

  @override
  Widget build(BuildContext context) {
    final location = _readMap(building['location']);
    final lat = _readDouble(location['lat']);
    final lng = _readDouble(location['lng']);
    final address = _address(location, building);
    final hasLatLng = lat != null && lng != null;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map_outlined, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (hasLatLng)
              _GoogleMapBox(
                latitude: lat,
                longitude: lng,
                title: _text(building['name'], 'Tòa nhà'),
              )
            else
              _MapFallbackBox(
                hasAddress: address.isNotEmpty,
              ),
            const SizedBox(height: 10),
            if (address.isNotEmpty)
              Text(address, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: MapService.canOpenDirections(building)
                    ? () => _openDirections(context)
                    : null,
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Chỉ đường'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    final opened = await MapService.openDirectionsForBuilding(building);
    if (!context.mounted || opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không mở được Google Maps.')),
    );
  }

  static String _address(
    Map<String, dynamic> location,
    Map<String, dynamic> building,
  ) {
    final formattedAddress = _text(location['formattedAddress'], '');
    if (formattedAddress.isNotEmpty) return formattedAddress;

    final locationAddress = _text(location['address'], '');
    if (locationAddress.isNotEmpty) return locationAddress;

    return _text(building['address'], '');
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

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

class _GoogleMapBox extends StatelessWidget {
  const _GoogleMapBox({
    required this.latitude,
    required this.longitude,
    required this.title,
  });

  final double latitude;
  final double longitude;
  final String title;

  @override
  Widget build(BuildContext context) {
    final target = LatLng(latitude, longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: target,
            zoom: 16,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('building'),
              position: target,
              infoWindow: InfoWindow(title: title),
            ),
          },
          liteModeEnabled: true,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          rotateGesturesEnabled: false,
          scrollGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomGesturesEnabled: false,
        ),
      ),
    );
  }
}

class _MapFallbackBox extends StatelessWidget {
  const _MapFallbackBox({
    required this.hasAddress,
  });

  final bool hasAddress;

  @override
  Widget build(BuildContext context) {
    final message = !hasAddress
        ? 'Chưa có Địa chỉ tòa nhà.'
        : 'Chưa có tọa độ. Admin có thể vào Cài đặt và chọn vị trí trên bản đồ.';

    return Container(
      height: 150,
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, color: Color(0xFF2563EB), size: 34),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
