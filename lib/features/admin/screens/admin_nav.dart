import 'package:flutter/material.dart';

import 'admin_device_list_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_user_list_screen.dart';

void openAdminTab(
  BuildContext context, {
  required int currentIndex,
  required int targetIndex,
}) {
  if (targetIndex == currentIndex) return;

  if (targetIndex == 0) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    return;
  }

  final Widget? screen = switch (targetIndex) {
    1 => const AdminUserListScreen(),
    2 => const AdminDeviceListScreen(),
    4 => const AdminSettingsScreen(),
    _ => null,
  };

  if (screen == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chuc nang nay dang duoc phat trien.')),
    );
    return;
  }

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => screen),
  );
}
