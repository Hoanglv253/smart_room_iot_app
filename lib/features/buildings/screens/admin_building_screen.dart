import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';

class AdminBuildingScreen extends StatelessWidget {
  const AdminBuildingScreen({
    required this.user,
    required this.onOpenUserManagement,
    super.key,
  });

  final User user;
  final void Function(String buildingId, String buildingName)
      onOpenUserManagement;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AppFirestoreService.buildings
          .where('adminId', isEqualTo: user.uid)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final buildingDoc = snapshot.data?.docs.isNotEmpty == true
            ? snapshot.data!.docs.first
            : null;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (buildingDoc == null) {
          return const _NoBuildingView();
        }

        final buildingId = buildingDoc.id;
        final building = buildingDoc.data();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              (building['name'] ?? 'Tòa nhà của tôi').toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text((building['address'] ?? 'Chưa có địa chỉ').toString()),
            const SizedBox(height: 16),
            _BuildingStats(buildingId: buildingId, building: building),
            const SizedBox(height: 16),
            _AdminActionGrid(
              buildingId: buildingId,
              building: building,
              onOpenUserManagement: onOpenUserManagement,
            ),
            const SizedBox(height: 16),
            _JoinRequestBoard(buildingId: buildingId),
          ],
        );
      },
    );
  }
}

class _NoBuildingView extends StatelessWidget {
  const _NoBuildingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Bạn chưa thiết lập tòa nhà. Hãy vào tab Cài đặt để tạo thông tin tòa nhà.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _BuildingStats extends StatelessWidget {
  const _BuildingStats({required this.buildingId, required this.building});

  final String buildingId;
  final Map<String, dynamic> building;

  @override
  Widget build(BuildContext context) {
    final totalRooms = (building['totalRooms'] as num?)?.toInt() ?? 0;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AppFirestoreService.users
          .where('buildingId', isEqualTo: buildingId)
          .snapshots(),
      builder: (context, snapshot) {
        final tenantCount = (snapshot.data?.docs ?? [])
            .where((doc) => doc.data()['role'] == UserRole.user)
            .length;
        final occupiedRooms = tenantCount.clamp(0, totalRooms);
        final emptyRooms = (totalRooms - occupiedRooms).clamp(0, totalRooms);

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Tổng người thuê',
                value: '$tenantCount',
                icon: Icons.groups_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoomPieCard(
                totalRooms: totalRooms,
                occupiedRooms: occupiedRooms,
                emptyRooms: emptyRooms,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.blueAccent, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _RoomPieCard extends StatelessWidget {
  const _RoomPieCard({
    required this.totalRooms,
    required this.occupiedRooms,
    required this.emptyRooms,
  });

  final int totalRooms;
  final int occupiedRooms;
  final int emptyRooms;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: 68,
              height: 68,
              child: CustomPaint(
                painter: _RoomPiePainter(
                  occupied: occupiedRooms,
                  empty: emptyRooms,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$totalRooms phòng',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Trống: $emptyRooms | Đã thuê: $occupiedRooms'),
          ],
        ),
      ),
    );
  }
}

class _RoomPiePainter extends CustomPainter {
  const _RoomPiePainter({required this.occupied, required this.empty});

  final int occupied;
  final int empty;

  @override
  void paint(Canvas canvas, Size size) {
    final total = occupied + empty;
    final rect = Offset.zero & size;
    final occupiedPaint = Paint()..color = Colors.blueAccent;
    final emptyPaint = Paint()..color = const Color(0xFFBDBDBD);

    if (total == 0) {
      canvas.drawArc(rect, 0, 6.283, true, emptyPaint);
      return;
    }

    final occupiedSweep = (occupied / total) * 6.283;
    canvas.drawArc(rect, -1.5708, occupiedSweep, true, occupiedPaint);
    canvas.drawArc(
      rect,
      -1.5708 + occupiedSweep,
      6.283 - occupiedSweep,
      true,
      emptyPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RoomPiePainter oldDelegate) {
    return oldDelegate.occupied != occupied || oldDelegate.empty != empty;
  }
}

class _AdminActionGrid extends StatelessWidget {
  const _AdminActionGrid({
    required this.buildingId,
    required this.building,
    required this.onOpenUserManagement,
  });

  final String buildingId;
  final Map<String, dynamic> building;
  final void Function(String buildingId, String buildingName)
      onOpenUserManagement;

  static const _actions = [
    _AdminAction('building', Icons.apartment_outlined, 'Quản lý tòa nhà'),
    _AdminAction('users', Icons.people_outline, 'Quản lý người dùng'),
    _AdminAction('bills', Icons.receipt_long_outlined, 'Hóa đơn'),
    _AdminAction('emergency', Icons.emergency_outlined, 'Khẩn cấp'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: _actions.map((action) {
        return Card(
          elevation: 1,
          child: InkWell(
            onTap: () => _handleActionTap(context, action.id),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.icon, color: Colors.blueAccent),
                const SizedBox(height: 8),
                Text(action.label, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleActionTap(BuildContext context, String actionId) {
    if (actionId == 'users') {
      onOpenUserManagement(
        buildingId,
        (building['name'] ?? 'toa nha').toString(),
      );
    }
  }
}

class _AdminAction {
  const _AdminAction(this.id, this.icon, this.label);

  final String id;
  final IconData icon;
  final String label;
}

class _JoinRequestBoard extends StatelessWidget {
  const _JoinRequestBoard({required this.buildingId});

  final String buildingId;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bảng thông báo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: AppFirestoreService.joinRequests
                  .where('buildingId', isEqualTo: buildingId)
                  .where('status', isEqualTo: JoinRequestStatus.pending)
                  .snapshots(),
              builder: (context, snapshot) {
                final requests = snapshot.data?.docs ?? [];
                if (requests.isEmpty) {
                  return const Text('Chưa có yêu cầu tham gia nào.');
                }

                return Column(
                  children: requests.map((doc) {
                    final data = doc.data();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notifications_outlined),
                      title: Text(
                        (data['requesterName'] ?? 'Người dùng').toString(),
                      ),
                      subtitle: Text(
                        'Muốn tham gia với vai trò ${UserRole.label((data['requesterRole'] ?? UserRole.user).toString())}',
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Duyệt',
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _approve(doc.id, data),
                          ),
                          IconButton(
                            tooltip: 'Từ chối',
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _reject(doc.id),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(String requestId, Map<String, dynamic> data) async {
    final requesterId = (data['requesterId'] ?? '').toString();
    if (requesterId.isEmpty) return;

    await AppFirestoreService.db.runTransaction((transaction) async {
      transaction.update(AppFirestoreService.joinRequests.doc(requestId), {
        'status': JoinRequestStatus.approved,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(AppFirestoreService.users.doc(requesterId), {
        'buildingId': buildingId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _ensureGroupChatMember(requesterId);
  }

  Future<void> _reject(String requestId) {
    return AppFirestoreService.joinRequests.doc(requestId).update({
      'status': JoinRequestStatus.rejected,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _ensureGroupChatMember(String requesterId) async {
    final query = await AppFirestoreService.chats
        .where('type', isEqualTo: ChatType.group)
        .where('buildingId', isEqualTo: buildingId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return;

    await query.docs.first.reference.update({
      'memberIds': FieldValue.arrayUnion([requesterId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
