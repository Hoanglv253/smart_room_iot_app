import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class BuildingDashboardAction {
  const BuildingDashboardAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color color;
}

class BuildingDashboardTask {
  const BuildingDashboardTask({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final Color color;
  final VoidCallback? onTap;
}

class BuildingDashboardContent extends StatelessWidget {
  const BuildingDashboardContent({
    required this.building,
    required this.rooms,
    required this.tenantCount,
    required this.pendingRequestCount,
    required this.pendingInvoiceCount,
    required this.actions,
    this.footer,
    super.key,
  });

  final Map<String, dynamic> building;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms;
  final int tenantCount;
  final int pendingRequestCount;
  final int pendingInvoiceCount;
  final List<BuildingDashboardAction> actions;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final stats = _DashboardRoomStats.from(
      building: building,
      rooms: rooms,
      tenantCount: tenantCount,
    );
    final tasks = [
      BuildingDashboardTask(
        icon: Icons.receipt_long_outlined,
        title: 'Hóa đơn chờ xác nhận',
        count: pendingInvoiceCount,
        color: const Color(0xFFF59E0B),
      ),
      BuildingDashboardTask(
        icon: Icons.person_add_alt_1_outlined,
        title: 'Yêu cầu tham gia mới',
        count: pendingRequestCount,
        color: const Color(0xFF2168F3),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _BuildingHeroCard(building: building, stats: stats),
        const SizedBox(height: 14),
        _MetricStrip(
          totalRooms: stats.totalRooms,
          availableRooms: stats.availableRooms,
          occupiedRooms: stats.occupiedRooms,
          pendingRequestCount: pendingRequestCount,
        ),
        const SizedBox(height: 14),
        _FloorOverviewCard(floors: stats.floors),
        const SizedBox(height: 14),
        _QuickActionsCard(actions: actions),
        const SizedBox(height: 14),
        _TaskBoardCard(tasks: tasks),
        if (footer != null) ...[
          const SizedBox(height: 14),
          footer!,
        ],
      ],
    );
  }
}

class _BuildingHeroCard extends StatelessWidget {
  const _BuildingHeroCard({required this.building, required this.stats});

  final Map<String, dynamic> building;
  final _DashboardRoomStats stats;

  @override
  Widget build(BuildContext context) {
    final name = _text(building['name'], 'Tòa nhà của tôi');
    final address = _text(building['address'], 'Chưa có Địa chỉ');
    final occupancy = stats.totalRooms == 0
        ? 0
        : ((stats.occupiedRooms / stats.totalRooms) * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient(),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -24,
            child: Icon(
              Icons.apartment_rounded,
              size: 132,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Text(
                      'Đang hoạt động',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.maps_home_work_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: stats.totalRooms == 0
                      ? 0
                      : stats.occupiedRooms / stats.totalRooms,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$occupancy% phòng đang được thuê',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({
    required this.totalRooms,
    required this.availableRooms,
    required this.occupiedRooms,
    required this.pendingRequestCount,
  });

  final int totalRooms;
  final int availableRooms;
  final int occupiedRooms;
  final int pendingRequestCount;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric('Tổng phòng', '$totalRooms', Icons.meeting_room_outlined,
          AppColors.primary),
      _Metric('Phòng trêng', '$availableRooms', Icons.check_circle_outline,
          const Color(0xFF16A34A)),
      _Metric('Đã thuê', '$occupiedRooms', Icons.key_outlined,
          const Color(0xFF0EA5E9)),
      _Metric('Yêu cầu', '$pendingRequestCount', Icons.notifications_outlined,
          const Color(0xFFF59E0B)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            _MetricCard(metric: metrics[index]),
            if (index != metrics.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: metric.color, size: 22),
          const SizedBox(height: 10),
          Text(
            metric.value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloorOverviewCard extends StatelessWidget {
  const _FloorOverviewCard({required this.floors});

  final List<_DashboardFloorStats> floors;

  @override
  Widget build(BuildContext context) {
    return _DashboardSectionCard(
      title: 'Sơ đồ tầng',
      trailing: floors.isEmpty ? null : '${floors.length} tầng',
      child: floors.isEmpty
          ? const Text(
              'Chưa có dữ liệu phòng để hiển thị sơ đồ tầng.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < floors.length; index++) ...[
                    _FloorChip(floor: floors[index]),
                    if (index != floors.length - 1) const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
    );
  }
}

class _FloorChip extends StatelessWidget {
  const _FloorChip({required this.floor});

  final _DashboardFloorStats floor;

  @override
  Widget build(BuildContext context) {
    final availability = floor.total == 0 ? 0.0 : floor.available / floor.total;
    final label = floor.floor > 0 ? 'Tầng ${floor.floor}' : 'Khác';

    return Container(
      width: 118,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: availability,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${floor.available}/${floor.total} trong',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.actions});

  final List<BuildingDashboardAction> actions;

  @override
  Widget build(BuildContext context) {
    return _DashboardSectionCard(
      title: 'Thao tác nhanh',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.25,
        ),
        itemBuilder: (context, index) {
          return _QuickActionTile(action: actions[index]);
        },
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final BuildingDashboardAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(action.icon, color: action.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (action.subtitle != null)
                      Text(
                        action.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
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

class _TaskBoardCard extends StatelessWidget {
  const _TaskBoardCard({required this.tasks});

  final List<BuildingDashboardTask> tasks;

  @override
  Widget build(BuildContext context) {
    final activeTasks = tasks.where((task) => task.count > 0).toList();

    return _DashboardSectionCard(
      title: 'Cần xử lý',
      child: activeTasks.isEmpty
          ? const _AllClearTaskRow()
          : Column(
              children: [
                for (var index = 0; index < activeTasks.length; index++) ...[
                  _TaskRow(task: activeTasks[index]),
                  if (index != activeTasks.length - 1)
                    const Divider(height: 18),
                ],
              ],
            ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final BuildingDashboardTask task;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: task.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: task.color.withValues(alpha: 0.12),
              child: Icon(task.icon, color: task.color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                task.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: task.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${task.count}',
                style: TextStyle(
                  color: task.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllClearTaskRow extends StatelessWidget {
  const _AllClearTaskRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFFEAFBF1),
          child: Icon(Icons.check_rounded, color: Color(0xFF16A34A)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Mọi thứ đang ổn định, chưa có việc cần xử lý.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _DashboardSectionCard extends StatelessWidget {
  const _DashboardSectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const Spacer(),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DashboardRoomStats {
  const _DashboardRoomStats({
    required this.totalRooms,
    required this.availableRooms,
    required this.occupiedRooms,
    required this.floors,
  });

  final int totalRooms;
  final int availableRooms;
  final int occupiedRooms;
  final List<_DashboardFloorStats> floors;

  factory _DashboardRoomStats.from({
    required Map<String, dynamic> building,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms,
    required int tenantCount,
  }) {
    final configuredTotal = _readInt(building['totalRooms']);
    if (rooms.isEmpty) {
      final occupied = tenantCount.clamp(0, configuredTotal).toInt();
      final available = (configuredTotal - occupied)
          .clamp(0, configuredTotal)
          .toInt();
      return _DashboardRoomStats(
        totalRooms: configuredTotal,
        availableRooms: available,
        occupiedRooms: occupied,
        floors: _fallbackFloors(building, configuredTotal, available),
      );
    }

    final floors = <int, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    var available = 0;
    var occupied = 0;
    for (final room in rooms) {
      final data = room.data();
      final status = _roomStatus(data);
      if (status == 'available') available++;
      if (status == 'occupied') occupied++;
      final floor = _readInt(data['floor']);
      floors.putIfAbsent(floor, () => []).add(room);
    }

    final floorStats = floors.entries.map((entry) {
      final floorRooms = entry.value;
      final floorAvailable = floorRooms
          .where((room) => _roomStatus(room.data()) == 'available')
          .length;
      return _DashboardFloorStats(
        floor: entry.key,
        total: floorRooms.length,
        available: floorAvailable,
      );
    }).toList()
      ..sort((left, right) => left.floor.compareTo(right.floor));

    return _DashboardRoomStats(
      totalRooms: rooms.length,
      availableRooms: available,
      occupiedRooms: occupied,
      floors: floorStats,
    );
  }

  static List<_DashboardFloorStats> _fallbackFloors(
    Map<String, dynamic> building,
    int totalRooms,
    int availableRooms,
  ) {
    final floorCount = _readInt(building['floorCount']);
    if (floorCount <= 0 || totalRooms <= 0) return const [];
    final perFloor = (totalRooms / floorCount).ceil();
    final floors = <_DashboardFloorStats>[];
    var remainingTotal = totalRooms;
    var remainingAvailable = availableRooms;
    for (var floor = 1; floor <= floorCount; floor++) {
      final total = floor == floorCount
          ? remainingTotal
          : perFloor.clamp(0, remainingTotal).toInt();
      final available = total == 0
          ? 0
          : remainingAvailable.clamp(0, total).toInt();
      floors.add(
        _DashboardFloorStats(
          floor: floor,
          total: total,
          available: available,
        ),
      );
      remainingTotal -= total;
      remainingAvailable -= available;
    }
    return floors;
  }
}

class _DashboardFloorStats {
  const _DashboardFloorStats({
    required this.floor,
    required this.total,
    required this.available,
  });

  final int floor;
  final int total;
  final int available;
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

String _roomStatus(Map<String, dynamic> room) {
  final tenantId = (room['tenantId'] ?? '').toString();
  final tenantName = (room['tenantName'] ?? '').toString();
  if (tenantId.isNotEmpty || tenantName.isNotEmpty) return 'occupied';
  final status = (room['status'] ?? 'available').toString();
  if (status == 'occupied') return 'occupied';
  return 'available';
}

String _text(Object? value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _readInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
