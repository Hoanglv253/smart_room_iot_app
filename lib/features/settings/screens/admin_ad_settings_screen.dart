import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';

class AdminAdSettingsScreen extends StatefulWidget {
  const AdminAdSettingsScreen({
    required this.user,
    required this.buildingId,
    super.key,
  });

  final User user;
  final String buildingId;

  @override
  State<AdminAdSettingsScreen> createState() => _AdminAdSettingsScreenState();
}

class _AdminAdSettingsScreenState extends State<AdminAdSettingsScreen> {
  bool _isSaving = false;

  Future<void> _publishAd() async {
    setState(() => _isSaving = true);

    try {
      await AppFirestoreService.buildings.doc(widget.buildingId).update({
        'adPublished': true,
        'adPublishedBy': widget.user.uid,
        'adUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Da day quang cao len trang chu.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Firestore chua cap quyen cap nhat quang cao toa nha.'
                : e.message ?? 'Khong luu duoc quang cao.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildingRef = AppFirestoreService.buildings.doc(widget.buildingId);

    return Scaffold(
      appBar: AppBar(title: const Text('Thiet lap quang cao')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: buildingRef.snapshots(),
        builder: (context, buildingSnapshot) {
          if (buildingSnapshot.hasError) {
            return const _AdEmptyState(
              icon: Icons.lock_outline,
              message: 'Khong tai duoc thong tin toa nha.',
            );
          }

          if (buildingSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (buildingSnapshot.data?.exists != true) {
            return const _AdEmptyState(
              icon: Icons.apartment_outlined,
              message: 'Hay luu thiet lap toa nha truoc khi tao quang cao.',
            );
          }

          final building = buildingSnapshot.data!.data() ?? {};

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: AppFirestoreService.buildingRooms(widget.buildingId)
                .orderBy('roomNumber')
                .snapshots(),
            builder: (context, roomSnapshot) {
              final rooms = roomSnapshot.data?.docs ?? [];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _BuildingPreviewCard(building: building),
                  const SizedBox(height: 16),
                  _RoomButtonSection(
                    isLoading:
                        roomSnapshot.connectionState == ConnectionState.waiting,
                    hasError: roomSnapshot.hasError,
                    rooms: rooms.map((doc) => doc.data()).toList(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _publishAd,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.campaign_outlined),
                    label: const Text('Luu va day len trang chu'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BuildingPreviewCard extends StatelessWidget {
  const _BuildingPreviewCard({required this.building});

  final Map<String, dynamic> building;

  @override
  Widget build(BuildContext context) {
    final name = _text(building['name'], 'Toa nha');
    final address = _text(building['address'], 'Chua co dia chi');
    final description = _text(building['description'], 'Chua co mo ta');
    final phone = _text(building['phone'], 'Chua co so dien thoai');
    final email = _text(building['email'], 'Chua co email');
    final adminName = _text(building['adminName'], 'Admin');
    final amenities = _amenitiesText(building['amenities']);
    final servicePrices = _servicePricesText(building);
    final rules = _text(building['rulesText'], 'Chua co noi quy');
    final totalRooms = _readInt(building['totalRooms']);
    final floorCount = _readInt(building['floorCount']);
    final defaultRent = _readInt(building['defaultRent']);
    final adPublished = building['adPublished'] == true;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.campaign_outlined, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Noi dung quang cao',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text(adPublished ? 'Dang hien thi' : 'Chua dang'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AdInfoRow(label: 'Ten toa nha', value: name),
            _AdInfoRow(label: 'Dia chi', value: address),
            _AdInfoRow(label: 'Mo ta', value: description),
            _AdInfoRow(label: 'Admin', value: adminName),
            _AdInfoRow(label: 'Lien he', value: '$phone - $email'),
            _AdInfoRow(
              label: 'Tien ich',
              value: amenities.isEmpty ? 'Chua thiet lap' : amenities,
            ),
            _AdInfoRow(
              label: 'Phi dich vu',
              value: servicePrices.isEmpty ? 'Chua thiet lap' : servicePrices,
            ),
            _AdInfoRow(
              label: 'Quy mo',
              value: [
                if (floorCount > 0) '$floorCount tang',
                if (totalRooms > 0) '$totalRooms phong',
              ].isEmpty
                  ? 'Chua thiet lap'
                  : [
                      if (floorCount > 0) '$floorCount tang',
                      if (totalRooms > 0) '$totalRooms phong',
                    ].join(' - '),
            ),
            _AdInfoRow(
              label: 'Gia mac dinh',
              value: defaultRent > 0 ? '$defaultRent VND/thang' : 'Chua thiet lap',
            ),
            _AdInfoRow(label: 'Noi quy', value: rules),
          ],
        ),
      ),
    );
  }

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _amenitiesText(Object? value) {
    if (value is! Map) return '';

    final labels = <String>[];
    if (value['wifi'] == true) labels.add('Wifi');
    if (value['elevator'] == true) labels.add('Thang may');
    if (value['camera'] == true) labels.add('Camera');
    if (value['parking'] == true) labels.add('Cho de xe');
    if (value['laundry'] == true) labels.add('May giat');
    if (value['security'] == true) labels.add('Bao ve');
    return labels.join(', ');
  }

  static String _servicePricesText(Map<String, dynamic> building) {
    final items = <String>[];
    void addPrice(String label, Object? value) {
      final amount = _readInt(value);
      if (amount > 0) items.add('$label $amount VND');
    }

    addPrice('Dien', building['electricityPrice']);
    addPrice('Nuoc', building['waterPrice']);
    addPrice('Dich vu', building['serviceFee']);
    addPrice('Internet', building['internetFee']);
    addPrice('Gui xe', building['parkingFee']);
    return items.join(', ');
  }
}

class _RoomButtonSection extends StatelessWidget {
  const _RoomButtonSection({
    required this.isLoading,
    required this.hasError,
    required this.rooms,
  });

  final bool isLoading;
  final bool hasError;
  final List<Map<String, dynamic>> rooms;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trang thai tat ca phong',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const LinearProgressIndicator(minHeight: 2)
            else if (hasError)
              const Text('Khong tai duoc danh sach phong.')
            else if (rooms.isEmpty)
              const Text('Chua co phong nao de hien thi.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rooms.map((room) {
                  final name = (room['name'] ?? 'Phong').toString();
                  final status = _statusFromRoom(room);
                  final color = _statusColor(status);

                  return OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color.withValues(alpha: 0.45)),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text('$name - ${_statusLabel(status)}'),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  static String _statusFromRoom(Map<String, dynamic> room) {
    final tenantId = (room['tenantId'] ?? '').toString();
    final tenantName = (room['tenantName'] ?? '').toString();
    if (tenantId.isNotEmpty || tenantName.isNotEmpty) return 'occupied';
    final status = (room['status'] ?? 'available').toString();
    if (status == 'occupied' || status == 'maintenance' || status == 'reserved') {
      return status;
    }
    return 'available';
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'occupied' => 'Da thue',
      'maintenance' => 'Bao tri',
      'reserved' => 'Da dat',
      _ => 'Trong',
    };
  }

  static Color _statusColor(String status) {
    return switch (status) {
      'occupied' => Colors.blueAccent,
      'maintenance' => Colors.orange,
      'reserved' => Colors.purple,
      _ => Colors.green,
    };
  }
}

class _AdInfoRow extends StatelessWidget {
  const _AdInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdEmptyState extends StatelessWidget {
  const _AdEmptyState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
