import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../auth/screens/login_screen.dart';
import '../view_models/home_view_model.dart';
import 'admin_home_screen.dart';
import 'manager_home_screen.dart';
import 'tenant_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.user, super.key});

  final User user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _viewModel = HomeViewModel();
  late final Future<String> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = _viewModel.loadRole(widget.user.uid);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data ?? _viewModel.fallbackRole();

        return switch (role) {
          UserRole.admin => AdminHomeScreen(
              user: widget.user,
              onLogout: _logout,
            ),
          UserRole.manager => ManagerHomeScreen(
              user: widget.user,
              onLogout: _logout,
            ),
          _ => TenantHomeScreen(
              user: widget.user,
              role: role,
              onLogout: _logout,
            ),
        };
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    await _viewModel.logout();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}
