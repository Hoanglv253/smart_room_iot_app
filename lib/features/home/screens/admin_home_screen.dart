import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../buildings/screens/admin_building_screen.dart';
import '../../buildings/screens/admin_user_management_screen.dart';
import '../../feed/screens/feed_screen.dart';
import '../../messages/screens/messages_screen.dart';
import '../../settings/screens/admin_settings_screen.dart';
import '../view_models/role_home_view_model.dart';
import '../widgets/role_home_shell.dart';

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

  static const _items = <RoleNavItem>[
    RoleNavItem(icon: Icons.dynamic_feed_outlined, label: 'Trang chủ'),
    RoleNavItem(icon: Icons.apartment_outlined, label: 'Tòa nhà'),
    RoleNavItem(icon: Icons.chat_bubble_outline, label: 'Tin nhắn'),
    RoleNavItem(icon: Icons.settings_outlined, label: 'Cài đặt'),
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
        return RoleHomeShell(
          user: widget.user,
          role: UserRole.admin,
          roleLabel: 'Admin',
          avatarText: 'AD',
          avatarColor: const Color(0xFFFFCCBC),
          avatarTextColor: const Color(0xFF5D4037),
          currentIndex: _viewModel.currentIndex,
          pages: pages,
          items: _items,
          onTapNav: _viewModel.selectIndex,
          onLogout: () => widget.onLogout(context),
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
