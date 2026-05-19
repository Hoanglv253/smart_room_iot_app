import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../notifications/screens/notification_center_screen.dart';

class RoomControlScreen extends StatefulWidget {
  const RoomControlScreen({super.key});

  @override
  State<RoomControlScreen> createState() => _RoomControlScreenState();
}

class _RoomControlScreenState extends State<RoomControlScreen> {
  bool _lightOn = true;
  bool _fanOn = true;
  bool _acOn = true;
  int _fanSpeed = 2;
  int _currentIndex = 0;

  static const Color _primaryBlue = Color(0xFF0D5FA8);
  static const Color _deepBlue = Color(0xFF0A4E91);
  static const Color _softBackground = Color(0xFFF2F5F8);
  static const Color _lineColor = Color(0xFFE1E7EF);
  final AuthService _authService = AuthService();

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBackground,
      appBar: AppBar(
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 10,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD7A6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.4),
              ),
              child: const _TenantAvatarBadge(),
            ),
            const SizedBox(width: 9),
            const Expanded(child: _TenantAppBarTitle()),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
          child: Column(
            children: [
              const _TenantHeaderLine(),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DashboardCard(
                      height: 156,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardTitle(
                            title: 'Môi Trường Phòng:',
                            onMore: () {},
                          ),
                          const SizedBox(height: 4),
                          const Expanded(child: _EnvironmentChart()),
                          const SizedBox(height: 3),
                          const _MetricLine(
                            color: _deepBlue,
                            text: 'Nhiệt độ (26°C)',
                          ),
                          const _MetricLine(
                            color: Color(0xFF4AA3A7),
                            text: 'Độ ẩm (55%)',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _TenantControlledDeviceCard(
                      height: 156,
                      deviceName: 'Đèn Chính',
                      isOn: _lightOn,
                      status: 'Đang bật',
                      icon: Icons.lightbulb,
                      onChanged: (value) => setState(() => _lightOn = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DashboardCard(
                      height: 154,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _TenantCardTitle(deviceName: 'Quạt Trần'),
                          const SizedBox(height: 8),
                          _SegmentSwitch(
                            value: _fanOn,
                            onChanged: (value) =>
                                setState(() => _fanOn = value),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Tốc độ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(3, (index) {
                              final speed = index + 1;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: index == 2 ? 0 : 5,
                                  ),
                                  child: _SpeedButton(
                                    label: '$speed',
                                    selected: _fanSpeed == speed,
                                    onTap: () =>
                                        setState(() => _fanSpeed = speed),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const Spacer(),
                          Text(
                            _fanOn
                                ? 'Đang bật - Tốc độ $_fanSpeed'
                                : 'Đang tắt',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _DashboardCard(
                      height: 154,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _TenantCardTitle(deviceName: 'Máy Lạnh'),
                          const SizedBox(height: 8),
                          _SegmentSwitch(
                            value: _acOn,
                            onChanged: (value) => setState(() => _acOn = value),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Expanded(
                                child: Text(
                                  'Mode',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                'Temp',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Expanded(
                                child: Text(
                                  'Cool/Fan/Heat',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                              Text(
                                '24°C',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            _acOn ? 'Đang bật - 24°C Cool' : 'Đang tắt',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              const _TenantBillSummary(),
              const SizedBox(height: 9),
              const _DashboardCard(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(2, 2, 2, 0),
                  child: _ActivityList(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationCenterScreen(
                  currentRole: 'user',
                  title: 'Thông Báo Người Thuê',
                  canSendReport: true,
                ),
              ),
            );
            return;
          }
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const _TenantDevicesScreen(),
              ),
            );
            return;
          }
          if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const _TenantBillDetailScreen(),
              ),
            );
            return;
          }
          if (index == 4) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => _TenantSettingsScreen(
                  onLogout: _handleLogout,
                ),
              ),
            );
            return;
          }
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: Colors.black54,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 10.5),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang Chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Thiết Bị'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Hóa Đơn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông Báo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài Đặt'),
        ],
      ),
    );
  }
}

class _TenantDashboardData {
  const _TenantDashboardData({
    required this.name,
    required this.email,
    required this.roomNumber,
  });

  final String name;
  final String email;
  final int? roomNumber;

  factory _TenantDashboardData.fromMap(Map<String, dynamic>? data) {
    final user = FirebaseAuth.instance.currentUser;
    final email = (data?['email'] ?? user?.email ?? '').toString();
    final rawRoomNumber = data?['roomNumber'];
    final parsedRoomNumber = rawRoomNumber is int
        ? rawRoomNumber
        : int.tryParse(rawRoomNumber?.toString() ?? '');

    return _TenantDashboardData(
      name: (data?['name'] ?? data?['displayName'] ?? user?.displayName ?? email)
          .toString(),
      email: email,
      roomNumber: parsedRoomNumber,
    );
  }

  String get initials {
    final source = name.trim().isNotEmpty ? name.trim() : email.trim();
    if (source.isEmpty) return 'U';
    return source.substring(0, 1).toUpperCase();
  }

  String get roomBadge {
    if (roomNumber == null) return '---';
    return 'P${roomNumber.toString().padLeft(3, '0')}';
  }

  String get roomName {
    if (roomNumber == null) return 'Chưa gán phòng';
    return AppFirestoreService.roomName(roomNumber!);
  }

  String get headerLine => 'Người Thuê: $name ($roomName)';
}

class _TenantInfoBuilder extends StatelessWidget {
  const _TenantInfoBuilder({required this.builder});

  final Widget Function(BuildContext context, _TenantDashboardData tenant)
      builder;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return builder(context, _TenantDashboardData.fromMap(null));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: AppFirestoreService.users.doc(uid).snapshots(),
      builder: (context, snapshot) {
        return builder(
          context,
          _TenantDashboardData.fromMap(snapshot.data?.data()),
        );
      },
    );
  }
}

class _TenantAvatarBadge extends StatelessWidget {
  const _TenantAvatarBadge();

  @override
  Widget build(BuildContext context) {
    return _TenantInfoBuilder(
      builder: (context, tenant) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tenant.initials,
              style: const TextStyle(
                color: Color(0xFF4C3A24),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 0.92,
              ),
            ),
            Text(
              tenant.roomBadge,
              style: const TextStyle(
                color: Color(0xFF4C3A24),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TenantAppBarTitle extends StatelessWidget {
  const _TenantAppBarTitle();

  @override
  Widget build(BuildContext context) {
    return _TenantInfoBuilder(
      builder: (context, tenant) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'IoT CHUNG CƯ - BẢNG ĐIỀU KHIỂN NGƯỜI THUÊ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tenant.headerLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.2, color: Colors.white70),
            ),
          ],
        );
      },
    );
  }
}

class _TenantHeaderLine extends StatelessWidget {
  const _TenantHeaderLine();

  @override
  Widget build(BuildContext context) {
    return _TenantInfoBuilder(
      builder: (context, tenant) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            tenant.headerLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        );
      },
    );
  }
}

class _TenantCardTitle extends StatelessWidget {
  const _TenantCardTitle({required this.deviceName});

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    return _TenantInfoBuilder(
      builder: (context, tenant) {
        return _CardTitle(title: '$deviceName (${tenant.roomBadge})');
      },
    );
  }
}

class _TenantControlledDeviceCard extends StatelessWidget {
  const _TenantControlledDeviceCard({
    required this.deviceName,
    required this.isOn,
    required this.status,
    required this.icon,
    required this.onChanged,
    this.height,
  });

  final String deviceName;
  final bool isOn;
  final String status;
  final IconData icon;
  final ValueChanged<bool> onChanged;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return _TenantInfoBuilder(
      builder: (context, tenant) {
        return _DeviceCard(
          height: height,
          title: '$deviceName (${tenant.roomBadge})',
          isOn: isOn,
          status: tenant.roomNumber == null ? 'Chưa gán phòng' : status,
          icon: icon,
          onChanged: tenant.roomNumber == null ? (_) {} : onChanged,
        );
      },
    );
  }
}

class _TenantBillSummary extends StatelessWidget {
  const _TenantBillSummary();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const _TenantBillFallback();

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: AppFirestoreService.users.doc(uid).get(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data();
        final rawRoomNumber = userData?['roomNumber'];
        final roomNumber = rawRoomNumber is int
            ? rawRoomNumber
            : int.tryParse(rawRoomNumber?.toString() ?? '');

        if (roomNumber == null) return const _TenantBillFallback();

        final billDocId = AppFirestoreService.billId(
          roomNumber,
          AppFirestoreService.currentMonthKey(),
        );

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: AppFirestoreService.bills.doc(billDocId).snapshots(),
          builder: (context, billSnapshot) {
            final data = billSnapshot.data?.data();
            final bill = data == null
                ? BillRecord.sampleForRoom(
                    roomNumber,
                    AppFirestoreService.currentMonthKey(),
                  )
                : BillRecord.fromFirestore(billDocId, data);

            return Row(
              children: [
                const Expanded(
                  child: _DashboardCard(
                    height: 58,
                    child: Center(
                      child: Text(
                        'Tiêu thụ điện T5',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _DashboardCard(
                    height: 58,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${bill.electricKwh.toStringAsFixed(1)} kWh',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Hóa đơn: ${_formatTenantMoney(bill.totalAmount)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1A7F3F),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TenantBillFallback extends StatelessWidget {
  const _TenantBillFallback();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _DashboardCard(
            height: 58,
            child: Center(
              child: Text(
                'Tiêu thụ điện T5',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        SizedBox(width: 9),
        Expanded(
          child: _DashboardCard(
            height: 58,
            child: Center(
              child: Text(
                'Chưa gán phòng',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _formatTenantMoney(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return '${buffer.toString()} đ';
}

class _TenantBillDetailScreen extends StatelessWidget {
  const _TenantBillDetailScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      appBar: AppBar(
        backgroundColor: _RoomControlScreenState._primaryBlue,
        foregroundColor: Colors.white,
        title: const Text('Hóa Đơn Người Thuê'),
      ),
      body: _TenantInfoBuilder(
        builder: (context, tenant) {
          final roomNumber = tenant.roomNumber;
          if (roomNumber == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Tài khoản của bạn chưa được gán phòng. Vui lòng liên hệ admin hoặc quản lý.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            );
          }

          final billDocId = AppFirestoreService.billId(
            roomNumber,
            AppFirestoreService.currentMonthKey(),
          );

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: AppFirestoreService.bills.doc(billDocId).snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              final bill = data == null
                  ? BillRecord.sampleForRoom(
                      roomNumber,
                      AppFirestoreService.currentMonthKey(),
                    )
                  : BillRecord.fromFirestore(billDocId, data);

              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _TenantBillLine(
                    icon: Icons.meeting_room,
                    title: tenant.roomName,
                    subtitle: 'Tháng ${bill.monthKey}',
                    amount: bill.roomAmount,
                  ),
                  _TenantBillLine(
                    icon: Icons.electric_bolt,
                    title: 'Tiền điện',
                    subtitle: '${bill.electricKwh.toStringAsFixed(1)} kWh',
                    amount: bill.electricAmount,
                  ),
                  _TenantBillLine(
                    icon: Icons.water_drop,
                    title: 'Tiền nước',
                    subtitle: '${bill.waterM3.toStringAsFixed(1)} m3',
                    amount: bill.waterAmount,
                  ),
                  const SizedBox(height: 8),
                  _DashboardCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: _RoomControlScreenState._primaryBlue,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Tổng thanh toán',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          _formatTenantMoney(bill.totalAmount),
                          style: const TextStyle(
                            color: _RoomControlScreenState._primaryBlue,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
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

class _TenantDevicesScreen extends StatelessWidget {
  const _TenantDevicesScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      appBar: AppBar(
        backgroundColor: _RoomControlScreenState._primaryBlue,
        foregroundColor: Colors.white,
        title: const Text('Thiết Bị Người Thuê'),
      ),
      body: _TenantInfoBuilder(
        builder: (context, tenant) {
          final roomNumber = tenant.roomNumber;
          if (roomNumber == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Tài khoản của bạn chưa được gán phòng nên chưa có thiết bị để điều khiển.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: AppFirestoreService.devices
                .where('roomNumber', isEqualTo: roomNumber)
                .snapshots(),
            builder: (context, snapshot) {
              final devices = snapshot.data?.docs ??
                  const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _DashboardCard(
                    child: Text(
                      tenant.roomName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (devices.isEmpty) ...[
                    const _TenantDeviceInfoTile(
                      icon: Icons.lightbulb,
                      title: 'Đèn Chính',
                      subtitle: 'Thiết bị đang dùng dữ liệu điều khiển tại trang chủ',
                    ),
                    const _TenantDeviceInfoTile(
                      icon: Icons.air,
                      title: 'Quạt Trần',
                      subtitle: 'Thiết bị đang dùng dữ liệu điều khiển tại trang chủ',
                    ),
                    const _TenantDeviceInfoTile(
                      icon: Icons.ac_unit,
                      title: 'Máy Lạnh',
                      subtitle: 'Thiết bị đang dùng dữ liệu điều khiển tại trang chủ',
                    ),
                  ] else
                    ...devices.map((doc) {
                      final data = doc.data();
                      final name = (data['name'] ?? 'Thiết bị').toString();
                      final status = (data['status'] ?? 'offline').toString();
                      return _TenantDeviceInfoTile(
                        icon: Icons.devices,
                        title: name,
                        subtitle: status == 'online' ? 'Online' : 'Offline',
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TenantDeviceInfoTile extends StatelessWidget {
  const _TenantDeviceInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _DashboardCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  _RoomControlScreenState._primaryBlue.withValues(alpha: 0.12),
              child: Icon(icon, color: _RoomControlScreenState._primaryBlue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenantBillLine extends StatelessWidget {
  const _TenantBillLine({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _DashboardCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  _RoomControlScreenState._primaryBlue.withValues(alpha: 0.12),
              child: Icon(icon, color: _RoomControlScreenState._primaryBlue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Text(
              _formatTenantMoney(amount),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenantSettingsScreen extends StatelessWidget {
  const _TenantSettingsScreen({
    required this.onLogout,
  });

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      appBar: AppBar(
        backgroundColor: _RoomControlScreenState._primaryBlue,
        foregroundColor: Colors.white,
        title: const Text('Cài Đặt Người Thuê'),
      ),
      body: _TenantInfoBuilder(
        builder: (context, tenant) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _TenantSettingTile(
                icon: Icons.person,
                title: 'Họ tên',
                value: tenant.name,
              ),
              _TenantSettingTile(
                icon: Icons.email,
                title: 'Email',
                value: tenant.email.isEmpty ? 'Chưa có email' : tenant.email,
              ),
              _TenantSettingTile(
                icon: Icons.meeting_room,
                title: 'Phòng đang thuê',
                value: tenant.roomName,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await onLogout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TenantSettingTile extends StatelessWidget {
  const _TenantSettingTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _DashboardCard(
        child: Row(
          children: [
            Icon(icon, color: _RoomControlScreenState._primaryBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child, this.height});

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _RoomControlScreenState._lineColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title, this.onMore});

  final String title;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onMore,
          child: const Icon(Icons.more_vert, size: 18, color: Colors.black54),
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.title,
    required this.isOn,
    required this.status,
    required this.icon,
    required this.onChanged,
    this.height,
  });

  final String title;
  final bool isOn;
  final String status;
  final IconData icon;
  final ValueChanged<bool> onChanged;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      height: height,
      child: Column(
        children: [
          _CardTitle(title: title),
          const SizedBox(height: 8),
          _SegmentSwitch(value: isOn, onChanged: onChanged),
          const SizedBox(height: 8),
          Expanded(
            child: Icon(
              icon,
              size: 42,
              color: isOn
                  ? _RoomControlScreenState._primaryBlue
                  : Colors.black38,
            ),
          ),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SegmentSwitch extends StatelessWidget {
  const _SegmentSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF9EADBA)),
        color: const Color(0xFFEAF0F6),
      ),
      child: Row(
        children: [
          _SwitchHalf(
            label: 'ON',
            selected: value,
            onTap: () => onChanged(true),
          ),
          _SwitchHalf(
            label: 'OFF',
            selected: !value,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _SwitchHalf extends StatelessWidget {
  const _SwitchHalf({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? _RoomControlScreenState._primaryBlue
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: selected
              ? _RoomControlScreenState._primaryBlue
              : const Color(0xFFE5E9EF),
          foregroundColor: selected ? Colors.white : Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          elevation: selected ? 1 : 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _EnvironmentChart extends StatelessWidget {
  const _EnvironmentChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _EnvironmentChartPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _EnvironmentChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFFD6DEE8)
      ..strokeWidth = 1;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    const labels = ['30', '26', '22'];
    const leftGap = 20.0;
    final chartWidth = size.width - leftGap;
    final rowHeight = size.height / 2.8;

    for (var i = 0; i < 3; i++) {
      final y = 8 + (i * rowHeight);
      canvas.drawLine(Offset(leftGap, y), Offset(size.width, y), axisPaint);
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(fontSize: 9, color: Colors.black87),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    final bluePoints = [
      const Offset(0.04, 0.66),
      const Offset(0.18, 0.38),
      const Offset(0.34, 0.58),
      const Offset(0.50, 0.30),
      const Offset(0.70, 0.48),
      const Offset(0.94, 0.34),
    ];
    final tealPoints = [
      const Offset(0.02, 0.42),
      const Offset(0.20, 0.68),
      const Offset(0.40, 0.52),
      const Offset(0.56, 0.58),
      const Offset(0.72, 0.42),
      const Offset(0.96, 0.54),
    ];

    _drawLine(
      canvas,
      size,
      chartWidth,
      leftGap,
      bluePoints,
      _RoomControlScreenState._deepBlue,
    );
    _drawLine(
      canvas,
      size,
      chartWidth,
      leftGap,
      tealPoints,
      const Color(0xFF4AA3A7),
    );

    textPainter.text = const TextSpan(
      text: '12:00',
      style: TextStyle(fontSize: 9, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(leftGap + chartWidth * 0.45, size.height - 12),
    );
    textPainter.text = const TextSpan(
      text: '10:30',
      style: TextStyle(fontSize: 9, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 28, size.height - 12));
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    double chartWidth,
    double leftGap,
    List<Offset> points,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final point = Offset(
        leftGap + points[i].dx * chartWidth,
        8 + points[i].dy * (size.height - 24),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AppFirestoreService.notifications
          .where('targetRoles', arrayContains: 'user')
          .snapshots(),
      builder: (context, snapshot) {
        final items = (snapshot.data?.docs ??
                const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
            .map((doc) => _TenantActivity.fromFirestore(doc.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final visibleItems = items.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hoạt Động Gần Đây',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (visibleItems.isEmpty)
              const _ActivityItem(
                text: 'Chưa có thông báo mới',
                time: '--:--',
              )
            else
              ...visibleItems.map(
                (item) => _ActivityItem(
                  text: item.title,
                  time: item.timeLabel,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TenantActivity {
  const _TenantActivity({
    required this.message,
    required this.senderRole,
    required this.createdAt,
  });

  final String message;
  final String senderRole;
  final DateTime createdAt;

  factory _TenantActivity.fromFirestore(Map<String, dynamic> data) {
    final timestamp = data['createdAt'];
    return _TenantActivity(
      message: (data['message'] ?? '').toString(),
      senderRole: (data['senderRole'] ?? '').toString(),
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String get title {
    final prefix = senderRole == 'manager'
        ? 'Quản lý'
        : senderRole == 'admin'
            ? 'Admin'
            : 'Thông báo';
    return '$prefix: $message';
  }

  String get timeLabel {
    if (createdAt.millisecondsSinceEpoch == 0) return 'Mới';
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.text, required this.time});

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: _RoomControlScreenState._primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

