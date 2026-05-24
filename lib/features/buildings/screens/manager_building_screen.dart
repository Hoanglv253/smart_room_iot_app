import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_room_management_screen.dart';
import 'admin_invoice_management_screen.dart';
import 'admin_user_management_screen.dart';
import '../view_models/manager_building_view_model.dart';

class ManagerBuildingScreen extends StatefulWidget {
  const ManagerBuildingScreen({required this.user, super.key});

  final User user;

  @override
  State<ManagerBuildingScreen> createState() => _ManagerBuildingScreenState();
}

class _ManagerBuildingScreenState extends State<ManagerBuildingScreen> {
  final _viewModel = ManagerBuildingViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _viewModel.userProfile(widget.user.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = userSnapshot.data?.data() ?? {};
        final buildingId = (profile['buildingId'] ?? '').toString();
        if (buildingId.isEmpty) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _viewModel.building(buildingId),
          builder: (context, buildingSnapshot) {
            if (buildingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (buildingSnapshot.hasError ||
                buildingSnapshot.data?.exists != true) {
              return const SizedBox.shrink();
            }

            final building = buildingSnapshot.data!.data() ?? {};
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
                _ManagerBuildingStats(
                  buildingId: buildingId,
                  building: building,
                  viewModel: _viewModel,
                ),
                const SizedBox(height: 16),
                _ManagerActionGrid(
                  buildingId: buildingId,
                  building: building,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ManagerBuildingStats extends StatelessWidget {
  const _ManagerBuildingStats({
    required this.buildingId,
    required this.building,
    required this.viewModel,
  });

  final String buildingId;
  final Map<String, dynamic> building;
  final ManagerBuildingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final totalRooms = (building['totalRooms'] as num?)?.toInt() ?? 0;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: viewModel.members(buildingId),
      builder: (context, snapshot) {
        final tenantCount = viewModel.tenantCount(snapshot.data?.docs ?? []);
        final occupiedRooms = tenantCount.clamp(0, totalRooms).toInt();
        final emptyRooms = (totalRooms - occupiedRooms)
            .clamp(0, totalRooms)
            .toInt();

        return Row(
          children: [
            Expanded(
              child: _ManagerStatCard(
                title: 'Tổng người thuê',
                value: '$tenantCount',
                icon: Icons.groups_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ManagerRoomPieCard(
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

class _ManagerStatCard extends StatelessWidget {
  const _ManagerStatCard({
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

class _ManagerRoomPieCard extends StatelessWidget {
  const _ManagerRoomPieCard({
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
                painter: _ManagerRoomPiePainter(
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

class _ManagerRoomPiePainter extends CustomPainter {
  const _ManagerRoomPiePainter({
    required this.occupied,
    required this.empty,
  });

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
  bool shouldRepaint(covariant _ManagerRoomPiePainter oldDelegate) {
    return oldDelegate.occupied != occupied || oldDelegate.empty != empty;
  }
}

class _ManagerActionGrid extends StatelessWidget {
  const _ManagerActionGrid({
    required this.buildingId,
    required this.building,
  });

  final String buildingId;
  final Map<String, dynamic> building;

  static const _actions = [
    _ManagerAction('building', Icons.apartment_outlined, 'Quản lý tòa nhà'),
    _ManagerAction('users', Icons.people_outline, 'Quản lý người dùng'),
    _ManagerAction('bills', Icons.receipt_long_outlined, 'Hóa đơn'),
    _ManagerAction('emergency', Icons.emergency_outlined, 'Khẩn cấp'),
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
    if (actionId == 'building') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminRoomManagementScreen(
            buildingId: buildingId,
            building: building,
            canEditRoom: false,
            canManageTenant: false,
          ),
        ),
      );
      return;
    }

    if (actionId == 'users') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminUserManagementScreen(
            buildingId: buildingId,
            buildingName: (building['name'] ?? 'tòa nhà').toString(),
          ),
        ),
      );
      return;
    }

    if (actionId == 'bills') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminInvoiceManagementScreen(
            buildingId: buildingId,
            building: building,
            canCreate: false,
            canConfirmPayment: false,
          ),
        ),
      );
    }
  }
}

class _ManagerAction {
  const _ManagerAction(this.id, this.icon, this.label);

  final String id;
  final IconData icon;
  final String label;
}
