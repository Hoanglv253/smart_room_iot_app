import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _keyword = '';
  String _roleFilter = 'all';
  int _currentIndex = 1;

  static const Color _primaryBlue = Color(0xFF1565C0);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 72,
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFFFCCBC),
              child: Text(
                'AD',
                style: TextStyle(
                  color: Color(0xFF5D4037),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IoT CHUNG CƯ - BẢNG ĐIỀU KHIỂN',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Admin Hoàng VL.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 21),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: Colors.white,
              size: 21,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'DANH SÁCH NGƯỜI DÙNG',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(
                              () => _keyword = value.trim().toLowerCase(),
                            );
                          },
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm theo tên, email, ID...',
                            hintStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(Icons.search, size: 19),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF6F8FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide: const BorderSide(
                                color: Color(0xFFDDE5EE),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(7),
                              borderSide: const BorderSide(
                                color: Color(0xFFDDE5EE),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    _SmallFilterButton(label: 'Lọc', onTap: _showRoleFilter),
                    const SizedBox(width: 7),
                    _SmallFilterButton(
                      label: 'Sắp xếp',
                      onTap: () => setState(() {}),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 32,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text('Avatar', style: _HeaderStyle()),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: Text('Tên Người Dùng', style: _HeaderStyle()),
                ),
                Expanded(flex: 3, child: Text('ID', style: _HeaderStyle())),
                Expanded(
                  flex: 3,
                  child: Text('Vai Trò', style: _HeaderStyle()),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Liên Hệ/Phòng', style: _HeaderStyle()),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryBlue),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Không tải được danh sách người dùng.'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final users =
                    docs
                        .map(
                          (doc) => _AdminUser.fromFirestore(doc.id, doc.data()),
                        )
                        .where(_matchesFilter)
                        .toList()
                      ..sort((a, b) {
                        final roleCompare = _roleRank(
                          a.role,
                        ).compareTo(_roleRank(b.role));
                        if (roleCompare != 0) return roleCompare;
                        return a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        );
                      });

                if (users.isEmpty) {
                  return const Center(
                    child: Text('Chưa có tài khoản phù hợp.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  itemCount: users.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Color(0xFFE7EAF0)),
                  itemBuilder: (context, index) {
                    return _UserRow(
                      user: users[index],
                      onTap: () => _showUserActions(users[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pop();
            return;
          }
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang Chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Người Dùng',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Thiết Bị'),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Nhật Ký',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài Đặt'),
        ],
      ),
    );
  }

  bool _matchesFilter(_AdminUser user) {
    if (_roleFilter != 'all' && user.role != _roleFilter) return false;
    if (_keyword.isEmpty) return true;

    final haystack = [
      user.name,
      user.email,
      user.shortId,
      user.roleLabel,
      user.room,
    ].join(' ').toLowerCase();
    return haystack.contains(_keyword);
  }

  int _roleRank(String role) {
    switch (role) {
      case 'admin':
        return 0;
      case 'manager':
        return 1;
      default:
        return 2;
    }
  }

  void _showRoleFilter() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RoleFilterTile(
                title: 'Tất cả tài khoản',
                selected: _roleFilter == 'all',
                onTap: () => _setRoleFilter('all'),
              ),
              _RoleFilterTile(
                title: 'Quản trị viên',
                selected: _roleFilter == 'admin',
                onTap: () => _setRoleFilter('admin'),
              ),
              _RoleFilterTile(
                title: 'Quản lý',
                selected: _roleFilter == 'manager',
                onTap: () => _setRoleFilter('manager'),
              ),
              _RoleFilterTile(
                title: 'Người thuê',
                selected: _roleFilter == 'user',
                onTap: () => _setRoleFilter('user'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setRoleFilter(String role) {
    setState(() => _roleFilter = role);
    Navigator.of(context).pop();
  }

  void _showUserActions(_AdminUser user) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.email} • ${user.roleLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                if (user.role == 'user')
                  _ActionTile(
                    icon: Icons.workspace_premium,
                    color: _primaryBlue,
                    title: 'Bổ nhiệm làm quản lý',
                    subtitle: 'Đổi vai trò tài khoản này thành Quản lý',
                    onTap: () => _updateUserRole(user, 'manager'),
                  ),
                if (user.role == 'manager')
                  _ActionTile(
                    icon: Icons.person_remove_alt_1,
                    color: Colors.deepOrange,
                    title: 'Cắt chức',
                    subtitle: 'Đổi vai trò tài khoản này về Người thuê',
                    onTap: () => _updateUserRole(user, 'user'),
                  ),
                if (user.role == 'admin')
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Tài khoản quản trị không thể đổi vai trò tại đây.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                _ActionTile(
                  icon: Icons.delete,
                  color: Colors.redAccent,
                  title: 'Xóa tài khoản khỏi danh sách',
                  subtitle: 'Xóa hồ sơ người dùng trong Firestore',
                  onTap: () => _confirmDeleteUser(user),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateUserRole(_AdminUser user, String role) async {
    Navigator.of(context).pop();
    try {
      await _firestore.collection('users').doc(user.id).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      final roleName = role == 'manager' ? 'Quản lý' : 'Người thuê';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật ${user.name} thành $roleName.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cập nhật thất bại: $e')));
    }
  }

  Future<void> _confirmDeleteUser(_AdminUser user) async {
    Navigator.of(context).pop();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa tài khoản?'),
          content: Text(
            'Bạn có chắc muốn xóa hồ sơ của ${user.name} khỏi danh sách người dùng không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _firestore.collection('users').doc(user.id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xóa ${user.name} khỏi danh sách.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xóa thất bại: $e')));
    }
  }
}

class _HeaderStyle extends TextStyle {
  const _HeaderStyle()
    : super(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black87);
}

class _SmallFilterButton extends StatelessWidget {
  const _SmallFilterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Color(0xFFDDE5EE)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.onTap});

  final _AdminUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: user.avatarColor.withValues(alpha: 0.2),
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      color: user.avatarColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  user.shortId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: user.roleColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.roleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  user.contactDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

class _RoleFilterTile extends StatelessWidget {
  const _RoleFilterTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: selected
          ? const Icon(
              Icons.check,
              color: _AdminUserListScreenState._primaryBlue,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _AdminUser {
  const _AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.room,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String room;

  factory _AdminUser.fromFirestore(String id, Map<String, dynamic> data) {
    final name =
        (data['name'] ?? data['displayName'] ?? data['email'] ?? 'Không tên')
            .toString();
    return _AdminUser(
      id: id,
      name: name,
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? 'user').toString(),
      phone: (data['phone'] ?? data['phoneNumber'] ?? '').toString(),
      room: (data['room'] ?? data['roomCode'] ?? data['roomNumber'] ?? '')
          .toString(),
    );
  }

  String get shortId {
    final prefix = role == 'admin'
        ? 'USR_AD'
        : role == 'manager'
        ? 'USR_MG'
        : 'USR_TE';
    final tail = id.length >= 4
        ? id.substring(0, 4).toUpperCase()
        : id.toUpperCase();
    return '$prefix$tail';
  }

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Quản trị';
      case 'manager':
        return 'Quản lý';
      default:
        return 'Người thuê';
    }
  }

  Color get roleColor {
    switch (role) {
      case 'admin':
        return Colors.redAccent;
      case 'manager':
        return const Color(0xFF149447);
      default:
        return const Color(0xFF1565C0);
    }
  }

  Color get avatarColor {
    switch (role) {
      case 'admin':
        return Colors.redAccent;
      case 'manager':
        return const Color(0xFF149447);
      default:
        return const Color(0xFF1565C0);
    }
  }

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String get contactDisplay {
    if (role == 'admin') return phone.isNotEmpty ? phone : email;
    if (role == 'manager') return room.isNotEmpty ? room : 'Tầng';
    return room.isNotEmpty ? room : (phone.isNotEmpty ? phone : email);
  }
}
