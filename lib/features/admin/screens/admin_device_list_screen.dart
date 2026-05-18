import 'package:flutter/material.dart';

class AdminDeviceListScreen extends StatefulWidget {
  const AdminDeviceListScreen({super.key});

  @override
  State<AdminDeviceListScreen> createState() => _AdminDeviceListScreenState();
}

class _AdminDeviceListScreenState extends State<AdminDeviceListScreen> {
  bool _hallLightOn = true;
  int _currentIndex = 2;

  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _background = Color(0xFFF3F5F8);

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
        title: Row(
          children: [
            const CircleAvatar(
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
            const SizedBox(width: 10),
            const Expanded(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 21),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: Colors.white,
              size: 21,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
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
              const _BuildingDeviceCard(
                icon: Icons.water_drop,
                iconBackground: Color(0xFFDDEEFF),
                iconColor: _primaryBlue,
                title: 'Hệ thống Bơm Nước Tổng',
                leftStatus: 'Online',
                rightStatus: 'Đang hoạt động',
              ),
              const SizedBox(height: 8),
              const _BuildingDeviceCard(
                icon: Icons.local_fire_department,
                iconBackground: Color(0xFFFFE2D8),
                iconColor: Colors.redAccent,
                title: 'Hệ thống Báo Cháy Trung Tâm',
                leftStatus: 'Online',
                rightStatus: 'Bình thường',
              ),
              const SizedBox(height: 8),
              _BuildingDeviceCard(
                icon: Icons.light,
                iconBackground: const Color(0xFFE7F0FA),
                iconColor: _primaryBlue,
                title: 'Đèn Hành Lang (Khu A)',
                leftStatus: 'Online',
                trailing: Switch(
                  value: _hallLightOn,
                  activeThumbColor: _primaryBlue,
                  onChanged: (value) {
                    setState(() => _hallLightOn = value);
                  },
                ),
              ),
              const SizedBox(height: 14),
              const _SectionHeader(title: 'QUẢN LÝ CĂN HỘ'),
              const SizedBox(height: 8),
              const _ApartmentDeviceCard(
                icon: Icons.apartment,
                iconBackground: Color(0xFFE7F0FA),
                iconColor: _primaryBlue,
                room: 'Căn 101',
                safety: 'An toàn: Bình thường',
                esp: 'ESP32: Online',
                usage: 'Tiêu thụ: 25.5 kWh',
              ),
              const SizedBox(height: 8),
              const _ApartmentDeviceCard(
                icon: Icons.apartment,
                iconBackground: Color(0xFFFFE2D8),
                iconColor: Colors.deepOrange,
                room: 'Căn 102',
                safety: 'An toàn: Cảnh báo',
                esp: 'ESP32: Online',
                usage: 'Tiêu thụ: 18.2 kWh',
                warning: true,
              ),
              const SizedBox(height: 8),
              const _ApartmentDeviceCard(
                icon: Icons.apartment,
                iconBackground: Color(0xFFE7F0FA),
                iconColor: _primaryBlue,
                room: 'Căn 201 (VIP)',
                safety: 'An toàn: Bình thường',
                esp: 'ESP32: Online',
                usage: 'Tiêu thụ: 32.1 kWh',
              ),
              const SizedBox(height: 8),
              const _ApartmentDeviceCard(
                icon: Icons.apartment,
                iconBackground: Color(0xFFE7F0FA),
                iconColor: _primaryBlue,
                room: 'Căn 202',
                safety: 'An toàn: Bình thường',
                esp: 'ESP32: Online',
                usage: 'Tiêu thụ: 21.8 kWh',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pop();
            return;
          }
          setState(() => _currentIndex = index);
        },
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
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Người Dùng',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Thiết Bị'),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Nhật Ký',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài Đặt'),
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

class _BuildingDeviceCard extends StatelessWidget {
  const _BuildingDeviceCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.leftStatus,
    this.rightStatus,
    this.trailing,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String leftStatus;
  final String? rightStatus;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _DeviceShell(
      child: Row(
        children: [
          _DeviceIcon(
            icon: icon,
            backgroundColor: iconBackground,
            iconColor: iconColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      leftStatus,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF149447),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (rightStatus != null)
                      Text(
                        rightStatus!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _ApartmentDeviceCard extends StatelessWidget {
  const _ApartmentDeviceCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.room,
    required this.safety,
    required this.esp,
    required this.usage,
    this.warning = false,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String room;
  final String safety;
  final String esp;
  final String usage;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return _DeviceShell(
      child: Row(
        children: [
          _DeviceIcon(
            icon: icon,
            backgroundColor: iconBackground,
            iconColor: iconColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        room,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (warning) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.deepOrange,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  safety,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: warning ? Colors.deepOrange : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  esp,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
                Text(
                  usage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(54, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Xem chi tiết',
              style: TextStyle(fontSize: 10, color: Colors.black87),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black54, size: 18),
        ],
      ),
    );
  }
}

class _DeviceShell extends StatelessWidget {
  const _DeviceShell({required this.child});

  final Widget child;

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
      child: child,
    );
  }
}

class _DeviceIcon extends StatelessWidget {
  const _DeviceIcon({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: 23),
    );
  }
}
