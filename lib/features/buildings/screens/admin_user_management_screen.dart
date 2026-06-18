import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../view_models/admin_user_management_view_model.dart';

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
  final _searchController = TextEditingController();
  final _viewModel = AdminUserManagementViewModel();
  final _memberActionViewModel = AdminMemberProfileViewModel();
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _memberActionViewModel.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: AppColors.primary,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient()),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _viewModel.members(widget.buildingId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Không tải được danh sách tài khoản trong tòa nhà.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = (snapshot.data?.docs ?? [])
              .map((doc) => _MemberView.fromDoc(doc))
              .toList()
            ..sort(_sortMembers);

          if (members.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Chưa có tài khoản nào tham gia ${widget.buildingName}.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final filteredMembers = members.where(_matchesFilters).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _UserManagementHero(
                buildingName: widget.buildingName,
                members: members,
                onAddUser: _showAddUserHint,
              ),
              const SizedBox(height: 14),
              _UserSearchPanel(
                controller: _searchController,
                selectedRole: _selectedRole,
                onRoleChanged: _selectRole,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '${filteredMembers.length} thành viên',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${members.length} tổng',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (filteredMembers.isEmpty)
                const _EmptyUserResult()
              else
                ...filteredMembers.map(
                  (member) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MemberCard(
                      member: member,
                      onTap: () => _showMemberActions(member),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserHint,
        child: const Icon(Icons.add),
      ),
    );
  }

  bool _matchesFilters(_MemberView member) {
    if (_selectedRole != null && member.role != _selectedRole) return false;

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;

    return member.name.toLowerCase().contains(query) ||
        member.email.toLowerCase().contains(query) ||
        member.roleLabel.toLowerCase().contains(query) ||
        member.roomLabel.toLowerCase().contains(query);
  }

  void _selectRole(String? role) {
    setState(() => _selectedRole = role);
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _showMemberActions(_MemberView member) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AnimatedBuilder(
              animation: _memberActionViewModel,
              builder: (context, _) {
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                    onPressed: _memberActionViewModel.isLoading
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            _confirmRemoveMember(member);
                          },
                    icon: _memberActionViewModel.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_remove_outlined),
                    label: const Text('Xóa khỏi tòa nhà'),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmRemoveMember(_MemberView member) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa khỏi tòa nhà?'),
          content: Text(
            'Bạn có chắc muốn xóa ${member.name} khỏi ${widget.buildingName}?',
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
      await _removeMember(member);
    }
  }

  Future<void> _removeMember(_MemberView member) async {
    final removed = await _memberActionViewModel.removeFromBuilding(
      buildingId: widget.buildingId,
      userId: member.id,
      roomId: member.roomId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed ? 'Đã xóa tài khoản khỏi tòa nhà.' : _removeErrorMessage(),
        ),
      ),
    );
  }

  String _removeErrorMessage() {
    if (_memberActionViewModel.errorMessage?.contains('permission-denied') ==
        true) {
      return 'Firestore chưa cấp quyền xóa thành viên khỏi tòa nhà.';
    }

    return 'Không xóa được thành viên.';
  }

  void _showAddUserHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Người dùng cần gửi yêu cầu tham gia tòa nhà trước.'),
      ),
    );
  }

  int _sortMembers(_MemberView a, _MemberView b) {
    final roleCompare = _roleWeight(a.role).compareTo(_roleWeight(b.role));
    if (roleCompare != 0) return roleCompare;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  int _roleWeight(String role) {
    return switch (role) {
      UserRole.admin => 0,
      UserRole.manager => 1,
      _ => 2,
    };
  }
}

class _UserManagementHero extends StatelessWidget {
  const _UserManagementHero({
    required this.buildingName,
    required this.members,
    required this.onAddUser,
  });

  final String buildingName;
  final List<_MemberView> members;
  final VoidCallback onAddUser;

  @override
  Widget build(BuildContext context) {
    final managerCount = members
        .where((member) => member.role == UserRole.manager)
        .length;
    final userCount = members
        .where((member) => member.role == UserRole.user)
        .length;
    final unassignedCount = members
        .where((member) => member.isUnassigned)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient(),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -28,
            child: Icon(
              Icons.groups_rounded,
              color: Colors.white.withValues(alpha: 0.12),
              size: 146,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buildingName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${members.length} thành viên',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: onAddUser,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(104, 46),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _UserMetric(
                      label: 'Quản lý',
                      value: managerCount,
                      color: AppColors.managerAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _UserMetric(
                      label: 'Người dùng',
                      value: userCount,
                      color: AppColors.tenantAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _UserMetric(
                      label: 'Chưa gắn',
                      value: unassignedCount,
                      color: const Color(0xFFFACC15),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserMetric extends StatelessWidget {
  const _UserMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserSearchPanel extends StatelessWidget {
  const _UserSearchPanel({
    required this.controller,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final TextEditingController controller;
  final String? selectedRole;
  final ValueChanged<String?> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Tìm tên, email, vai trò...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.tune_outlined),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _RoleFilterChip(
                  label: 'Tất cả',
                  selected: selectedRole == null,
                  onTap: () => onRoleChanged(null),
                ),
                _RoleFilterChip(
                  label: 'Quản lý',
                  selected: selectedRole == UserRole.manager,
                  onTap: () => onRoleChanged(UserRole.manager),
                ),
                _RoleFilterChip(
                  label: 'Người dùng',
                  selected: selectedRole == UserRole.user,
                  onTap: () => onRoleChanged(UserRole.user),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleFilterChip extends StatelessWidget {
  const _RoleFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        avatar: selected ? const Icon(Icons.check, size: 18) : null,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onTap,
  });

  final _MemberView member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: member.roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  member.initials,
                  style: TextStyle(
                    color: member.roleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RoleBadge(member: member),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      member.email.isEmpty ? member.roleLabel : member.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Flexible(
                          child: _MemberInfoPill(
                            icon: member.role == UserRole.manager
                                ? Icons.admin_panel_settings_outlined
                                : Icons.meeting_room_outlined,
                            label: member.roomLabel,
                            color: member.roomColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MemberInfoPill(
                          icon: Icons.person_remove_outlined,
                          label: 'Xóa',
                          color: const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.member});

  final _MemberView member;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: member.roleColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: member.roleColor.withValues(alpha: 0.18)),
      ),
      child: Text(
        member.roleLabel,
        style: TextStyle(
          color: member.roleColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MemberInfoPill extends StatelessWidget {
  const _MemberInfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyUserResult extends StatelessWidget {
  const _EmptyUserResult();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Không tìm thấy thành viên phù hợp.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _MemberView {
  const _MemberView({
    required this.id,
    required this.data,
    required this.name,
    required this.email,
    required this.role,
    required this.roomId,
    required this.roomName,
    required this.roomNumber,
  });

  factory _MemberView.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final name = (data['name'] ?? data['displayName'] ?? 'Tài khoản')
        .toString()
        .trim();

    return _MemberView(
      id: doc.id,
      data: data,
      name: name.isEmpty ? 'Tài khoản' : name,
      email: (data['email'] ?? '').toString().trim(),
      role: (data['role'] ?? UserRole.user).toString(),
      roomId: (data['roomId'] ?? '').toString().trim(),
      roomName: (data['roomName'] ?? '').toString().trim(),
      roomNumber: data['roomNumber'],
    );
  }

  final String id;
  final Map<String, dynamic> data;
  final String name;
  final String email;
  final String role;
  final String roomId;
  final String roomName;
  final Object? roomNumber;

  String get roleLabel => UserRole.label(role);

  bool get isUnassigned {
    return role == UserRole.user && roomId.isEmpty && roomName.isEmpty;
  }

  String get roomLabel {
    if (role == UserRole.manager) return 'Quản lý tòa nhà';
    if (roomName.isNotEmpty) return roomName;
    if (roomNumber != null) return 'Phòng $roomNumber';
    return 'Chưa gắn phòng';
  }

  Color get roleColor {
    return switch (role) {
      UserRole.admin => AppColors.primary,
      UserRole.manager => AppColors.managerAccent,
      _ => AppColors.tenantAccent,
    };
  }

  Color get roomColor {
    if (role == UserRole.manager) return AppColors.managerAccent;
    return isUnassigned ? const Color(0xFFF59E0B) : AppColors.primary;
  }

  String get initials {
    final source = name.trim().isNotEmpty ? name.trim() : email.trim();
    if (source.isEmpty) return '?';
    final words = source.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.take(2).map((word) => word[0]).join().toUpperCase();
  }
}
