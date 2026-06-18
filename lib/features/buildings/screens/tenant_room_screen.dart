import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/building_map_preview.dart';
import '../../notifications/models/app_notification.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../../notifications/screens/notifications_screen.dart';
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
            message: 'Không tải được thông tin tài khoản.',
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
            message: 'Bạn chưa tham gia tòa nhà nào.',
          );
        }

        if (roomId.isEmpty) {
          return const _RoomEmptyView(
            icon: Icons.meeting_room_outlined,
            message: 'Bạn đã tham gia tòa nhà, nhưng chưa được gắn phòng.',
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
            message: 'Không tìm thấy thông tin tòa nhà.',
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
                message: 'Không tìm thấy thông tin phòng.',
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
    final roomName = _text(room['name'], 'Phòng của tôi');
    final buildingName = _text(building['name'], 'Tòa nhà');
    final floor = _text(room['floor'], 'Chưa có');
    final type = _text(room['type'], 'standard');
    final maxPeople = _readInt(room['maxPeople']);
    final status = _statusLabel((room['status'] ?? 'occupied').toString());
    final statusColor = _statusColor(status);
    final rentText = rent > 0 ? '${_money(rent)}/tháng' : 'Chưa thiết lập';
    final maxPeopleText = maxPeople > 0 ? '$maxPeople người' : 'Chưa thiết lập';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        _TenantRoomHeroCard(
          roomName: roomName,
          buildingName: buildingName,
          floor: floor,
          status: status,
          statusColor: statusColor,
          rent: rentText,
          type: type,
          maxPeople: maxPeopleText,
          onTap: () => _openRoomInfo(context),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 126,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _TenantNotificationSummaryCard(
                  user: user,
                  buildingId: buildingId,
                  buildingName: buildingName,
                  roomId: roomId,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TenantMiniStatusCard(
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFFF59E0B),
                  title: 'Hóa đơn',
                  value: rent > 0 ? _money(rent) : 'Chưa có',
                  caption: 'Xem chi tiết',
                  onTap: () => _openInvoices(context),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _TenantMiniStatusCard(
                  icon: Icons.device_thermostat_outlined,
                  color: Color(0xFF0EA5E9),
                  title: 'Nhiệt độ',
                  value: '26.5°C',
                  caption: 'Độ ẩm 55%',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _TenantSectionHeader(
          title: 'Thao tác nhanh',
          subtitle: 'Những việc hay dùng được gom lại cho dễ bấm.',
        ),
        const SizedBox(height: 10),
        _TenantQuickActionGrid(
          actions: [
            _TenantQuickActionItem(
              icon: Icons.meeting_room_outlined,
              title: 'Xem phòng',
              subtitle: 'Thông tin và vị trí',
              color: AppColors.tenantAccent,
              onTap: () => _openRoomInfo(context),
            ),
            _TenantQuickActionItem(
              icon: Icons.payments_outlined,
              title: 'Thanh toán',
              subtitle: 'Hóa đơn của tôi',
              color: const Color(0xFFF59E0B),
              onTap: () => _openInvoices(context),
            ),
            _TenantQuickActionItem(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Nhắn quản lý',
              subtitle: 'Qua tab Tin nhắn',
              color: AppColors.primary,
              onTap: () => _showSnack(
                context,
                'Bạn có thể nhắn quản lý trong tab Tin nhắn.',
              ),
            ),
            _TenantQuickActionItem(
              icon: Icons.settings_input_component_outlined,
              title: 'Thiết bị',
              subtitle: 'Đèn, AC, khóa',
              color: const Color(0xFF16A34A),
              onTap: () => _showSnack(
                context,
                'Phần quản lý thiết bị sẽ được hoàn thiện sau.',
              ),
            ),
            _TenantQuickActionItem(
              icon: Icons.emergency_outlined,
              title: 'Khẩn cấp',
              subtitle: 'Liên hệ hỗ trợ',
              color: const Color(0xFFE11D48),
              isDanger: true,
              onTap: () => _showSnack(
                context,
                'Hãy gọi quản lý hoặc bảo vệ tòa nhà nếu cần hỗ trợ gấp.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openRoomInfo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _TenantRoomInfoScreen(
          user: user,
          buildingId: buildingId,
          roomId: roomId,
          building: building,
        ),
      ),
    );
  }

  void _openInvoices(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TenantInvoiceScreen(
          user: user,
          buildingId: buildingId,
          roomId: roomId,
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    if (value <= 0) return 'Chưa thiết lập';
    return '${_formatNumber(value)} VND';
  }

  static String _formatNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'occupied' => 'Đang ở',
      'maintenance' => 'Bảo trì',
      'reserved' => 'Đã đặt',
      _ => 'Phòng trống',
    };
  }

  static Color _statusColor(String statusLabel) {
    return switch (statusLabel) {
      'Đang ở' => const Color(0xFF16A34A),
      'Bảo trì' => const Color(0xFFF59E0B),
      'Đã đặt' => const Color(0xFF9333EA),
      _ => AppColors.primary,
    };
  }
}

class _TenantRoomInfoScreen extends StatefulWidget {
  const _TenantRoomInfoScreen({
    required this.user,
    required this.buildingId,
    required this.roomId,
    required this.building,
  });

  final User user;
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
      appBar: AppBar(
        title: const Text('Thông tin phòng'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _viewModel.room(
          buildingId: widget.buildingId,
          roomId: widget.roomId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _RoomEmptyView(
              icon: Icons.lock_outline,
              message: 'Không tải được thông tin phòng.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?.exists != true) {
            return const _RoomEmptyView(
              icon: Icons.meeting_room_outlined,
              message: 'Không tìm thấy phòng được gắn cho tài khoản này.',
            );
          }

          final room = snapshot.data!.data() ?? {};
          final roomName = _text(room['name'], 'Phòng của tôi');
          final roomNumber = _readInt(room['roomNumber']);
          final floor = _text(room['floor'], 'Chưa có');
          final area = _readInt(room['area']);
          final maxPeople = _readInt(room['maxPeople']);
          final roomRent = _readInt(room['rent']);
          final defaultRent = _readInt(widget.building['defaultRent']);
          final rent = roomRent > 0 ? roomRent : defaultRent;
          final type = _text(room['type'], 'standard');
          final status = _statusLabel(
            (room['status'] ?? 'occupied').toString(),
          );
          final tenantName = _text(room['tenantName'], 'Chưa có');
          final tenantEmail = _text(room['tenantEmail'], 'Chưa có email');
          final buildingName = _text(widget.building['name'], 'Tòa nhà');
          final buildingAddress =
              _text(widget.building['address'], 'Chưa có Địa chỉ');
          final roomNumberText =
              roomNumber > 0 ? '$roomNumber' : widget.roomId;
          final areaText = area > 0 ? '$area m2' : 'Chưa thiết lập';
          final maxPeopleText =
              maxPeople > 0 ? '$maxPeople người' : 'Chưa thiết lập';
          final rentText =
              rent > 0 ? '${_money(rent)}/tháng' : 'Chưa thiết lập';
          final roomImageUrl = _firstRoomImageUrl(room);
          final statusColor = _statusColor(status);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _RoomInfoHeroCard(
                roomName: roomName,
                buildingName: buildingName,
                floor: floor,
                status: status,
                statusColor: statusColor,
                rent: rentText,
                type: type,
                maxPeople: maxPeopleText,
                imageUrl: roomImageUrl,
              ),
              const SizedBox(height: 12),
              _RoomActionButtons(
                onViewInvoices: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TenantInvoiceScreen(
                        user: widget.user,
                        buildingId: widget.buildingId,
                        roomId: widget.roomId,
                      ),
                    ),
                  );
                },
                onMessageManager: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Bạn có thể nhắn quản lý trong tab Tin nhắn.',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _InfoSection(
                icon: Icons.meeting_room_outlined,
                title: 'Hồ sơ phòng',
                children: [
                  _InfoRow(label: 'Số phòng', value: roomNumberText),
                  _InfoRow(label: 'Tên phòng', value: roomName),
                  _InfoRow(label: 'Tầng', value: floor),
                  _InfoRow(label: 'Diện tích', value: areaText),
                  _InfoRow(label: 'Số người', value: maxPeopleText),
                  _InfoRow(label: 'Loại phòng', value: type),
                  _InfoRow(label: 'Trạng thái', value: status),
                ],
              ),
              const SizedBox(height: 14),
              _InfoSection(
                icon: Icons.payments_outlined,
                title: 'Chi phí hằng tháng',
                children: [
                  _InfoRow(label: 'Tiền thuê', value: rentText),
                  const _InfoNote(
                    text:
                        'Tiền điện, nước và dịch vụ sẽ được tính trong hóa đơn hằng tháng.',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoSection(
                icon: Icons.apartment_outlined,
                title: 'Tòa nhà',
                children: [
                  _InfoRow(label: 'Tên tòa nhà', value: buildingName),
                  _InfoRow(label: 'Địa chỉ', value: buildingAddress),
                ],
              ),
              const SizedBox(height: 14),
              _RoomMapPreviewCard(building: widget.building),
              const SizedBox(height: 14),
              _InfoSection(
                icon: Icons.person_outline,
                title: 'Người đang ở',
                children: [
                  _InfoRow(label: 'Tên', value: tenantName),
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
    if (value <= 0) return 'Chưa thiết lập';
    return '$value VND';
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'occupied' => 'Đang ở',
      'maintenance' => 'Bảo trì',
      'reserved' => 'Đã đặt',
      _ => 'Phòng trêng',
    };
  }

  static Color _statusColor(String statusLabel) {
    return switch (statusLabel) {
      'Đang ở' => const Color(0xFF16A34A),
      'Bảo trì' => const Color(0xFFF59E0B),
      'Đã đặt' => const Color(0xFF9333EA),
      _ => AppColors.primary,
    };
  }

  static String _firstRoomImageUrl(Map<String, dynamic> room) {
    for (final key in ['coverImageUrl', 'imageUrl', 'thumbnailUrl']) {
      final value = room[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    for (final key in ['images', 'imageUrls', 'roomImages', 'photoUrls']) {
      final value = room[key];
      if (value is Iterable) {
        for (final item in value) {
          final text = item?.toString().trim() ?? '';
          if (text.isNotEmpty) return text;
        }
      }
    }

    return '';
  }

}

class _RoomInfoHeroCard extends StatelessWidget {
  const _RoomInfoHeroCard({
    required this.roomName,
    required this.buildingName,
    required this.floor,
    required this.status,
    required this.statusColor,
    required this.rent,
    required this.type,
    required this.maxPeople,
    required this.imageUrl,
  });

  final String roomName;
  final String buildingName;
  final String floor;
  final String status;
  final Color statusColor;
  final String rent;
  final String type;
  final String maxPeople;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.door_front_door_outlined,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$buildingName - Tầng $floor',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _RoomStatusBadge(label: status, color: statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF8FBFF), Color(0xFFEFF6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Color(0xFFDCEBFF)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RoomPassChip(
                        icon: Icons.payments_outlined,
                        label: rent,
                        color: AppColors.primary,
                      ),
                      _RoomPassChip(
                        icon: Icons.king_bed_outlined,
                        label: type,
                        color: const Color(0xFF0EA5E9),
                      ),
                      _RoomPassChip(
                        icon: Icons.groups_2_outlined,
                        label: maxPeople,
                        color: const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _RoomPreviewTile(imageUrl: imageUrl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomStatusBadge extends StatelessWidget {
  const _RoomStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RoomPassChip extends StatelessWidget {
  const _RoomPassChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomPreviewTile extends StatelessWidget {
  const _RoomPreviewTile({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 88,
        height: 76,
        child: imageUrl.isEmpty
            ? Container(
                color: Colors.white,
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textSecondary,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _RoomActionButtons extends StatelessWidget {
  const _RoomActionButtons({
    required this.onViewInvoices,
    required this.onMessageManager,
  });

  final VoidCallback onViewInvoices;
  final VoidCallback onMessageManager;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onViewInvoices,
              icon: const Icon(Icons.receipt_long_outlined, size: 20),
              label: const Text('Xem hóa đơn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onMessageManager,
              icon: const Icon(Icons.chat_bubble_outline, size: 19),
              label: const Text('Nhắn quản lý'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _RoomMapPreviewCard extends StatelessWidget {
  const _RoomMapPreviewCard({required this.building});

  final Map<String, dynamic> building;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Vị trí tòa nhà',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BuildingMapPreview(building: building),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantRoomHeroCard extends StatelessWidget {
  const _TenantRoomHeroCard({
    required this.roomName,
    required this.buildingName,
    required this.floor,
    required this.status,
    required this.statusColor,
    required this.rent,
    required this.type,
    required this.maxPeople,
    required this.onTap,
  });

  final String roomName;
  final String buildingName;
  final String floor;
  final String status;
  final Color statusColor;
  final String rent;
  final String type;
  final String maxPeople;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2168F3), Color(0xFF6F58D9)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.tenantAccent.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -4,
                bottom: -18,
                child: Icon(
                  Icons.door_front_door_outlined,
                  size: 150,
                  color: Colors.white.withValues(alpha: 0.10),
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
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: const Icon(
                          Icons.meeting_room_outlined,
                          color: Colors.white,
                          size: 34,
                        ),
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
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '$buildingName - Tầng $floor',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TenantHeroStatusBadge(label: status, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      _TenantHeroChip(
                        icon: Icons.payments_outlined,
                        label: rent,
                      ),
                      _TenantHeroChip(icon: Icons.king_bed_outlined, label: type),
                      _TenantHeroChip(
                        icon: Icons.groups_2_outlined,
                        label: maxPeople,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TenantHeroStatusBadge extends StatelessWidget {
  const _TenantHeroStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantHeroChip extends StatelessWidget {
  const _TenantHeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantMiniStatusCard extends StatelessWidget {
  const _TenantMiniStatusCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.caption,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TenantNotificationSummaryCard extends StatelessWidget {
  const _TenantNotificationSummaryCard({
    required this.user,
    required this.buildingId,
    required this.buildingName,
    required this.roomId,
  });

  static final _repository = NotificationRepository();

  final User user;
  final String buildingId;
  final String buildingName;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _repository.buildingNotifications(buildingId),
      builder: (context, snapshot) {
        final hasError = snapshot.hasError;
        final items = (snapshot.data?.docs ?? [])
            .map(AppNotification.fromDoc)
            .where(
              (item) => item.visibleFor(
                userId: user.uid,
                role: UserRole.user,
                roomId: roomId,
              ),
            )
            .toList()
          ..sort((left, right) {
            final leftDate = left.createdDate;
            final rightDate = right.createdDate;
            if (leftDate == null && rightDate == null) return 0;
            if (leftDate == null) return 1;
            if (rightDate == null) return -1;
            return rightDate.compareTo(leftDate);
          });

        final unreadCount = items.where((item) => !item.isReadBy(user.uid)).length;
        final latest = items.isEmpty ? null : items.first;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return _TenantMiniStatusCard(
          icon: Icons.notifications_active_outlined,
          color: const Color(0xFFF97316),
          title: 'Thông báo',
          value: hasError
              ? 'Lỗi tải'
              : isLoading
                  ? 'Đang tải'
                  : unreadCount > 0
                      ? '$unreadCount mới'
                      : 'Không mới',
          caption: hasError
              ? 'Chạm để thử lại'
              : latest?.title ?? 'Xem tất cả',
          onTap: () => _openNotifications(context),
        );
      },
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          user: user,
          role: UserRole.user,
          buildingId: buildingId,
          buildingName: buildingName,
          roomId: roomId,
        ),
      ),
    );
  }
}

class _TenantSectionHeader extends StatelessWidget {
  const _TenantSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TenantQuickActionItem {
  const _TenantQuickActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDanger;
}

class _TenantQuickActionGrid extends StatelessWidget {
  const _TenantQuickActionGrid({required this.actions});

  final List<_TenantQuickActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final action in actions)
              SizedBox(
                width: itemWidth,
                child: _TenantQuickActionCard(action: action),
              ),
          ],
        );
      },
    );
  }
}

class _TenantQuickActionCard extends StatelessWidget {
  const _TenantQuickActionCard({required this.action});

  final _TenantQuickActionItem action;

  @override
  Widget build(BuildContext context) {
    final background = action.isDanger
        ? const Color(0xFFFFF1F2)
        : action.color.withValues(alpha: 0.08);
    final borderColor = action.isDanger
        ? const Color(0xFFFDA4AF)
        : action.color.withValues(alpha: 0.14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: action.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: action.color.withValues(alpha: action.isDanger ? 0.13 : 0.07),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(action.icon, color: action.color, size: 23),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: action.isDanger
                            ? const Color(0xFFE11D48)
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
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
