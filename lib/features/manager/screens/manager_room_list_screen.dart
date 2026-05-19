import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../admin/models/admin_profile_data.dart';

class ManagerRoomListScreen extends StatefulWidget {
  const ManagerRoomListScreen({super.key});

  @override
  State<ManagerRoomListScreen> createState() => _ManagerRoomListScreenState();
}

class _ManagerRoomListScreenState extends State<ManagerRoomListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _background = Color(0xFFF3F5F8);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        title: const Text('Quản lý phòng'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: AppFirestoreService.watchUsers(),
        builder: (context, userSnapshot) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: AppFirestoreService.watchCurrentBills(),
            builder: (context, billSnapshot) {
              final users = (userSnapshot.data?.docs ??
                      const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                  .map((doc) => AppUserRecord.fromFirestore(doc.id, doc.data()))
                  .toList();
              final billByRoom = <int, BillRecord>{};

              for (final doc in billSnapshot.data?.docs ??
                  const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
                final bill = BillRecord.fromFirestore(doc.id, doc.data());
                billByRoom[bill.roomNumber] = bill;
              }

              final rooms = _buildRooms(users: users, billByRoom: billByRoom)
                  .where((room) {
                final text = _keyword.trim().toLowerCase();
                if (text.isEmpty) return true;
                return room.name.toLowerCase().contains(text) ||
                    room.statusLabel.toLowerCase().contains(text) ||
                    room.tenantSummary.toLowerCase().contains(text);
              }).toList();

              final occupiedCount =
                  rooms.where((room) => room.isOccupied).length;
              final emptyCount = rooms.length - occupiedCount;
              final loading =
                  userSnapshot.connectionState == ConnectionState.waiting ||
                      billSnapshot.connectionState == ConnectionState.waiting;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _keyword = value),
                          decoration: InputDecoration(
                            hintText:
                                'Tìm theo số phòng, trạng thái, người thuê...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _keyword.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _keyword = '');
                                    },
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _RoomSummaryChip(
                                label: 'Tất cả',
                                value: '${rooms.length}',
                                color: _primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _RoomSummaryChip(
                                label: 'Đang thuê',
                                value: '$occupiedCount',
                                color: const Color(0xFF149447),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _RoomSummaryChip(
                                label: 'Còn trống',
                                value: '$emptyCount',
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (loading)
                    const LinearProgressIndicator(minHeight: 2)
                  else
                    const SizedBox(height: 2),
                  Expanded(
                    child: rooms.isEmpty
                        ? const Center(
                            child: Text('Không tìm thấy phòng phù hợp.'),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
                            itemCount: rooms.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final room = rooms[index];
                              return _ManagerRoomCard(
                                room: room,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          _ManagerRoomBillScreen(room: room),
                                    ),
                                  );
                                },
                              );
                            },
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

  List<_ManagerRoomInfo> _buildRooms({
    required List<AppUserRecord> users,
    required Map<int, BillRecord> billByRoom,
  }) {
    return List.generate(AdminProfileData.roomCount, (index) {
      final number = index + 1;
      final members = users.where((user) => user.roomNumber == number).toList();
      return _ManagerRoomInfo(
        number: number,
        name: AppFirestoreService.roomName(number),
        members: members,
        bill: billByRoom[number] ??
            BillRecord.sampleForRoom(
              number,
              AppFirestoreService.currentMonthKey(),
            ),
      );
    });
  }
}

class _ManagerRoomBillScreen extends StatelessWidget {
  const _ManagerRoomBillScreen({required this.room});

  final _ManagerRoomInfo room;

  static const Color _primaryBlue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    final bill = room.bill;
    final payableAmount = room.isOccupied ? bill.totalAmount : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        title: Text(room.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: room.statusColor.withValues(alpha: 0.12),
                  child: Icon(Icons.meeting_room, color: room.statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.statusLabel,
                        style: TextStyle(
                          color: room.statusColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        room.tenantSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _BillLine(
            icon: Icons.electric_bolt,
            title: 'Tiền điện tháng này',
            subtitle: '${bill.electricKwh.toStringAsFixed(1)} kWh',
            amount: room.isOccupied ? bill.electricAmount : 0,
            color: Colors.amber.shade800,
          ),
          _BillLine(
            icon: Icons.water_drop,
            title: 'Tiền nước tháng này',
            subtitle: '${bill.waterM3.toStringAsFixed(1)} m3',
            amount: room.isOccupied ? bill.waterAmount : 0,
            color: Colors.lightBlue.shade700,
          ),
          _BillLine(
            icon: Icons.home_work,
            title: 'Tiền phòng tháng này',
            subtitle: room.isOccupied ? 'Đang tính tiền thuê' : 'Phòng trống',
            amount: room.isOccupied ? bill.roomAmount : 0,
            color: _primaryBlue,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: _primaryBlue, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tổng tiền tháng này',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  _formatMoney(payableAmount),
                  style: const TextStyle(
                    color: _primaryBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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

class _ManagerRoomCard extends StatelessWidget {
  const _ManagerRoomCard({required this.room, required this.onTap});

  final _ManagerRoomInfo room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final payableAmount = room.isOccupied ? room.bill.totalAmount : 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: room.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.meeting_room, color: room.statusColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      room.tenantSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: room.statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      room.statusLabel,
                      style: TextStyle(
                        color: room.statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatMoney(payableAmount),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomSummaryChip extends StatelessWidget {
  const _RoomSummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _BillLine extends StatelessWidget {
  const _BillLine({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            _formatMoney(amount),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ManagerRoomInfo {
  const _ManagerRoomInfo({
    required this.number,
    required this.name,
    required this.members,
    required this.bill,
  });

  final int number;
  final String name;
  final List<AppUserRecord> members;
  final BillRecord bill;

  bool get isOccupied => members.isNotEmpty;

  String get statusLabel => isOccupied ? 'Đang thuê' : 'Còn trống';

  Color get statusColor =>
      isOccupied ? const Color(0xFF149447) : Colors.deepOrange;

  String get tenantSummary {
    if (members.isEmpty) return 'Chưa có người thuê';
    if (members.length == 1) return members.first.name;
    return '${members.first.name} và ${members.length - 1} thành viên khác';
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
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
  );
}

String _formatMoney(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${buffer.toString()} đ';
}
