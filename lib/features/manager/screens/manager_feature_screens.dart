import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';

const Color _managerBlue = Color(0xFF1565C0);
const Color _managerBackground = Color(0xFFF3F5F8);

class ManagerTenantListScreen extends StatelessWidget {
  const ManagerTenantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _managerBackground,
      appBar: _managerAppBar('Người thuê'),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: AppFirestoreService.watchUsers(),
        builder: (context, snapshot) {
          final users = (snapshot.data?.docs ??
                  const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
              .map((doc) => AppUserRecord.fromFirestore(doc.id, doc.data()))
              .where((user) => user.role == 'user')
              .toList()
            ..sort((a, b) {
              final roomA = a.roomNumber ?? 9999;
              final roomB = b.roomNumber ?? 9999;
              if (roomA != roomB) return roomA.compareTo(roomB);
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (users.isEmpty) {
            return const _EmptyState(
              icon: Icons.people_outline,
              text: 'Chưa có tài khoản người thuê.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = users[index];
              final room = user.roomNumber == null
                  ? 'Chưa gán phòng'
                  : AppFirestoreService.roomName(user.roomNumber!);
              return _InfoCard(
                icon: Icons.person,
                title: user.name,
                subtitle: user.email,
                trailing: room,
                color:
                    user.roomNumber == null ? Colors.deepOrange : _managerBlue,
              );
            },
          );
        },
      ),
    );
  }
}

class ManagerRepairRequestScreen extends StatelessWidget {
  const ManagerRepairRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _managerBackground,
      appBar: _managerAppBar('Yêu cầu sửa chữa'),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: AppFirestoreService.notifications.snapshots(),
        builder: (context, snapshot) {
          final items = (snapshot.data?.docs ??
                  const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
              .map((doc) => _ManagerNotice.fromFirestore(doc.id, doc.data()))
              .where(
                (item) =>
                    item.type == 'report' ||
                    item.message.toLowerCase().contains('sửa') ||
                    item.message.toLowerCase().contains('báo cáo'),
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (items.isEmpty) {
            return const _EmptyState(
              icon: Icons.build_outlined,
              text: 'Chưa có yêu cầu sửa chữa hoặc báo cáo mới.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return _InfoCard(
                icon: Icons.build,
                title: item.senderName,
                subtitle: item.message,
                trailing: item.timeLabel,
                color: Colors.deepOrange,
              );
            },
          );
        },
      ),
    );
  }
}

class ManagerBillListScreen extends StatelessWidget {
  const ManagerBillListScreen({super.key});

  Future<void> _sendAllBills(
    BuildContext context,
    List<BillRecord> bills,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    var sent = 0;
    for (final bill in bills) {
      try {
        await sendBillNotification(bill);
        sent++;
      } catch (_) {
        // Keep sending remaining rooms; report summary after the loop.
      }
    }
    messenger.showSnackBar(
      SnackBar(content: Text('Đã gửi hóa đơn cho $sent/${bills.length} phòng.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _managerBackground,
      appBar: _managerAppBar('Hóa đơn điện nước'),
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
              final bills = <int, BillRecord>{};
              for (final doc in billSnapshot.data?.docs ??
                  const <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
                final bill = BillRecord.fromFirestore(doc.id, doc.data());
                bills[bill.roomNumber] = bill;
              }

              final occupiedRooms = users
                  .where((user) => user.roomNumber != null)
                  .map((user) => user.roomNumber!)
                  .toSet()
                  .toList()
                ..sort();

              final visibleBills = occupiedRooms
                  .map(
                    (roomNumber) =>
                        bills[roomNumber] ??
                        BillRecord.sampleForRoom(
                          roomNumber,
                          AppFirestoreService.currentMonthKey(),
                        ),
                  )
                  .toList();

              if (userSnapshot.connectionState == ConnectionState.waiting ||
                  billSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (visibleBills.isEmpty) {
                return const _EmptyState(
                  icon: Icons.receipt_long,
                  text: 'Chưa có phòng đang thuê để lập hóa đơn.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: visibleBills.length + 1,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final total = visibleBills.fold<int>(
                      0,
                      (sum, bill) => sum + bill.totalAmount,
                    );
                    return _BillSendAllCard(
                      roomCount: visibleBills.length,
                      total: total,
                      onSend: () => _sendAllBills(context, visibleBills),
                    );
                  }
                  return _BillCard(bill: visibleBills[index - 1]);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ManagerSettingsScreen extends StatelessWidget {
  const ManagerSettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _managerBackground,
      appBar: _managerAppBar('Cài đặt quản lý'),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _SettingsTile(
            icon: Icons.notifications,
            title: 'Thông báo',
            subtitle: 'Nhận thông báo từ admin và người thuê.',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.receipt_long,
            title: 'Hóa đơn',
            subtitle: 'Theo dõi và gửi hóa đơn điện nước theo phòng.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ManagerBillListScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Đăng xuất',
            subtitle: 'Thoát khỏi tài khoản quản lý.',
            color: Colors.redAccent,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class _BillSendAllCard extends StatelessWidget {
  const _BillSendAllCard({
    required this.roomCount,
    required this.total,
    required this.onSend,
  });

  final int roomCount;
  final int total;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _managerBlue.withValues(alpha: 0.12),
            child: const Icon(Icons.campaign, color: _managerBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gửi hóa đơn tháng này',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '$roomCount phòng đang thuê • Tổng ${_formatMoney(total)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onSend,
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Gửi tất cả'),
          ),
        ],
      ),
    );
  }
}

class _BillCard extends StatefulWidget {
  const _BillCard({required this.bill});

  final BillRecord bill;

  @override
  State<_BillCard> createState() => _BillCardState();
}

class _BillCardState extends State<_BillCard> {
  bool _saving = false;
  bool _sending = false;

  Future<void> _togglePaid() async {
    setState(() => _saving = true);
    final nextStatus = widget.bill.status == 'paid' ? 'unpaid' : 'paid';
    try {
      await AppFirestoreService.upsertBill(
        widget.bill.copyWith(status: nextStatus),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextStatus == 'paid'
                ? 'Đã đánh dấu hóa đơn là đã thanh toán.'
                : 'Đã chuyển hóa đơn về chưa thanh toán.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không cập nhật được hóa đơn: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendBill() async {
    setState(() => _sending = true);
    try {
      await sendBillNotification(widget.bill);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã gửi hóa đơn ${AppFirestoreService.roomName(widget.bill.roomNumber)}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi hóa đơn thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    final paid = bill.status == 'paid';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _managerBlue.withValues(alpha: 0.12),
                child: const Icon(Icons.receipt_long, color: _managerBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppFirestoreService.roomName(bill.roomNumber),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Tháng ${bill.monthKey}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                text: paid ? 'Đã thu' : 'Chưa thu',
                color: paid ? const Color(0xFF149447) : Colors.deepOrange,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MoneyLine(label: 'Tiền điện', value: bill.electricAmount),
          _MoneyLine(label: 'Tiền nước', value: bill.waterAmount),
          _MoneyLine(label: 'Tiền phòng', value: bill.roomAmount),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tổng: ${_formatMoney(bill.totalAmount)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _sending ? null : _sendBill,
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Gửi'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _saving ? null : _togglePaid,
                child: Text(paid ? 'Bỏ thu' : 'Đã thu'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = _managerBlue,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
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
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black38, size: 44),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagerNotice {
  const _ManagerNotice({
    required this.id,
    required this.message,
    required this.type,
    required this.senderName,
    required this.createdAt,
  });

  final String id;
  final String message;
  final String type;
  final String senderName;
  final DateTime createdAt;

  factory _ManagerNotice.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'];
    return _ManagerNotice(
      id: id,
      message: (data['message'] ?? '').toString(),
      type: (data['type'] ?? '').toString(),
      senderName:
          (data['senderName'] ?? data['senderEmail'] ?? 'Người thuê').toString(),
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String get timeLabel {
    if (createdAt.millisecondsSinceEpoch == 0) return 'Mới';
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Text(
            _formatMoney(value),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Future<void> sendBillNotification(BillRecord bill) async {
  final user = FirebaseAuth.instance.currentUser;
  final roomName = AppFirestoreService.roomName(bill.roomNumber);
  final message =
      'Hóa đơn tháng ${bill.monthKey} của $roomName: tổng tiền phải trả ${_formatMoney(bill.totalAmount)}. '
      'Chi tiết: điện ${_formatMoney(bill.electricAmount)}, nước ${_formatMoney(bill.waterAmount)}, phòng ${_formatMoney(bill.roomAmount)}.';
  final doc = AppFirestoreService.notifications.doc();
  await doc.set({
    'id': doc.id,
    'message': message,
    'senderRole': 'manager',
    'senderName': user?.displayName ?? user?.email ?? 'Quản lý',
    'senderEmail': user?.email ?? '',
    'senderUid': user?.uid ?? '',
    'targetRoles': const ['user'],
    'targetRoomNumber': bill.roomNumber,
    'roomNumber': bill.roomNumber,
    'roomName': roomName,
    'billId': bill.id,
    'amount': bill.totalAmount,
    'type': 'bill',
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
  }).timeout(const Duration(seconds: 10));
}

PreferredSizeWidget _managerAppBar(String title) {
  return AppBar(
    backgroundColor: _managerBlue,
    foregroundColor: Colors.white,
    title: Text(title),
  );
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
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return '${buffer.toString()} đ';
}
