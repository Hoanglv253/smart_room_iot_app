import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/building_map_preview.dart';
import '../view_models/tenant_room_view_model.dart';
import 'tenant_invoice_screen.dart';

class TenantRoomScreen extends StatefulWidget {
  const TenantRoomScreen({required this.user, super.key});

  final User user;

  @override
  State<TenantRoomScreen> createState() => _TenantRoomScreenState();
}

class _TenantRoomScreenState extends State<TenantRoomScreen> {
  final _viewModel = TenantRoomViewModel();

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
        if (userSnapshot.hasError) {
          return const _RoomEmptyView(
            icon: Icons.lock_outline,
            message: 'Khong tai duoc thong tin tai khoan.',
          );
        }

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = userSnapshot.data?.data() ?? {};
        final buildingId = (profile['buildingId'] ?? '').toString();
        final roomId = (profile['roomId'] ?? '').toString();

        if (buildingId.isEmpty) {
          return const _RoomEmptyView(
            icon: Icons.apartment_outlined,
            message: 'Ban chua tham gia toa nha nao.',
          );
        }

        if (roomId.isEmpty) {
          return const _RoomEmptyView(
            icon: Icons.meeting_room_outlined,
            message: 'Ban da tham gia toa nha, nhung chua duoc gan phong.',
          );
        }

        return _TenantRoomDetail(
          user: widget.user,
          buildingId: buildingId,
          roomId: roomId,
          viewModel: _viewModel,
        );
      },
    );
  }
}

class _TenantRoomDetail extends StatelessWidget {
  const _TenantRoomDetail({
    required this.user,
    required this.buildingId,
    required this.roomId,
    required this.viewModel,
  });

  final User user;
  final String buildingId;
  final String roomId;
  final TenantRoomViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: viewModel.building(buildingId),
      builder: (context, buildingSnapshot) {
        if (buildingSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (buildingSnapshot.hasError ||
            buildingSnapshot.data?.exists != true) {
          return const _RoomEmptyView(
            icon: Icons.apartment_outlined,
            message: 'Khong tim thay thong tin toa nha.',
          );
        }

        final building = buildingSnapshot.data!.data() ?? {};

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: viewModel.room(buildingId: buildingId, roomId: roomId),
          builder: (context, roomSnapshot) {
            if (roomSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (roomSnapshot.hasError || roomSnapshot.data?.exists != true) {
              return const _RoomEmptyView(
                icon: Icons.meeting_room_outlined,
                message: 'Khong tim thay thong tin phong.',
              );
            }

            final room = roomSnapshot.data!.data() ?? {};
            return _RoomDashboard(
              user: user,
              buildingId: buildingId,
              roomId: roomId,
              building: building,
              room: room,
            );
          },
        );
      },
    );
  }
}

class _RoomDashboard extends StatelessWidget {
  const _RoomDashboard({
    required this.user,
    required this.buildingId,
    required this.roomId,
    required this.building,
    required this.room,
  });

  final User user;
  final String buildingId;
  final String roomId;
  final Map<String, dynamic> building;
  final Map<String, dynamic> room;

  @override
  Widget build(BuildContext context) {
    final roomRent = _readInt(room['rent']);
    final defaultRent = _readInt(building['defaultRent']);
    final rent = roomRent > 0 ? roomRent : defaultRent;
    final roomName = _text(room['name'], 'Phong cua toi');
    final floor = _text(room['floor'], 'Chua co');
    final status = _statusLabel((room['status'] ?? 'occupied').toString());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Nhiet do phong',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Thong bao',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 190,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(child: _TemperaturePanel()),
              SizedBox(width: 14),
              Expanded(child: _NotificationPanel()),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.05,
          children: [
            _DashboardTile(
              icon: Icons.apartment_outlined,
              iconColor: const Color(0xFF2563EB),
              title: roomName.toUpperCase(),
              subtitle: 'Tang $floor - $status',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _TenantRoomInfoScreen(
                      buildingId: buildingId,
                      roomId: roomId,
                      building: building,
                    ),
                  ),
                );
              },
            ),
            _DashboardTile(
              icon: Icons.receipt_long_outlined,
              iconColor: const Color(0xFFF59E0B),
              title: 'THANH TOAN',
              subtitle:
                  rent > 0 ? 'Tien phong: ${_money(rent)}' : 'Chua co hoa don',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TenantInvoiceScreen(
                      user: user,
                      buildingId: buildingId,
                      roomId: roomId,
                    ),
                  ),
                );
              },
            ),
            const _DashboardTile(
              icon: Icons.settings_input_component_outlined,
              iconColor: Color(0xFF16A34A),
              title: 'QUAN LY T.BI',
              subtitle: 'Den, AC, khoa thong minh',
            ),
            const _EmergencyTile(),
          ],
        ),
      ],
    );
  }

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _money(int value) {
    if (value <= 0) return 'Chua thiet lap';
    return '$value VND';
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'occupied' => 'Dang o',
      'maintenance' => 'Bao tri',
      'reserved' => 'Da dat',
      _ => 'Phong trong',
    };
  }
}

class _TenantRoomInfoScreen extends StatefulWidget {
  const _TenantRoomInfoScreen({
    required this.buildingId,
    required this.roomId,
    required this.building,
  });

  final String buildingId;
  final String roomId;
  final Map<String, dynamic> building;

  @override
  State<_TenantRoomInfoScreen> createState() => _TenantRoomInfoScreenState();
}

class _TenantRoomInfoScreenState extends State<_TenantRoomInfoScreen> {
  final _viewModel = TenantRoomViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thong tin phong')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _viewModel.room(
          buildingId: widget.buildingId,
          roomId: widget.roomId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _RoomEmptyView(
              icon: Icons.lock_outline,
              message: 'Khong tai duoc thong tin phong.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?.exists != true) {
            return const _RoomEmptyView(
              icon: Icons.meeting_room_outlined,
              message: 'Khong tim thay phong duoc gan cho tai khoan nay.',
            );
          }

          final room = snapshot.data!.data() ?? {};
          final roomName = _text(room['name'], 'Phong cua toi');
          final roomNumber = _readInt(room['roomNumber']);
          final floor = _text(room['floor'], 'Chua co');
          final area = _readInt(room['area']);
          final maxPeople = _readInt(room['maxPeople']);
          final roomRent = _readInt(room['rent']);
          final defaultRent = _readInt(widget.building['defaultRent']);
          final rent = roomRent > 0 ? roomRent : defaultRent;
          final type = _text(room['type'], 'standard');
          final status = _statusLabel(
            (room['status'] ?? 'occupied').toString(),
          );
          final tenantName = _text(room['tenantName'], 'Chua co');
          final tenantEmail = _text(room['tenantEmail'], 'Chua co email');
          final buildingName = _text(widget.building['name'], 'Toa nha');
          final buildingAddress =
              _text(widget.building['address'], 'Chua co dia chi');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RoomInfoHeader(
                roomName: roomName,
                buildingName: buildingName,
                status: status,
              ),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Thong tin phong',
                children: [
                  _InfoRow(
                    label: 'So phong',
                    value: roomNumber > 0 ? '$roomNumber' : widget.roomId,
                  ),
                  _InfoRow(label: 'Ten phong', value: roomName),
                  _InfoRow(label: 'Tang', value: floor),
                  _InfoRow(
                    label: 'Dien tich',
                    value: area > 0 ? '$area m2' : 'Chua thiet lap',
                  ),
                  _InfoRow(
                    label: 'So nguoi toi da',
                    value: maxPeople > 0
                        ? '$maxPeople nguoi'
                        : 'Chua thiet lap',
                  ),
                  _InfoRow(label: 'Loai phong', value: type),
                  _InfoRow(label: 'Trang thai', value: status),
                ],
              ),
              const SizedBox(height: 12),
              _InfoSection(
                title: 'Chi phi',
                children: [
                  _InfoRow(
                    label: 'Tien thue',
                    value: rent > 0
                        ? '${_money(rent)}/thang'
                        : 'Chua thiet lap',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoSection(
                title: 'Toa nha',
                children: [
                  _InfoRow(label: 'Ten toa nha', value: buildingName),
                  _InfoRow(label: 'Dia chi', value: buildingAddress),
                ],
              ),
              const SizedBox(height: 12),
              BuildingMapPreview(building: widget.building),
              const SizedBox(height: 12),
              _InfoSection(
                title: 'Nguoi dang o',
                children: [
                  _InfoRow(label: 'Ten', value: tenantName),
                  _InfoRow(label: 'Email', value: tenantEmail),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _money(int value) {
    if (value <= 0) return 'Chua thiet lap';
    return '$value VND';
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'occupied' => 'Dang o',
      'maintenance' => 'Bao tri',
      'reserved' => 'Da dat',
      _ => 'Phong trong',
    };
  }

}

class _RoomInfoHeader extends StatelessWidget {
  const _RoomInfoHeader({
    required this.roomName,
    required this.buildingName,
    required this.status,
  });

  final String roomName;
  final String buildingName;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFE0F2FE),
              child: Icon(Icons.meeting_room_outlined, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roomName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$buildingName - $status',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _InfoSection extends StatelessWidget {
  const _InfoSection({
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
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

class _TemperaturePanel extends StatelessWidget {
  const _TemperaturePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.topRight,
            child: Icon(Icons.wb_sunny_outlined, color: Color(0xFFEAB308)),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(text: '26.5', style: TextStyle(fontSize: 56)),
                  TextSpan(text: ' C', style: TextStyle(fontSize: 22)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Do am: 55%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'AC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THONG BAO',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          _NotificationLine(title: 'Thong bao tu toa nha'),
          Divider(height: 16),
          _NotificationLine(title: 'Hoa don se hien thi tai day'),
          Divider(height: 16),
          _NotificationLine(title: 'Tin nhan tu quan ly'),
        ],
      ),
    );
  }
}

class _NotificationLine extends StatelessWidget {
  const _NotificationLine({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Moi cap nhat',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
          ),
          child: const Text(
            '1',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: iconColor),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyTile extends StatelessWidget {
  const _EmergencyTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emergency_outlined, size: 46, color: Colors.white),
          SizedBox(height: 12),
          Text(
            'KHAN CAP',
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Lien he ho tro',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _RoomEmptyView extends StatelessWidget {
  const _RoomEmptyView({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
