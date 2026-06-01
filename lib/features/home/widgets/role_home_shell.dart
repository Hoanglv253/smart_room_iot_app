import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'role_header.dart';

class RoleNavItem {
  const RoleNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class RoleHomeShell extends StatelessWidget {
  const RoleHomeShell({
    required this.user,
    required this.role,
    required this.roleLabel,
    required this.avatarText,
    required this.avatarColor,
    required this.avatarTextColor,
    required this.currentIndex,
    required this.pages,
    required this.items,
    required this.onTapNav,
    required this.onLogout,
    super.key,
  });

  final User user;
  final String role;
  final String roleLabel;
  final String avatarText;
  final Color avatarColor;
  final Color avatarTextColor;
  final int currentIndex;
  final List<Widget> pages;
  final List<RoleNavItem> items;
  final ValueChanged<int> onTapNav;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.roleAccent(role);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 76,
        titleSpacing: 14,
        title: RoleHeader(
          user: user,
          roleLabel: roleLabel,
          avatarText: avatarText,
          avatarColor: avatarColor,
          avatarTextColor: avatarTextColor,
        ),
        actions: [
          IconButton(
            tooltip: 'Dang xuat',
            icon: const Icon(Icons.logout_rounded),
            onPressed: onLogout,
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient(accent),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
      ),
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: accent.withValues(alpha: 0.14),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? accent : AppColors.textSecondary,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(color: selected ? accent : AppColors.textSecondary);
          }),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onTapNav,
          destinations: items
              .map(
                (item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
