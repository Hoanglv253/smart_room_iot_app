import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../view_models/admin_user_management_view_model.dart';
import 'admin_member_profile_screen.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({
    required this.buildingId,
    required this.buildingName,
    super.key,
  });

  final String buildingId;
  final String buildingName;

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final _viewModel = AdminUserManagementViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quan ly nguoi dung')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _viewModel.members(widget.buildingId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Khong tai duoc danh sach tai khoan trong toa nha.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Chua co tai khoan nao tham gia ${widget.buildingName}.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = users[index].data();
              final userId = users[index].id;
              final name = (data['name'] ?? data['displayName'] ?? 'Tai khoan')
                  .toString();
              final email = (data['email'] ?? '').toString();
              final role = (data['role'] ?? UserRole.user).toString();

              return Card(
                elevation: 1,
                child: ListTile(
                  leading: CircleAvatar(child: Text(_initials(name, email))),
                  title: Text(name),
                  subtitle: Text(email.isEmpty ? UserRole.label(role) : email),
                  trailing: Chip(label: Text(UserRole.label(role))),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminMemberProfileScreen(
                          userId: userId,
                          userData: data,
                          buildingId: widget.buildingId,
                          buildingName: widget.buildingName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _initials(String name, String email) {
    final source = name.trim().isNotEmpty ? name.trim() : email.trim();
    if (source.isEmpty) return '?';
    return source.substring(0, 1).toUpperCase();
  }
}
