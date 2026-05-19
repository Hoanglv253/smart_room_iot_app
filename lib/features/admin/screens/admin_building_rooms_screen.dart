import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/admin_profile_data.dart';
import 'admin_nav.dart';

class AdminBuildingRoomsScreen extends StatefulWidget {
  const AdminBuildingRoomsScreen({super.key});

  @override
  State<AdminBuildingRoomsScreen> createState() =>
      _AdminBuildingRoomsScreenState();
}

class _AdminBuildingRoomsScreenState extends State<AdminBuildingRoomsScreen> {
  static const int _currentIndex = 0;

  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _background = Color(0xFFF3F5F8);

  @override
  Widget build(BuildContext context) {
    final roomCount = AdminProfileData.roomCount;

    return Scaffold(
      backgroundColor: _background,
      appBar: const _AdminRoomsAppBar(title: 'IoT CHUNG CƯ - BẢNG ĐIỀU KHIỂN'),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          final users = (snapshot.data?.docs ?? const [])
              .map((doc) => _RegisteredUser.fromFirestore(doc.id, doc.data()))
              .toList();
          final occupiedRooms = List.generate(roomCount, (index) => index + 1)
              .where((room) => users.any((user) => user.roomNumber == room))
              .length;
          final emptyRooms = roomCount - occupiedRooms;

          return SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.black87,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Expanded(
                            child: Text(
                              'QUẢN LÝ TÒA NHÀ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
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
                            child: _SummaryCard(
                              label: 'Tổng số phòng',
                              value: '$roomCount',
                              color: _primaryBlue,
                              icon: Icons.meeting_room,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Có thành viên',
                              value: '$occupiedRooms',
                              color: const Color(0xFF149447),
                              icon: Icons.people,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Còn trống',
                              value: '$emptyRooms',
                              color: Colors.deepOrange,
                              icon: Icons.event_available,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 2)
                else
                  const SizedBox(height: 2),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                    itemCount: roomCount,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final roomNumber = index + 1;
                      final members = users
                          .where((user) => user.roomNumber == roomNumber)
                          .toList();
                      final hasMembers = members.isNotEmpty;
                      return _RoomCard(
                        roomName: _roomName(roomNumber),
                        memberSummary: hasMembers
                            ? '${members.length} thành viên'
                            : 'Đang còn trống',
                        status: hasMembers ? 'Có người ở' : 'Còn trống',
                        statusColor: hasMembers
                            ? const Color(0xFF149447)
                            : Colors.deepOrange,
                        electricity: hasMembers
                            ? '${18 + (roomNumber % 19)}.${roomNumber % 9} kWh'
                            : '0 kWh',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AdminRoomDetailScreen(
                                roomNumber: roomNumber,
                                roomName: _roomName(roomNumber),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => openAdminTab(
          context,
          currentIndex: _currentIndex,
          targetIndex: index,
        ),
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
}

class AdminRoomDetailScreen extends StatelessWidget {
  const AdminRoomDetailScreen({
    super.key,
    required this.roomNumber,
    required this.roomName,
  });

  final int roomNumber;
  final String roomName;

  static const Color _background = Color(0xFFF3F5F8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _AdminRoomsAppBar(title: roomName),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          final users = (snapshot.data?.docs ?? const [])
              .map((doc) => _RegisteredUser.fromFirestore(doc.id, doc.data()))
              .toList();
          final members = users
              .where((user) => user.roomNumber == roomNumber)
              .toList();
          final availableUsers = users
              .where((user) => user.role != 'admin' && user.roomNumber == null)
              .toList();
          final hasMembers = members.isNotEmpty;

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          roomName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _RoomStatusCard(
                    hasMembers: hasMembers,
                    memberCount: members.length,
                  ),
                  const SizedBox(height: 10),
                  _SectionTitle(
                    title: 'THÀNH VIÊN TRONG PHÒNG',
                    actionLabel: 'Thêm',
                    onAction: () =>
                        _showAddMemberSheet(context, availableUsers),
                  ),
                  const SizedBox(height: 8),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (members.isEmpty)
                    const _EmptyRoomCard()
                  else
                    ...members.map(
                      (member) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _MemberCard(
                          member: member,
                          onDelete: () =>
                              _removeMemberFromRoom(context, member),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  const _SectionTitle(title: 'ĐIỆN'),
                  const SizedBox(height: 8),
                  _ElectricityCard(roomNumber: roomNumber),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddMemberSheet(BuildContext context, List<_RegisteredUser> users) {
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
                const Text(
                  'Chọn tài khoản đã đăng ký',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                if (users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Không còn tài khoản người thuê/quản lý nào chưa được gán phòng.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: users.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFF1565C0,
                            ).withValues(alpha: 0.12),
                            child: Text(user.initials),
                          ),
                          title: Text(user.name),
                          subtitle: Text(user.email),
                          trailing: const Icon(Icons.add),
                          onTap: () => _assignUserToRoom(context, user),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _assignUserToRoom(
    BuildContext context,
    _RegisteredUser user,
  ) async {
    await FirebaseFirestore.instance.collection('users').doc(user.id).update({
      'room': roomName,
      'roomNumber': roomNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm ${user.name} vào $roomName.')),
    );
  }

  Future<void> _removeMemberFromRoom(
    BuildContext context,
    _RegisteredUser user,
  ) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa thành viên khỏi phòng?'),
          content: Text('Bạn có chắc muốn xóa ${user.name} khỏi $roomName?'),
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

    if (shouldRemove != true) return;
    await FirebaseFirestore.instance.collection('users').doc(user.id).update({
      'room': FieldValue.delete(),
      'roomNumber': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xóa ${user.name} khỏi $roomName.')),
    );
  }
}

class _RegisteredUser {
  const _RegisteredUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roomNumber,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final int? roomNumber;

  factory _RegisteredUser.fromFirestore(String id, Map<String, dynamic> data) {
    final rawRoomNumber = data['roomNumber'];
    final parsedRoomNumber = rawRoomNumber is int
        ? rawRoomNumber
        : int.tryParse((rawRoomNumber ?? '').toString());
    return _RegisteredUser(
      id: id,
      name:
          (data['name'] ?? data['displayName'] ?? data['email'] ?? 'Không tên')
              .toString(),
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? 'user').toString(),
      roomNumber: parsedRoomNumber,
    );
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
}

class _AdminRoomsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AdminRoomsAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF1565C0),
      foregroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 72,
      titleSpacing: 14,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
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
          icon: const Icon(Icons.notifications, color: Colors.white, size: 21),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _WhitePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.roomName,
    required this.memberSummary,
    required this.status,
    required this.statusColor,
    required this.electricity,
    required this.onTap,
  });

  final String roomName;
  final String memberSummary;
  final String status;
  final Color statusColor;
  final String electricity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: _WhitePanel(
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.meeting_room, color: statusColor, size: 23),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      memberSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Điện: $electricity',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomStatusCard extends StatelessWidget {
  const _RoomStatusCard({required this.hasMembers, required this.memberCount});

  final bool hasMembers;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final color = hasMembers ? const Color(0xFF149447) : Colors.deepOrange;
    return _WhitePanel(
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              hasMembers ? Icons.people : Icons.event_available,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasMembers ? 'Có $memberCount thành viên' : 'Đang còn trống',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasMembers
                      ? 'Thành viên được lấy từ tài khoản đã đăng ký.'
                      : 'Phòng này chưa có tài khoản nào được gán.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
        if (actionLabel != null)
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add, size: 16),
            label: Text(actionLabel!),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}

class _EmptyRoomCard extends StatelessWidget {
  const _EmptyRoomCard();

  @override
  Widget build(BuildContext context) {
    return _WhitePanel(
      child: const Row(
        children: [
          Icon(Icons.info, color: Colors.deepOrange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Không có thành viên nào. Phòng đang còn trống.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onDelete});

  final _RegisteredUser member;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _WhitePanel(
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.12),
            child: Text(member.initials),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Xóa thành viên khỏi phòng',
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ElectricityCard extends StatelessWidget {
  const _ElectricityCard({required this.roomNumber});

  final int roomNumber;

  @override
  Widget build(BuildContext context) {
    return _WhitePanel(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFE7F0FA),
            child: Icon(Icons.electric_bolt, color: Color(0xFF1565C0)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mục điện',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chỉ số tháng này: ${18 + (roomNumber % 19)}.${roomNumber % 9} kWh',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Chức năng quản lý điện sẽ được phát triển sau.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhitePanel extends StatelessWidget {
  const _WhitePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

String _roomName(int roomNumber) {
  return 'Phòng ${roomNumber.toString().padLeft(3, '0')}';
}
