import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import 'admin_nav.dart';

class AdminDeviceListScreen extends StatefulWidget {
  const AdminDeviceListScreen({super.key});

  @override
  State<AdminDeviceListScreen> createState() => _AdminDeviceListScreenState();
}

class _AdminDeviceListScreenState extends State<AdminDeviceListScreen> {
  static const int _currentIndex = 2;
  bool _isSeeding = false;

  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _background = Color(0xFFF3F5F8);

  @override
  void initState() {
    super.initState();
    unawaited(_ensureDevices());
  }

  Future<void> _ensureDevices() async {
    if (_isSeeding) return;
    setState(() => _isSeeding = true);
    try {
      await AppFirestoreService.ensureDevices();
    } catch (_) {
      // Nếu rules chưa cho ghi, màn hình vẫn đọc dữ liệu đã có.
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 72,
        titleSpacing: 14,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFFFCCBC),
              child: Text(
                'A',
                style: TextStyle(
                  color: Color(0xFF5D4037),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IoT CHUNG CƯ - BẢNG ĐIỀU KHIỂN',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Admin Hoàng VL.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: AppFirestoreService.watchDevices(),
          builder: (context, snapshot) {
            final devices = (snapshot.data?.docs ?? const [])
                .map((doc) => _DeviceView.fromFirestore(doc.id, doc.data()))
                .toList();
            final buildingDevices =
                devices.where((device) => device.scope == 'building').toList();
            final roomDevices =
                devices.where((device) => device.scope == 'room').toList();
            final loading =
                snapshot.connectionState == ConnectionState.waiting ||
                    _isSeeding;

            return Column(
              children: [
                if (loading)
                  const LinearProgressIndicator(minHeight: 2)
                else
                  const SizedBox(height: 2),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DANH SÁCH THIẾT BỊ HỆ THỐNG',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _SectionHeader(title: 'THIẾT BỊ CHUNG TÒA NHÀ'),
                        const SizedBox(height: 8),
                        if (buildingDevices.isEmpty)
                          const _EmptyPanel(
                            text: 'Chưa có thiết bị chung trong Firestore.',
                          )
                        else
                          ...buildingDevices.map(
                            (device) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _DeviceCard(device: device),
                            ),
                          ),
                        const SizedBox(height: 8),
                        const _SectionHeader(title: 'QUẢN LÝ CĂN HỘ'),
                        const SizedBox(height: 8),
                        if (roomDevices.isEmpty)
                          const _EmptyPanel(
                            text:
                                'Chưa có thiết bị theo phòng. Hãy thêm document vào collection devices.',
                          )
                        else
                          ...roomDevices.map(
                            (device) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _DeviceCard(device: device),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => openAdminTab(
          context,
          currentIndex: _currentIndex,
          targetIndex: index,
        ),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang Chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Người Dùng'),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Thiết Bị'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Nhật Ký'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài Đặt'),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final _DeviceView device;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: device.iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(device.icon, color: device.iconColor, size: 23),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  device.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  device.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: device.warning ? Colors.deepOrange : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  device.usageLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: device.statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              device.statusLabel,
              style: TextStyle(
                fontSize: 11,
                color: device.statusColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
        const Icon(Icons.expand_less, size: 20, color: Colors.black87),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EF)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black54)),
    );
  }
}

class _DeviceView {
  const _DeviceView({
    required this.id,
    required this.title,
    required this.type,
    required this.scope,
    required this.status,
    required this.roomNumber,
    required this.usage,
  });

  final String id;
  final String title;
  final String type;
  final String scope;
  final String status;
  final int? roomNumber;
  final double usage;

  factory _DeviceView.fromFirestore(String id, Map<String, dynamic> data) {
    final rawRoomNumber = data['roomNumber'];
    final parsedRoomNumber = rawRoomNumber is int
        ? rawRoomNumber
        : int.tryParse(rawRoomNumber?.toString() ?? '');
    return _DeviceView(
      id: id,
      title: (data['name'] ?? 'Thiết bị').toString(),
      type: (data['type'] ?? 'device').toString(),
      scope: (data['scope'] ?? 'building').toString(),
      status: (data['status'] ?? 'offline').toString(),
      roomNumber: parsedRoomNumber,
      usage: (data['usage'] as num?)?.toDouble() ?? 0,
    );
  }

  IconData get icon {
    switch (type) {
      case 'water':
        return Icons.water_drop;
      case 'alarm':
        return Icons.local_fire_department;
      case 'light':
        return Icons.light;
      default:
        return scope == 'room' ? Icons.apartment : Icons.devices;
    }
  }

  Color get iconBackground {
    if (warning) return const Color(0xFFFFE2D8);
    return const Color(0xFFE7F0FA);
  }

  Color get iconColor {
    if (warning) return Colors.deepOrange;
    return const Color(0xFF1565C0);
  }

  bool get warning => status == 'warning' || status == 'offline';

  Color get statusColor {
    if (status == 'online') return const Color(0xFF149447);
    if (status == 'warning') return Colors.deepOrange;
    return Colors.redAccent;
  }

  String get statusLabel {
    switch (status) {
      case 'online':
        return 'Online';
      case 'warning':
        return 'Cảnh báo';
      default:
        return 'Offline';
    }
  }

  String get subtitle {
    if (scope == 'room' && roomNumber != null) {
      return 'Phòng ${roomNumber.toString().padLeft(3, '0')}';
    }
    return type == 'alarm' ? 'Bình thường' : 'Đang hoạt động';
  }

  String get usageLabel {
    if (scope == 'room') return 'Tiêu thụ: ${usage.toStringAsFixed(1)} kWh';
    return 'Phạm vi: Thiết bị chung tòa nhà';
  }
}
