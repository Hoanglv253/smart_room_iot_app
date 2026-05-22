import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';

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
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildingName = (widget.building['name'] ?? 'Toa nha').toString();
    final totalRooms = (widget.building['totalRooms'] as num?)?.toInt() ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Quan ly toa nha')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  buildingName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalRooms > 0
                      ? '$totalRooms phong da thiet lap'
                      : 'Chua co tong so phong',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Tim theo ten phong, tang, trang thai...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: AppFirestoreService.buildingRooms(widget.buildingId)
                  .orderBy('roomNumber')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Khong tai duoc danh sach phong. Hay kiem tra quyen doc buildings/{id}/rooms.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rooms = (snapshot.data?.docs ?? [])
                    .map((doc) => _RoomView.fromDoc(doc))
                    .where((room) => totalRooms <= 0 || room.number <= totalRooms)
                    .where(_matchesQuery)
                    .toList();

                if ((snapshot.data?.docs ?? []).isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Chua co phong nao. Hay vao Cai dat va bam Luu thiet lap de tao danh sach phong.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (rooms.isEmpty) {
                  return const Center(
                    child: Text('Khong tim thay phong phu hop.'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.98,
                  ),
                  itemCount: rooms.length,
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
          ),
        ],
      ),
    );
  }

  bool _matchesQuery(_RoomView room) {
    if (_query.isEmpty) return true;
    return room.name.toLowerCase().contains(_query) ||
        room.number.toString().contains(_query) ||
        room.floor.toString().contains(_query) ||
        room.statusLabel.toLowerCase().contains(_query) ||
        (room.tenantName ?? '').toLowerCase().contains(_query);
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

    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.14),
                    child: Text(
                      '${room.number}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      room.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                room.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tang ${room.floor}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                room.rent > 0 ? '${room.rent} VND/thang' : 'Chua dat gia',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    room.tenantName?.isNotEmpty == true
                        ? room.tenantName!
                        : 'Chua co nguoi thue',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  String _status = 'available';
  bool _isSaving = false;

  static const _statusOptions = [
    DropdownMenuItem(value: 'available', child: Text('Phong trong')),
    DropdownMenuItem(value: 'occupied', child: Text('Da thue')),
    DropdownMenuItem(value: 'maintenance', child: Text('Bao tri')),
    DropdownMenuItem(value: 'reserved', child: Text('Da dat')),
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
    _status = _statusOptions.any((item) => item.value == room.status)
        ? room.status
        : 'available';
  }

  @override
  Widget build(BuildContext context) {
    final roomRef =
        AppFirestoreService.buildingRooms(widget.buildingId).doc(widget.room.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Thong tin phong')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: roomRef.snapshots(),
        builder: (context, snapshot) {
          final room = snapshot.data?.exists == true
              ? _RoomView.fromSnapshot(snapshot.data!)
              : widget.room;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RoomHeaderCard(room: room),
              const SizedBox(height: 16),
              _RoomEditSection(
                title: 'Thong tin phong',
                children: [
                  _buildTextField(_nameController, 'Ten phong'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _floorController,
                          'Tang',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _areaController,
                          'Dien tich (m2)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  _buildTextField(
                    _rentController,
                    'Tien thue',
                    keyboardType: TextInputType.number,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _maxPeopleController,
                          'So nguoi toi da',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _typeController,
                          'Loai phong',
                          hintText: 'standard',
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Trang thai',
                        border: OutlineInputBorder(),
                      ),
                      items: _statusOptions,
                      onChanged: widget.canEditRoom
                          ? (value) {
                              if (value != null) {
                                setState(() => _status = value);
                              }
                            }
                          : null,
                    ),
                  ),
                  if (widget.canEditRoom)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : () => _saveRoom(room),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Luu thong tin phong'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _RoomEditSection(
                title: 'Nguoi thue',
                children: [
                  _RoomInfoRow(
                    label: 'Ten',
                    value: room.tenantName?.isNotEmpty == true
                        ? room.tenantName!
                        : 'Chua co',
                  ),
                  if (room.tenantEmail?.isNotEmpty == true)
                    _RoomInfoRow(label: 'Email', value: room.tenantEmail!),
                  if (widget.canManageTenant) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _showTenantPicker(room),
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: Text(
                          room.tenantId?.isNotEmpty == true
                              ? 'Doi nguoi thue'
                              : 'Them nguoi thue',
                        ),
                      ),
                    ),
                    if (room.tenantId?.isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmRemoveTenant(room),
                          icon: const Icon(Icons.person_remove_outlined),
                          label: const Text('Xoa nguoi thue khoi phong'),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ],
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
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _saveRoom(_RoomView room) async {
    final roomName = _nameController.text.trim();
    if (roomName.isEmpty) {
      _showSnack('Hay nhap ten phong.');
      return;
    }

    setState(() => _isSaving = true);

    final tenantUserId = room.tenantId;
    final hasTenant = tenantUserId != null && tenantUserId.isNotEmpty;
    final statusToSave = hasTenant && _status == 'available'
        ? 'occupied'
        : _status;
    final type = _typeController.text.trim().isEmpty
        ? 'standard'
        : _typeController.text.trim();

    try {
      final batch = AppFirestoreService.db.batch();
      final roomRef =
          AppFirestoreService.buildingRooms(widget.buildingId).doc(room.id);

      batch.update(roomRef, {
        'name': roomName,
        'floor': _readInt(_floorController),
        'rent': _readInt(_rentController),
        'area': _readInt(_areaController),
        'maxPeople': _readInt(_maxPeopleController),
        'type': type,
        'status': statusToSave,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (hasTenant) {
        batch.update(AppFirestoreService.users.doc(tenantUserId), {
          'roomName': roomName,
          'roomNumber': room.number,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      _showSnack('Da luu thong tin phong.');
    } on FirebaseException catch (e) {
      _showSnack(
        e.code == 'permission-denied'
            ? 'Firestore chua cap quyen cap nhat phong.'
            : e.message ?? 'Khong luu duoc thong tin phong.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        : 'nguoi thue';
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xoa nguoi thue khoi phong?'),
          content: Text('Ban co chac muon xoa $tenantName khoi ${room.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Huy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xoa'),
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

    final roomRef = AppFirestoreService.buildingRooms(widget.buildingId)
        .doc(room.id);
    final tenantRef = AppFirestoreService.users.doc(tenantId);

    try {
      await AppFirestoreService.db.runTransaction((transaction) async {
        final tenantSnapshot = await transaction.get(tenantRef);

        transaction.update(roomRef, {
          'tenantId': FieldValue.delete(),
          'tenantName': FieldValue.delete(),
          'tenantEmail': FieldValue.delete(),
          'status': 'available',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (tenantSnapshot.exists) {
          transaction.update(tenantRef, {
            'roomId': FieldValue.delete(),
            'roomNumber': FieldValue.delete(),
            'roomName': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      _showSnack('Da xoa nguoi thue khoi ${room.name}.');
    } on FirebaseException catch (e) {
      _showSnack(
        e.code == 'permission-denied'
            ? 'Firestore chua cap quyen xoa nguoi thue khoi phong.'
            : e.message ?? 'Khong xoa duoc nguoi thue khoi phong.',
      );
    }
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
}

class _RoomHeaderCard extends StatelessWidget {
  const _RoomHeaderCard({required this.room});

  final _RoomView room;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: room.statusColor.withValues(alpha: 0.14),
              child: Icon(Icons.meeting_room_outlined, color: room.statusColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tang ${room.floor} - ${room.statusLabel}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomEditSection extends StatelessWidget {
  const _RoomEditSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _RoomInfoRow extends StatelessWidget {
  const _RoomInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
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
      name: (data['name'] ?? 'Phong ${number.toString().padLeft(3, '0')}')
          .toString(),
      floor: _readInt(data['floor'], fallback: 1),
      rent: _readInt(data['rent']),
      status: (data['status'] ?? (hasTenant ? 'occupied' : 'available'))
          .toString(),
      type: (data['type'] ?? 'standard').toString(),
      area: _readInt(data['area']),
      maxPeople: _readInt(data['maxPeople']),
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
  final String? tenantId;
  final String? tenantName;
  final String? tenantEmail;

  String get statusLabel {
    return switch (status) {
      'occupied' => 'Da thue',
      'maintenance' => 'Bao tri',
      'reserved' => 'Da dat',
      _ => 'Phong trong',
    };
  }

  Color get statusColor {
    return switch (status) {
      'occupied' => Colors.blueAccent,
      'maintenance' => Colors.orange,
      'reserved' => Colors.purple,
      _ => Colors.green,
    };
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
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
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
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
                'Them nguoi thue',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Chon tai khoan nguoi thue cho ${widget.room.name}.',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: AppFirestoreService.users
                      .where('buildingId', isEqualTo: widget.buildingId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Khong tai duoc danh sach nguoi thue trong toa nha.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final tenants = (snapshot.data?.docs ?? [])
                        .where(_canAssignToRoom)
                        .toList();

                    if (tenants.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Chua co nguoi thue nao dang trong toa nha va chua co phong.',
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
                        final isCurrentTenant = doc.id == widget.room.tenantId;

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
                                      ? 'Dang o phong nay'
                                      : 'Chua co phong')
                                  : email,
                            ),
                            trailing: isCurrentTenant
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : const Icon(Icons.chevron_right),
                            enabled: !_isSaving,
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
    setState(() => _isSaving = true);

    final tenant = tenantDoc.data();
    final tenantName = _displayName(tenant);
    final tenantEmail = (tenant['email'] ?? '').toString();
    final roomRef = AppFirestoreService.buildingRooms(widget.buildingId)
        .doc(widget.room.id);
    final tenantRef = AppFirestoreService.users.doc(tenantDoc.id);

    try {
      await AppFirestoreService.db.runTransaction((transaction) async {
        final roomSnapshot = await transaction.get(roomRef);
        final currentTenantId =
            roomSnapshot.data()?['tenantId']?.toString() ?? widget.room.tenantId;

        transaction.update(roomRef, {
          'tenantId': tenantDoc.id,
          'tenantName': tenantName,
          'tenantEmail': tenantEmail,
          'status': 'occupied',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (currentTenantId != null &&
            currentTenantId.isNotEmpty &&
            currentTenantId != tenantDoc.id) {
          transaction.update(AppFirestoreService.users.doc(currentTenantId), {
            'roomId': FieldValue.delete(),
            'roomNumber': FieldValue.delete(),
            'roomName': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        transaction.update(tenantRef, {
          'buildingId': widget.buildingId,
          'roomId': widget.room.id,
          'roomNumber': widget.room.number,
          'roomName': widget.room.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Da them $tenantName vao ${widget.room.name}.')),
      );
      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Firestore chua cap quyen gan nguoi thue vao phong.'
                : e.message ?? 'Khong them duoc nguoi thue.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _displayName(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['displayName'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    final email = (data['email'] ?? '').toString().trim();
    return email.isEmpty ? 'Nguoi thue' : email;
  }

  String _initials(String name, String email) {
    final source = name.trim().isNotEmpty ? name.trim() : email.trim();
    if (source.isEmpty) return '?';
    return source.substring(0, 1).toUpperCase();
  }
}
