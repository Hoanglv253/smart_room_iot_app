import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../view_models/admin_room_management_view_model.dart';

class AdminRoomManagementScreen extends StatefulWidget {
  const AdminRoomManagementScreen({
    required this.buildingId,
    required this.building,
    this.canEditRoom = true,
    this.canManageTenant = true,
    super.key,
  });

  final String buildingId;
  final Map<String, dynamic> building;
  final bool canEditRoom;
  final bool canManageTenant;

  @override
  State<AdminRoomManagementScreen> createState() =>
      _AdminRoomManagementScreenState();
}

class _AdminRoomManagementScreenState extends State<AdminRoomManagementScreen> {
  final _searchController = TextEditingController();
  final _viewModel = AdminRoomManagementViewModel();
  int? _selectedFloor;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _viewModel.setQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildingName = (widget.building['name'] ?? 'Tòa nhà').toString();
    final totalRooms = (widget.building['totalRooms'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý phòng'),
        backgroundColor: AppColors.primary,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient()),
        ),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _viewModel.rooms(widget.buildingId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Không tải được danh sách phòng. Hãy kiểm tra quyền đọc buildings/{id}/rooms.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final sourceRooms = (snapshot.data?.docs ?? [])
                  .map((doc) => _RoomView.fromDoc(doc))
                  .where((room) => totalRooms <= 0 || room.number <= totalRooms)
                  .toList()
                ..sort((a, b) => a.number.compareTo(b.number));

              if ((snapshot.data?.docs ?? []).isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Chưa có phòng nào. Hãy vào Cài đặt và bấm Lưu thiết lập để tạo danh sách phòng.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final rooms = sourceRooms.where(_matchesFilters).toList();
              final floors = sourceRooms.map((room) => room.floor).toSet().toList()
                ..sort();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _RoomManagementHero(
                    buildingName: buildingName,
                    totalRooms: totalRooms > 0 ? totalRooms : sourceRooms.length,
                    rooms: sourceRooms,
                    canEditRoom: widget.canEditRoom,
                    onAddRoom: _showAddRoomHint,
                  ),
                  const SizedBox(height: 14),
                  _RoomSearchPanel(
                    controller: _searchController,
                    selectedStatus: _selectedStatus,
                    onStatusChanged: _selectStatus,
                  ),
                  const SizedBox(height: 14),
                  _FloorFilterBar(
                    floors: floors,
                    selectedFloor: _selectedFloor,
                    onFloorChanged: _selectFloor,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${rooms.length} phòng',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 10),
                  if (rooms.isEmpty)
                    const _EmptyRoomResult()
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 720 ? 3 : 2;
                        return GridView.builder(
                          itemCount: rooms.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 174,
                          ),
                          itemBuilder: (context, index) {
                            return _RoomGridTile(
                              room: rooms[index],
                              buildingId: widget.buildingId,
                              canEditRoom: widget.canEditRoom,
                              canManageTenant: widget.canManageTenant,
                            );
                          },
                        );
                      },
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  bool _matchesFilters(_RoomView room) {
    if (_selectedFloor != null && room.floor != _selectedFloor) return false;
    if (_selectedStatus != null && room.status != _selectedStatus) return false;
    return _matchesQuery(room);
  }

  bool _matchesQuery(_RoomView room) {
    final query = _viewModel.query;
    if (query.isEmpty) return true;
    return room.name.toLowerCase().contains(query) ||
        room.number.toString().contains(query) ||
        room.floor.toString().contains(query) ||
        room.statusLabel.toLowerCase().contains(query) ||
        (room.tenantName ?? '').toLowerCase().contains(query);
  }

  void _selectFloor(int? floor) {
    setState(() => _selectedFloor = floor);
  }

  void _selectStatus(String? status) {
    setState(() => _selectedStatus = status);
  }

  void _showAddRoomHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hãy vào Cài đặt tòa nhà và lưu thiết lập để tạo phòng.'),
      ),
    );
  }
}

class _RoomManagementHero extends StatelessWidget {
  const _RoomManagementHero({
    required this.buildingName,
    required this.totalRooms,
    required this.rooms,
    required this.canEditRoom,
    required this.onAddRoom,
  });

  final String buildingName;
  final int totalRooms;
  final List<_RoomView> rooms;
  final bool canEditRoom;
  final VoidCallback onAddRoom;

  @override
  Widget build(BuildContext context) {
    final available = rooms.where((room) => room.status == 'available').length;
    final occupied = rooms.where((room) => room.status == 'occupied').length;
    final maintenance = rooms
        .where((room) => room.status == 'maintenance')
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
            right: -30,
            top: -26,
            child: Icon(
              Icons.apartment_rounded,
              color: Colors.white.withValues(alpha: 0.10),
              size: 150,
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
                          totalRooms > 0
                              ? '$totalRooms phòng đã thiết lập'
                              : 'Chưa có tổng số phòng',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canEditRoom)
                    FilledButton.icon(
                      onPressed: onAddRoom,
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
                    child: _HeroMetric(
                      label: 'Trống',
                      value: available,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroMetric(
                      label: 'Đã thuê',
                      value: occupied,
                      color: const Color(0xFF93C5FD),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroMetric(
                      label: 'Bảo trì',
                      value: maintenance,
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

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
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

class _RoomSearchPanel extends StatelessWidget {
  const _RoomSearchPanel({
    required this.controller,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final TextEditingController controller;
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

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
              hintText: 'Tìm phòng, tầng, người thuê...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.tune_outlined),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusFilterChip(
                  label: 'Tất cả',
                  selected: selectedStatus == null,
                  onTap: () => onStatusChanged(null),
                ),
                _StatusFilterChip(
                  label: 'Trống',
                  selected: selectedStatus == 'available',
                  onTap: () => onStatusChanged('available'),
                ),
                _StatusFilterChip(
                  label: 'Đã thuê',
                  selected: selectedStatus == 'occupied',
                  onTap: () => onStatusChanged('occupied'),
                ),
                _StatusFilterChip(
                  label: 'Bảo trì',
                  selected: selectedStatus == 'maintenance',
                  onTap: () => onStatusChanged('maintenance'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
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

class _FloorFilterBar extends StatelessWidget {
  const _FloorFilterBar({
    required this.floors,
    required this.selectedFloor,
    required this.onFloorChanged,
  });

  final List<int> floors;
  final int? selectedFloor;
  final ValueChanged<int?> onFloorChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FloorPill(
            label: 'Tất cả',
            selected: selectedFloor == null,
            onTap: () => onFloorChanged(null),
          ),
          for (final floor in floors)
            _FloorPill(
              label: 'Tầng $floor',
              selected: selectedFloor == floor,
              onTap: () => onFloorChanged(floor),
            ),
        ],
      ),
    );
  }
}

class _FloorPill extends StatelessWidget {
  const _FloorPill({
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
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRoomResult extends StatelessWidget {
  const _EmptyRoomResult();

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
        'Không tìm thấy phòng phù hợp.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _RoomGridTile extends StatelessWidget {
  const _RoomGridTile({
    required this.room,
    required this.buildingId,
    required this.canEditRoom,
    required this.canManageTenant,
  });

  final _RoomView room;
  final String buildingId;
  final bool canEditRoom;
  final bool canManageTenant;

  @override
  Widget build(BuildContext context) {
    final statusColor = room.statusColor;
    final tenant = room.tenantName?.trim() ?? '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _RoomDetailScreen(
                buildingId: buildingId,
                room: room,
                canEditRoom: canEditRoom,
                canManageTenant: canManageTenant,
              ),
            ),
          );
        },
        child: Container(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 5, color: statusColor),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${room.number}',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                room.statusLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        room.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        tenant.isEmpty ? 'Chưa có người thuê' : tenant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: _RoomMiniMeta(
                              icon: Icons.payments_outlined,
                              label: room.rent > 0
                                  ? _roomMoney(room.rent)
                                  : 'Chưa đặt giá',
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 34,
                            child: _RoomMiniMeta(
                              icon: Icons.image_outlined,
                              label: '${room.imageCount}',
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.more_horiz,
                            color: AppColors.textSecondary,
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
      ),
    );
  }
}

class _RoomMiniMeta extends StatelessWidget {
  const _RoomMiniMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 15),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomDetailScreen extends StatefulWidget {
  const _RoomDetailScreen({
    required this.buildingId,
    required this.room,
    required this.canEditRoom,
    required this.canManageTenant,
  });

  final String buildingId;
  final _RoomView room;
  final bool canEditRoom;
  final bool canManageTenant;

  @override
  State<_RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<_RoomDetailScreen> {
  final _nameController = TextEditingController();
  final _floorController = TextEditingController();
  final _rentController = TextEditingController();
  final _areaController = TextEditingController();
  final _maxPeopleController = TextEditingController();
  final _typeController = TextEditingController();
  final _viewModel = RoomDetailViewModel();

  static const _statusOptions = [
    DropdownMenuItem(value: 'available', child: Text('Phòng trêng')),
    DropdownMenuItem(value: 'occupied', child: Text('Đã thuê')),
    DropdownMenuItem(value: 'maintenance', child: Text('Bảo trì')),
    DropdownMenuItem(value: 'reserved', child: Text('Đã đặt')),
  ];

  @override
  void initState() {
    super.initState();
    _loadRoom(widget.room);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _floorController.dispose();
    _rentController.dispose();
    _areaController.dispose();
    _maxPeopleController.dispose();
    _typeController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _loadRoom(_RoomView room) {
    _nameController.text = room.name;
    _floorController.text = room.floor.toString();
    _rentController.text = room.rent > 0 ? room.rent.toString() : '';
    _areaController.text = room.area > 0 ? room.area.toString() : '';
    _maxPeopleController.text =
        room.maxPeople > 0 ? room.maxPeople.toString() : '';
    _typeController.text = room.type == 'standard' ? '' : room.type;
    _viewModel.loadStatus(
      status: room.status,
      allowedStatuses: _statusOptions
          .map((item) => item.value)
          .whereType<String>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông tin phòng'),
        backgroundColor: AppColors.primary,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient()),
        ),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _viewModel.room(
              buildingId: widget.buildingId,
              roomId: widget.room.id,
            ),
            builder: (context, snapshot) {
              final room = snapshot.data?.exists == true
                  ? _RoomView.fromSnapshot(snapshot.data!)
                  : widget.room;

              return Stack(
                children: [
                  ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      widget.canEditRoom ? 116 : 24,
                    ),
                    children: [
                      _RoomProfileHeroCard(room: room),
                      const SizedBox(height: 14),
                      _RoomDetailSectionCard(
                        icon: Icons.info_outline,
                        title: 'Thông tin có ban',
                        child: Column(
                          children: [
                            _buildTextField(_nameController, 'Tên phòng'),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    _floorController,
                                    'Tầng',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    _areaController,
                                    'Diện tích (m2)',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            _buildTextField(
                              _rentController,
                              'Tiền thuê',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _RoomDetailSectionCard(
                        icon: Icons.tune_outlined,
                        title: 'Cấu hình phòng',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RoomStatusSelector(
                              value: _viewModel.status,
                              enabled: widget.canEditRoom,
                              onChanged: _viewModel.setStatus,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    _maxPeopleController,
                                    'Số người tối đa',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    _typeController,
                                    'Loại phòng',
                                    hintText: 'standard',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _TenantSummaryCard(
                        room: room,
                        canManageTenant: widget.canManageTenant,
                        isLoading: _viewModel.isLoading,
                        onChangeTenant: () => _showTenantPicker(room),
                        onRemoveTenant: () => _confirmRemoveTenant(room),
                      ),
                    ],
                  ),
                  if (widget.canEditRoom)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: SafeArea(
                        top: false,
                        child: _RoomSaveBar(
                          isLoading: _viewModel.isLoading,
                          onSave: () => _saveRoom(room),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: widget.canEditRoom,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
        ),
      ),
    );
  }

  Future<void> _saveRoom(_RoomView room) async {
    final roomName = _nameController.text.trim();
    if (roomName.isEmpty) {
      _showSnack('Hãy nhập tên phòng.');
      return;
    }

    final type = _typeController.text.trim().isEmpty
        ? 'standard'
        : _typeController.text.trim();

    final saved = await _viewModel.saveRoom(
      buildingId: widget.buildingId,
      roomId: room.id,
      roomName: roomName,
      roomNumber: room.number,
      floor: _readInt(_floorController),
      rent: _readInt(_rentController),
      area: _readInt(_areaController),
      maxPeople: _readInt(_maxPeopleController),
      type: type,
      status: _viewModel.status,
      tenantUserId: room.tenantId,
    );

    _showSnack(
      saved
          ? 'Đã lưu thông tin phòng.'
          : _roomActionErrorMessage(
              _viewModel.errorMessage,
              permissionMessage: 'Firestore chưa cấp quyền cập nhật phòng.',
              fallbackMessage: 'Không lưu được thông tin phòng.',
            ),
    );
  }

  void _showTenantPicker(_RoomView room) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return _TenantPickerSheet(
          buildingId: widget.buildingId,
          room: room,
        );
      },
    );
  }

  Future<void> _confirmRemoveTenant(_RoomView room) async {
    final tenantName = room.tenantName?.isNotEmpty == true
        ? room.tenantName!
        : 'người thuê';
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa người thuê khỏi phòng?'),
          content: Text('Bạn có chắc muốn xóa $tenantName khỏi ${room.name}?'),
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
      await _removeTenant(room);
    }
  }

  Future<void> _removeTenant(_RoomView room) async {
    final tenantId = room.tenantId;
    if (tenantId == null || tenantId.isEmpty) return;

    final removed = await _viewModel.removeTenant(
      buildingId: widget.buildingId,
      roomId: room.id,
      tenantId: tenantId,
    );

    _showSnack(
      removed
          ? 'Đã xóa người thuê khỏi ${room.name}.'
          : _roomActionErrorMessage(
              _viewModel.errorMessage,
              permissionMessage:
                  'Firestore chưa cấp quyền xóa người thuê khỏi phòng.',
              fallbackMessage: 'Không xóa được người thuê khỏi phòng.',
            ),
    );
  }

  int _readInt(TextEditingController controller) {
    final raw = controller.text.trim().replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(raw) ?? 0;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _roomActionErrorMessage(
    String? errorMessage, {
    required String permissionMessage,
    required String fallbackMessage,
  }) {
    if (errorMessage?.contains('permission-denied') == true) {
      return permissionMessage;
    }

    return fallbackMessage;
  }
}

class _RoomProfileHeroCard extends StatelessWidget {
  const _RoomProfileHeroCard({required this.room});

  final _RoomView room;

  @override
  Widget build(BuildContext context) {
    final tenant = room.tenantName?.trim() ?? '';

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
            right: -22,
            top: -26,
            child: Icon(
              Icons.meeting_room_rounded,
              color: Colors.white.withValues(alpha: 0.12),
              size: 132,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.door_front_door_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _RoomHeroChip(
                              icon: Icons.layers_outlined,
                              label: 'Tầng ${room.floor}',
                            ),
                            _RoomHeroChip(
                              icon: Icons.circle,
                              label: room.statusLabel,
                              dotColor: room.statusColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_outlined, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        room.rent > 0
                            ? '${_roomMoney(room.rent)}/tháng'
                            : 'Chưa đặt giá',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tenant.isEmpty ? 'Chưa có người thuê' : tenant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
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

class _RoomHeroChip extends StatelessWidget {
  const _RoomHeroChip({
    required this.icon,
    required this.label,
    this.dotColor,
  });

  final IconData icon;
  final String label;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dotColor == null ? 15 : 9, color: dotColor ?? Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomDetailSectionCard extends StatelessWidget {
  const _RoomDetailSectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 21),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
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

class _RoomStatusSelector extends StatelessWidget {
  const _RoomStatusSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('available', 'Trống', Color(0xFF16A34A)),
      ('occupied', 'Đã thuê', AppColors.primary),
      ('maintenance', 'Bảo trì', Color(0xFFF59E0B)),
      ('reserved', 'Đã đặt', Color(0xFFA855F7)),
    ];

    return Opacity(
      opacity: enabled ? 1 : 0.62,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            _RoomStatusChoice(
              label: item.$2,
              color: item.$3,
              selected: value == item.$1,
              enabled: enabled,
              onTap: () => onChanged(item.$1),
            ),
        ],
      ),
    );
  }
}

class _RoomStatusChoice extends StatelessWidget {
  const _RoomStatusChoice({
    required this.label,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? color.withValues(alpha: 0.36) : AppColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TenantSummaryCard extends StatelessWidget {
  const _TenantSummaryCard({
    required this.room,
    required this.canManageTenant,
    required this.isLoading,
    required this.onChangeTenant,
    required this.onRemoveTenant,
  });

  final _RoomView room;
  final bool canManageTenant;
  final bool isLoading;
  final VoidCallback onChangeTenant;
  final VoidCallback onRemoveTenant;

  @override
  Widget build(BuildContext context) {
    final tenantName = room.tenantName?.trim() ?? '';
    final tenantEmail = room.tenantEmail?.trim() ?? '';
    final hasTenant = tenantName.isNotEmpty || tenantEmail.isNotEmpty;
    final displayName = tenantName.isEmpty ? 'Chưa có người thuê' : tenantName;

    return _RoomDetailSectionCard(
      icon: Icons.person_outline,
      title: 'Người thuê',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: hasTenant ? AppColors.primarySoft : const Color(0xFFF1F5F9),
                child: Text(
                  _tenantInitials(displayName, tenantEmail),
                  style: TextStyle(
                    color: hasTenant ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tenantEmail.isEmpty ? 'Phòng hiện đang trống' : tenantEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canManageTenant) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onChangeTenant,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(hasTenant ? 'Đổi người thuê' : 'Thêm người thuê'),
              ),
            ),
            if (room.tenantId?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onRemoveTenant,
                  icon: const Icon(Icons.person_remove_outlined),
                  label: const Text('Xóa khỏi phòng'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  static String _tenantInitials(String name, String email) {
    final source = name.trim().isNotEmpty ? name.trim() : email.trim();
    if (source.isEmpty || source == 'Chưa có người thuê') return '?';
    final words = source.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    return words.take(2).map((word) => word[0]).join().toUpperCase();
  }
}

class _RoomSaveBar extends StatelessWidget {
  const _RoomSaveBar({required this.isLoading, required this.onSave});

  final bool isLoading;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isLoading ? null : onSave,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Lưu thay đổi'),
        ),
      ),
    );
  }
}

String _roomMoney(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return '$buffer VND';
}

class _RoomView {
  const _RoomView({
    required this.id,
    required this.number,
    required this.name,
    required this.floor,
    required this.rent,
    required this.status,
    required this.type,
    required this.area,
    required this.maxPeople,
    required this.imageCount,
    required this.tenantId,
    required this.tenantName,
    required this.tenantEmail,
  });

  factory _RoomView.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return _RoomView.fromMap(doc.id, doc.data());
  }

  factory _RoomView.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return _RoomView.fromMap(doc.id, doc.data() ?? {});
  }

  factory _RoomView.fromMap(String id, Map<String, dynamic> data) {
    final number = _readInt(data['roomNumber']);
    final tenantName = data['tenantName']?.toString();
    final hasTenant = (data['tenantId']?.toString().isNotEmpty ?? false) ||
        (tenantName?.isNotEmpty ?? false);

    return _RoomView(
      id: id,
      number: number,
      name: (data['name'] ?? 'Phòng ${number.toString().padLeft(3, '0')}')
          .toString(),
      floor: _readInt(data['floor'], fallback: 1),
      rent: _readInt(data['rent']),
      status: (data['status'] ?? (hasTenant ? 'occupied' : 'available'))
          .toString(),
      type: (data['type'] ?? 'standard').toString(),
      area: _readInt(data['area']),
      maxPeople: _readInt(data['maxPeople']),
      imageCount: _imageCount(data),
      tenantId: data['tenantId']?.toString(),
      tenantName: tenantName,
      tenantEmail: data['tenantEmail']?.toString(),
    );
  }

  final String id;
  final int number;
  final String name;
  final int floor;
  final int rent;
  final String status;
  final String type;
  final int area;
  final int maxPeople;
  final int imageCount;
  final String? tenantId;
  final String? tenantName;
  final String? tenantEmail;

  String get statusLabel {
    return switch (status) {
      'occupied' => 'Đã thuê',
      'maintenance' => 'Bảo trì',
      'reserved' => 'Đã đặt',
      _ => 'Phòng trêng',
    };
  }

  Color get statusColor {
    return switch (status) {
      'occupied' => AppColors.primary,
      'maintenance' => const Color(0xFFF59E0B),
      'reserved' => const Color(0xFFA855F7),
      _ => const Color(0xFF16A34A),
    };
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int _imageCount(Map<String, dynamic> data) {
    final urls = <String>{};
    for (final key in ['coverImageUrl', 'imageUrl', 'thumbnailUrl']) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) urls.add(value);
    }

    for (final key in ['images', 'imageUrls', 'roomImages', 'photoUrls']) {
      final value = data[key];
      if (value is Iterable) {
        for (final item in value) {
          final text = item?.toString().trim() ?? '';
          if (text.isNotEmpty) urls.add(text);
        }
      }
    }

    return urls.length;
  }
}

class _TenantPickerSheet extends StatefulWidget {
  const _TenantPickerSheet({
    required this.buildingId,
    required this.room,
  });

  final String buildingId;
  final _RoomView room;

  @override
  State<_TenantPickerSheet> createState() => _TenantPickerSheetState();
}

class _TenantPickerSheetState extends State<_TenantPickerSheet> {
  final _viewModel = TenantPickerViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.68,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thêm người thuê',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chọn tài khoản người thuê cho ${widget.room.name}.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _viewModel.buildingUsers(widget.buildingId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              'Không tải được danh sách người thuê trong tòa nhà.',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final tenants = (snapshot.data?.docs ?? [])
                            .where(_canAssignToRoom)
                            .toList();

                        if (tenants.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Chưa có người thuê nào đang trong tòa nhà và chưa có phòng.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: tenants.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final doc = tenants[index];
                            final data = doc.data();
                            final name = _displayName(data);
                            final email = (data['email'] ?? '').toString();
                            final isCurrentTenant =
                                doc.id == widget.room.tenantId;

                            return Card(
                              elevation: 1,
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(_initials(name, email)),
                                ),
                                title: Text(name),
                                subtitle: Text(
                                  email.isEmpty
                                      ? (isCurrentTenant
                                          ? 'Đang ở phòng này'
                                          : 'Chưa có phòng')
                                      : email,
                                ),
                                trailing: isCurrentTenant
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : const Icon(Icons.chevron_right),
                                enabled: !_viewModel.isLoading,
                                onTap: isCurrentTenant
                                    ? null
                                    : () => _assignTenant(doc),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _canAssignToRoom(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if ((data['role'] ?? UserRole.user) != UserRole.user) return false;
    if (doc.id == widget.room.tenantId) return true;

    final roomId = (data['roomId'] ?? '').toString();
    final roomNumber = data['roomNumber'];
    return roomId.isEmpty && roomNumber == null;
  }

  Future<void> _assignTenant(
    QueryDocumentSnapshot<Map<String, dynamic>> tenantDoc,
  ) async {
    final tenant = tenantDoc.data();
    final tenantName = _displayName(tenant);
    final tenantEmail = (tenant['email'] ?? '').toString();

    final assigned = await _viewModel.assignTenant(
      buildingId: widget.buildingId,
      roomId: widget.room.id,
      roomNumber: widget.room.number,
      roomName: widget.room.name,
      currentTenantId: widget.room.tenantId,
      tenantId: tenantDoc.id,
      tenantName: tenantName,
      tenantEmail: tenantEmail,
    );

    if (assigned) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm $tenantName vào ${widget.room.name}.')),
      );
      Navigator.of(context).pop();
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_assignTenantErrorMessage())),
    );
  }

  String _displayName(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['displayName'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    final email = (data['email'] ?? '').toString().trim();
    return email.isEmpty ? 'Người thuê' : email;
  }

  String _initials(String name, String email) {
    final source = name.trim().isNotEmpty ? name.trim() : email.trim();
    if (source.isEmpty) return '?';
    return source.substring(0, 1).toUpperCase();
  }

  String _assignTenantErrorMessage() {
    if (_viewModel.errorMessage?.contains('permission-denied') == true) {
      return 'Firestore chưa cấp quyền gan người thuê vào phòng.';
    }

    return 'Không thêm được người thuê.';
  }
}
