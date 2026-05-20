import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../buildings/screens/tenant_room_screen.dart';
import '../../feed/screens/feed_screen.dart';
import '../../messages/screens/messages_screen.dart';
import '../../settings/screens/basic_settings_screen.dart';
import '../widgets/role_header.dart';

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({
    required this.user,
    required this.role,
    required this.onLogout,
    super.key,
  });

  final User user;
  final String role;
  final Future<void> Function(BuildContext context) onLogout;

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  int _currentIndex = 0;

  static const _items = <_TenantNavItem>[
    _TenantNavItem(icon: Icons.home_outlined, label: 'Trang chủ'),
    _TenantNavItem(icon: Icons.meeting_room_outlined, label: 'Phòng của tôi'),
    _TenantNavItem(icon: Icons.chat_bubble_outline, label: 'Tin nhắn'),
    _TenantNavItem(icon: Icons.settings_outlined, label: 'Cài đặt'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      FeedScreen(user: widget.user, role: UserRole.user),
      TenantRoomScreen(user: widget.user),
      MessagesScreen(user: widget.user),
      BasicSettingsScreen(user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        titleSpacing: 14,
        title: RoleHeader(
          user: widget.user,
          roleLabel: 'NGƯỜI DÙNG',
          avatarText: 'ND',
          avatarColor: const Color(0xFFBBDEFB),
          avatarTextColor: const Color(0xFF0D47A1),
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => widget.onLogout(context),
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _items
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TenantNavItem {
  const _TenantNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
