import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../view_models/profile_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.user,
    required this.roleLabel,
    required this.avatarText,
    required this.avatarColor,
    required this.avatarTextColor,
    this.profileUserId,
    this.initialProfile,
    this.onChat,
    super.key,
  });

  final User user;
  final String roleLabel;
  final String avatarText;
  final Color avatarColor;
  final Color avatarTextColor;
  final String? profileUserId;
  final Map<String, dynamic>? initialProfile;
  final Future<void> Function(BuildContext context)? onChat;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _viewModel = ProfileViewModel();

  String get _targetUserId => widget.profileUserId ?? widget.user.uid;
  bool get _isOwnProfile => _targetUserId == widget.user.uid;

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _viewModel.profile(_targetUserId),
      builder: (context, snapshot) {
        final profile =
            snapshot.data?.data() ??
            widget.initialProfile ??
            <String, dynamic>{};

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Hồ sơ')),
            body: _ProfileError(
              message: 'Không tải được hồ sơ. Kiểm tra quyền đọc users.',
              onRetry: () => setState(() {}),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FC),
          appBar: AppBar(
            title: const Text('Hồ sơ'),
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            actions: _isOwnProfile
                ? [
                    IconButton(
                      tooltip: 'Sửa hồ sơ',
                      onPressed: () => _openEditSheet(profile),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ]
                : null,
          ),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _ProfileHeader(
                      profile: profile,
                      user: widget.user,
                      isOwnProfile: _isOwnProfile,
                      roleLabel: widget.roleLabel,
                      avatarText: widget.avatarText,
                      avatarColor: widget.avatarColor,
                      avatarTextColor: widget.avatarTextColor,
                      onEdit: () => _openEditSheet(profile),
                      onChat: widget.onChat == null
                          ? null
                          : () => widget.onChat!(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileSummaryCard(
                            profile: profile,
                            user: widget.user,
                            isOwnProfile: _isOwnProfile,
                            roleLabel: widget.roleLabel,
                          ),
                          const SizedBox(height: 14),
                          _ProfileSection(
                            title: 'Thông tin cá nhân',
                            children: [
                              _InfoTile(
                                icon: Icons.badge_outlined,
                                label: 'Họ tên',
                                value: _displayName(
                                  profile,
                                  _isOwnProfile ? widget.user : null,
                                ),
                              ),
                              _InfoTile(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: _profileEmail(
                                  profile,
                                  widget.user,
                                  _isOwnProfile,
                                ),
                              ),
                              _InfoTile(
                                icon: Icons.phone_outlined,
                                label: 'Số điện thoại',
                                value: _fallback(
                                  _text(profile['phone']),
                                  'Chưa cập nhật',
                                ),
                              ),
                              _InfoTile(
                                icon: Icons.location_on_outlined,
                                label: 'Địa chỉ liên hệ',
                                value: _fallback(
                                  _text(profile['address']),
                                  'Chưa cập nhật',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ProfileSection(
                            title: 'Thông tin trong hệ thống',
                            children: [
                              _InfoTile(
                                icon: Icons.verified_user_outlined,
                                label: 'Vai trò',
                                value: _roleText(profile, widget.roleLabel),
                              ),
                              _InfoTile(
                                icon: Icons.apartment_outlined,
                                label: 'Trạng thái tòa nhà',
                                value: _buildingStatus(profile),
                              ),
                              _InfoTile(
                                icon: Icons.meeting_room_outlined,
                                label: 'Phòng',
                                value: _roomStatus(profile),
                              ),
                              _InfoTile(
                                icon: Icons.event_available_outlined,
                                label: 'Ngày tham gia',
                                value: _dateText(profile['createdAt']),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ProfileSection(
                            title: 'Giới thiệu',
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                child: Text(
                                  _fallback(
                                    _text(profile['bio']),
                                    'Chưa có giới thiệu cá nhân.',
                                  ),
                                  style: const TextStyle(
                                    height: 1.35,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _viewModel,
                builder: (context, _) {
                  if (!_viewModel.isLoading) return const SizedBox.shrink();
                  return Container(
                    color: Colors.black.withValues(alpha: 0.12),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEditSheet(Map<String, dynamic> profile) async {
    if (!_isOwnProfile) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: _displayName(profile, widget.user),
    );
    final phoneController = TextEditingController(text: _text(profile['phone']));
    final addressController = TextEditingController(
      text: _text(profile['address']),
    );
    final bioController = TextEditingController(text: _text(profile['bio']));
    final avatarController = TextEditingController(
      text: _avatarUrl(profile, widget.user, true),
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 18,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Sửa hồ sơ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Đóng',
                            onPressed: _viewModel.isLoading
                                ? null
                                : () => Navigator.of(sheetContext).pop(false),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Họ tên',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Vui lòng nhập họ tên';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ liên hệ',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: avatarController,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Link ảnh đại diện',
                          prefixIcon: Icon(Icons.image_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bioController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Giới thiệu',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _viewModel.isLoading
                            ? null
                            : () async {
                                if (!(formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }

                                final ok = await _viewModel.saveProfile(
                                  user: widget.user,
                                  name: nameController.text,
                                  phone: phoneController.text,
                                  bio: bioController.text,
                                  address: addressController.text,
                                  avatarUrl: avatarController.text,
                                );

                                if (!sheetContext.mounted) return;
                                if (ok) {
                                  Navigator.of(sheetContext).pop(true);
                                  return;
                                }

                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _viewModel.errorMessage ??
                                          'Không lưu được hồ sơ.',
                                    ),
                                  ),
                                );
                              },
                        icon: _viewModel.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Lưu hồ sơ'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    bioController.dispose();
    avatarController.dispose();

    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật hồ sơ.')),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.user,
    required this.isOwnProfile,
    required this.roleLabel,
    required this.avatarText,
    required this.avatarColor,
    required this.avatarTextColor,
    required this.onEdit,
    this.onChat,
  });

  final Map<String, dynamic> profile;
  final User user;
  final bool isOwnProfile;
  final String roleLabel;
  final String avatarText;
  final Color avatarColor;
  final Color avatarTextColor;
  final VoidCallback onEdit;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    final name = _displayName(profile, isOwnProfile ? user : null);
    final email = _profileEmail(profile, user, isOwnProfile);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProfileAvatar(
                profile: profile,
                user: user,
                isOwnProfile: isOwnProfile,
                fallbackText: avatarText,
                fallbackColor: avatarColor,
                fallbackTextColor: avatarTextColor,
                radius: 42,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.isEmpty ? 'Chưa có email' : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFDDEAFE)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeaderChip(
                          icon: Icons.shield_outlined,
                          label: _roleText(profile, roleLabel),
                        ),
                        _HeaderChip(
                          icon: Icons.apartment_outlined,
                          label: _buildingShortStatus(profile),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: isOwnProfile
                ? OutlinedButton.icon(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE0ECFF)),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa hồ sơ'),
                  )
                : FilledButton.icon(
                    onPressed: onChat,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2563EB),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Nhắn tin'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.profile,
    required this.user,
    required this.isOwnProfile,
    required this.roleLabel,
  });

  final Map<String, dynamic> profile;
  final User user;
  final bool isOwnProfile;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final role = _roleKey(profile, roleLabel);
    final color = _roleColor(role);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_roleIcon(role), color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _roleText(profile, roleLabel),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _roleDescription(
                    role,
                    _displayName(profile, isOwnProfile ? user : null),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.profile,
    required this.user,
    required this.isOwnProfile,
    required this.fallbackText,
    required this.fallbackColor,
    required this.fallbackTextColor,
    required this.radius,
  });

  final Map<String, dynamic> profile;
  final User user;
  final bool isOwnProfile;
  final String fallbackText;
  final Color fallbackColor;
  final Color fallbackTextColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _avatarUrl(profile, user, isOwnProfile);

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: radius - 3,
        backgroundColor: fallbackColor,
        backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
        child: avatarUrl.isEmpty
            ? Text(
                fallbackText,
                style: TextStyle(
                  color: fallbackTextColor,
                  fontSize: radius * 0.42,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 54, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14),
  boxShadow: const [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ],
);

String _text(Object? value) {
  return value?.toString().trim() ?? '';
}

String _fallback(String value, String fallback) {
  return value.trim().isEmpty ? fallback : value.trim();
}

String _displayName(Map<String, dynamic> profile, User? user) {
  final name = _text(profile['name']);
  if (name.isNotEmpty) return name;

  final displayName = _text(profile['displayName']);
  if (displayName.isNotEmpty) return displayName;

  final authName = user?.displayName?.trim();
  if (authName != null && authName.isNotEmpty) return authName;

  final email = user?.email ?? _text(profile['email']);
  return email.isEmpty ? 'Tài khoản' : email;
}

String _profileEmail(
  Map<String, dynamic> profile,
  User user,
  bool isOwnProfile,
) {
  final email = isOwnProfile ? user.email : _text(profile['email']);
  return email?.trim() ?? '';
}

String _avatarUrl(
  Map<String, dynamic> profile,
  User user,
  bool isOwnProfile,
) {
  final url = _text(profile['avatarUrl']);
  if (url.isNotEmpty) return url;
  if (!isOwnProfile) return '';
  return user.photoURL?.trim() ?? '';
}

String _roleKey(Map<String, dynamic> profile, String roleLabel) {
  final role = _text(profile['role']);
  if (UserRole.values.contains(role)) return role;

  final normalized = roleLabel.toLowerCase();
  if (normalized.contains('admin')) return UserRole.admin;
  if (normalized.contains('quản lý') || normalized.contains('quan ly')) {
    return UserRole.manager;
  }
  return UserRole.user;
}

String _roleText(Map<String, dynamic> profile, String roleLabel) {
  final key = _roleKey(profile, roleLabel);
  return switch (key) {
    UserRole.admin => 'ADMIN',
    UserRole.manager => 'QUẢN LÝ',
    _ => 'NGƯỜI THUÊ',
  };
}

String _roleDescription(String role, String name) {
  return switch (role) {
    UserRole.admin => '$name có quyền quản lý tòa nhà, phòng, hóa đơn và thành viên.',
    UserRole.manager => '$name hỗ trợ vận hành tòa nhà và làm việc với người thuê.',
    _ => '$name là người thuê trong hệ thống Smart Room.',
  };
}

Color _roleColor(String role) {
  return switch (role) {
    UserRole.admin => const Color(0xFF2563EB),
    UserRole.manager => const Color(0xFF059669),
    _ => const Color(0xFFF97316),
  };
}

IconData _roleIcon(String role) {
  return switch (role) {
    UserRole.admin => Icons.admin_panel_settings_outlined,
    UserRole.manager => Icons.engineering_outlined,
    _ => Icons.person_outline,
  };
}

String _buildingShortStatus(Map<String, dynamic> profile) {
  final buildingId = _text(profile['buildingId']);
  return buildingId.isEmpty ? 'Chưa tham gia' : 'Đã tham gia';
}

String _buildingStatus(Map<String, dynamic> profile) {
  final buildingName = _text(profile['buildingName']);
  if (buildingName.isNotEmpty) return buildingName;

  final buildingId = _text(profile['buildingId']);
  return buildingId.isEmpty ? 'Chưa tham gia tòa nhà' : 'Đã tham gia tòa nhà';
}

String _roomStatus(Map<String, dynamic> profile) {
  final roomName = _text(profile['roomName']);
  if (roomName.isNotEmpty) return roomName;

  final roomId = _text(profile['roomId']);
  return roomId.isEmpty ? 'Chưa gắn phòng' : 'Đã gắn phòng';
}

String _dateText(Object? value) {
  DateTime? date;
  if (value is Timestamp) date = value.toDate();
  if (value is DateTime) date = value;

  if (date == null) return 'Chưa có dữ liệu';

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
