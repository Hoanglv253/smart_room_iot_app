import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../buildings/screens/manager_building_screen.dart';
import '../../feed/screens/feed_screen.dart';
import '../../messages/screens/messages_screen.dart';
import '../../settings/screens/basic_settings_screen.dart';
import '../view_models/role_home_view_model.dart';
import '../widgets/role_home_shell.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({
    required this.user,
    required this.onLogout,
    super.key,
  });

  final User user;
  final Future<void> Function(BuildContext context) onLogout;

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  final _viewModel = RoleHomeViewModel();

  static const _items = <RoleNavItem>[
    RoleNavItem(icon: Icons.dynamic_feed_outlined, label: 'Feed'),
    RoleNavItem(icon: Icons.apartment_outlined, label: 'Toa nha'),
    RoleNavItem(icon: Icons.chat_bubble_outline, label: 'Tin nhan'),
    RoleNavItem(icon: Icons.settings_outlined, label: 'Cai dat'),
  ];

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      FeedScreen(user: widget.user, role: UserRole.manager),
      ManagerBuildingScreen(user: widget.user),
      MessagesScreen(user: widget.user),
      BasicSettingsScreen(user: widget.user),
    ];

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return RoleHomeShell(
          user: widget.user,
          role: UserRole.manager,
          roleLabel: 'Manager',
          avatarText: 'MG',
          avatarColor: const Color(0xFFC8E6C9),
          avatarTextColor: const Color(0xFF1B5E20),
          currentIndex: _viewModel.currentIndex,
          pages: pages,
          items: _items,
          onTapNav: _viewModel.selectIndex,
          onLogout: () => widget.onLogout(context),
        );
      },
    );
  }
}
