import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import 'admin_home_screen.dart';
import 'manager_home_screen.dart';
import 'tenant_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return FutureBuilder<String>(
      future: authService.getUserRole(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data ?? UserRole.user;
        Future<void> onLogout(BuildContext context) {
          return _logout(context, authService);
        }

        return switch (role) {
          UserRole.admin => AdminHomeScreen(user: user, onLogout: onLogout),
          UserRole.manager => ManagerHomeScreen(user: user, onLogout: onLogout),
          _ => TenantHomeScreen(
              user: user,
              role: role,
              onLogout: onLogout,
            ),
        };
      },
    );
  }

  Future<void> _logout(BuildContext context, AuthService authService) async {
    await authService.logout();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}
