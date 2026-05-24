import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../buildings/screens/admin_building_screen.dart';
import '../../buildings/screens/admin_user_management_screen.dart';
import '../../feed/screens/feed_screen.dart';
import '../../messages/screens/messages_screen.dart';
import '../../settings/screens/admin_settings_screen.dart';
import '../view_models/role_home_view_model.dart';
import '../widgets/role_header.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({
    required this.user,
    required this.onLogout,
    super.key,
  });

  final User user;
  final Future<void> Function(BuildContext context) onLogout;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _viewModel = RoleHomeViewModel();

  static const _items = <_AdminNavItem>[
    _AdminNavItem(icon: Icons.home_outlined, label: 'Trang chủ'),
    _AdminNavItem(icon: Icons.apartment_outlined, label: 'Tòa nhà của tôi'),
    _AdminNavItem(icon: Icons.chat_bubble_outline, label: 'Tin nhắn'),
    _AdminNavItem(icon: Icons.settings_outlined, label: 'Cài đặt'),
  ];

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      FeedScreen(user: widget.user, role: UserRole.admin),
      AdminBuildingScreen(
        user: widget.user,
        onOpenUserManagement: _openUserManagement,
      ),
      MessagesScreen(user: widget.user),
      AdminSettingsScreen(user: widget.user),
    ];

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            toolbarHeight: 72,
            titleSpacing: 14,
            title: RoleHeader(
              user: widget.user,
              roleLabel: 'ADMIN',
              avatarText: 'AD',
              avatarColor: const Color(0xFFFFCCBC),
              avatarTextColor: const Color(0xFF5D4037),
            ),
            actions: [
              IconButton(
                tooltip: 'Đăng xuất',
                icon: const Icon(Icons.logout),
                onPressed: () => widget.onLogout(context),
              ),
            ],
          ),
          body: pages[_viewModel.currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _viewModel.currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.grey,
            onTap: _viewModel.selectIndex,
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
      },
    );
  }

  void _openUserManagement(String buildingId, String buildingName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminUserManagementScreen(
          buildingId: buildingId,
          buildingName: buildingName,
        ),
      ),
    );
  }
}

class _AdminNavItem {
  const _AdminNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
