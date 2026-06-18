import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../view_models/admin_user_management_view_model.dart';

class AdminMemberProfileScreen extends StatefulWidget {
  const AdminMemberProfileScreen({
    required this.userId,
    required this.userData,
    required this.buildingId,
    required this.buildingName,
    super.key,
  });

  final String userId;
  final Map<String, dynamic> userData;
  final String buildingId;
  final String buildingName;

  @override
  State<AdminMemberProfileScreen> createState() =>
      _AdminMemberProfileScreenState();
}

class _AdminMemberProfileScreenState extends State<AdminMemberProfileScreen> {
  final _viewModel = AdminMemberProfileViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  String get _name {
    return (widget.userData['name'] ??
            widget.userData['displayName'] ??
            widget.userData['email'] ??
            'Tài khoản')
        .toString();
  }

  String get _email {
    return (widget.userData['email'] ?? '').toString();
  }

  String get _role {
    return (widget.userData['role'] ?? UserRole.user).toString();
  }

  String get _initials {
    final source = _name.trim().isNotEmpty ? _name.trim() : _email.trim();
    if (source.isEmpty) return '?';
    return source.substring(0, 1).toUpperCase();
  }

  Future<void> _confirmRemove() async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa khỏi tòa nhà?'),
          content: Text(
            'Bạn có chắc muốn xóa $_name khỏi ${widget.buildingName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      await _removeFromBuilding();
    }
  }

  Future<void> _removeFromBuilding() async {
    final removed = await _viewModel.removeFromBuilding(
      buildingId: widget.buildingId,
      userId: widget.userId,
      roomId: (widget.userData['roomId'] ?? '').toString(),
    );

    if (removed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa tài khoản khỏi tòa nhà.')),
      );
      Navigator.of(context).pop();
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_removeErrorMessage())),
    );
  }

  String _removeErrorMessage() {
    if (_viewModel.errorMessage?.contains('permission-denied') == true) {
      return 'Firestore chưa cấp quyền xóa thành viên khỏi tòa nhà.';
    }

    return 'Không xóa được thành viên.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ thành viên')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 56,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(UserRole.label(_role)),
              if (_email.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(_email, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 6),
              Text(
                widget.buildingName,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _viewModel,
                builder: (context, _) {
                  return FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: _viewModel.isLoading ? null : _confirmRemove,
                    icon: _viewModel.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_remove_outlined),
                    label: const Text('Xóa khỏi tòa nhà'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
