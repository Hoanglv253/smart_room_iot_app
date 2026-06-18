import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'admin_settings_widgets.dart';

class AdminAccessDisplaySettingsScreen extends StatefulWidget {
  const AdminAccessDisplaySettingsScreen({
    required this.wifi,
    required this.elevator,
    required this.camera,
    required this.parking,
    required this.laundry,
    required this.security,
    required this.isPublic,
    required this.allowPreJoinMessage,
    required this.allowTenantJoinRequest,
    required this.allowManagerApplication,
    required this.requireApproval,
    required this.autoJoinGroupChat,
    required this.showAddress,
    required this.showRoomPrice,
    required this.showAvailableRooms,
    required this.onWifiChanged,
    required this.onElevatorChanged,
    required this.onCameraChanged,
    required this.onParkingChanged,
    required this.onLaundryChanged,
    required this.onSecurityChanged,
    required this.onPublicChanged,
    required this.onAllowPreJoinMessageChanged,
    required this.onAllowTenantJoinRequestChanged,
    required this.onAllowManagerApplicationChanged,
    required this.onRequireApprovalChanged,
    required this.onAutoJoinGroupChatChanged,
    required this.onShowAddressChanged,
    required this.onShowRoomPriceChanged,
    required this.onShowAvailableRoomsChanged,
    required this.onSave,
    super.key,
  });

  final bool wifi;
  final bool elevator;
  final bool camera;
  final bool parking;
  final bool laundry;
  final bool security;
  final bool isPublic;
  final bool allowPreJoinMessage;
  final bool allowTenantJoinRequest;
  final bool allowManagerApplication;
  final bool requireApproval;
  final bool autoJoinGroupChat;
  final bool showAddress;
  final bool showRoomPrice;
  final bool showAvailableRooms;
  final ValueChanged<bool> onWifiChanged;
  final ValueChanged<bool> onElevatorChanged;
  final ValueChanged<bool> onCameraChanged;
  final ValueChanged<bool> onParkingChanged;
  final ValueChanged<bool> onLaundryChanged;
  final ValueChanged<bool> onSecurityChanged;
  final ValueChanged<bool> onPublicChanged;
  final ValueChanged<bool> onAllowPreJoinMessageChanged;
  final ValueChanged<bool> onAllowTenantJoinRequestChanged;
  final ValueChanged<bool> onAllowManagerApplicationChanged;
  final ValueChanged<bool> onRequireApprovalChanged;
  final ValueChanged<bool> onAutoJoinGroupChatChanged;
  final ValueChanged<bool> onShowAddressChanged;
  final ValueChanged<bool> onShowRoomPriceChanged;
  final ValueChanged<bool> onShowAvailableRoomsChanged;
  final Future<void> Function() onSave;

  @override
  State<AdminAccessDisplaySettingsScreen> createState() =>
      _AdminAccessDisplaySettingsScreenState();
}

class _AdminAccessDisplaySettingsScreenState
    extends State<AdminAccessDisplaySettingsScreen> {
  late bool _wifi;
  late bool _elevator;
  late bool _camera;
  late bool _parking;
  late bool _laundry;
  late bool _security;
  late bool _isPublic;
  late bool _allowPreJoinMessage;
  late bool _allowTenantJoinRequest;
  late bool _allowManagerApplication;
  late bool _requireApproval;
  late bool _autoJoinGroupChat;
  late bool _showAddress;
  late bool _showRoomPrice;
  late bool _showAvailableRooms;

  @override
  void initState() {
    super.initState();
    _wifi = widget.wifi;
    _elevator = widget.elevator;
    _camera = widget.camera;
    _parking = widget.parking;
    _laundry = widget.laundry;
    _security = widget.security;
    _isPublic = widget.isPublic;
    _allowPreJoinMessage = widget.allowPreJoinMessage;
    _allowTenantJoinRequest = widget.allowTenantJoinRequest;
    _allowManagerApplication = widget.allowManagerApplication;
    _requireApproval = widget.requireApproval;
    _autoJoinGroupChat = widget.autoJoinGroupChat;
    _showAddress = widget.showAddress;
    _showRoomPrice = widget.showRoomPrice;
    _showAvailableRooms = widget.showAvailableRooms;
  }

  @override
  Widget build(BuildContext context) {
    final enabledAmenities = [
      _wifi,
      _elevator,
      _camera,
      _parking,
      _laundry,
      _security,
    ].where((value) => value).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Tiện ích và quyền',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminSettingsHeroCard(
            icon: Icons.tune_outlined,
            title: '$enabledAmenities tiện ích đang bật',
            subtitle:
                'Kiểm soat tiện ích, quyền xin vào và nội dung hiển trên Trang chủ.',
            color: const Color(0xFF0EA5E9),
            metrics: [
              AdminSettingsHeroPill(
                icon: Icons.public_outlined,
                label: _isPublic ? 'Công khai' : 'Đang ẩn',
              ),
              AdminSettingsHeroPill(
                icon: Icons.person_add_alt_1_outlined,
                label: _allowTenantJoinRequest ? 'Cho xin vào' : 'Tắt xin vào',
              ),
            ],
          ),
          AdminSettingsSection(
            title: 'Tiện ích',
            subtitle:
                'Nhóm này sẽ được dùng cho quảng cáo và thông tin tòa nhà.',
            icon: Icons.auto_awesome_outlined,
            color: const Color(0xFF0EA5E9),
            children: [
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width >= 560 ? 3 : 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.25,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _AmenityTile(
                    icon: Icons.wifi_rounded,
                    label: 'Wifi',
                    value: _wifi,
                    color: AppColors.primary,
                    onTap: () {
                      final next = !_wifi;
                      setState(() => _wifi = next);
                      widget.onWifiChanged(next);
                    },
                  ),
                  _AmenityTile(
                    icon: Icons.elevator_outlined,
                    label: 'Thang máy',
                    value: _elevator,
                    color: const Color(0xFF0EA5E9),
                    onTap: () {
                      final next = !_elevator;
                      setState(() => _elevator = next);
                      widget.onElevatorChanged(next);
                    },
                  ),
                  _AmenityTile(
                    icon: Icons.videocam_outlined,
                    label: 'Camera',
                    value: _camera,
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      final next = !_camera;
                      setState(() => _camera = next);
                      widget.onCameraChanged(next);
                    },
                  ),
                  _AmenityTile(
                    icon: Icons.local_parking_outlined,
                    label: 'Chỗ để xe',
                    value: _parking,
                    color: const Color(0xFF16A34A),
                    onTap: () {
                      final next = !_parking;
                      setState(() => _parking = next);
                      widget.onParkingChanged(next);
                    },
                  ),
                  _AmenityTile(
                    icon: Icons.local_laundry_service_outlined,
                    label: 'Máy giặt',
                    value: _laundry,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      final next = !_laundry;
                      setState(() => _laundry = next);
                      widget.onLaundryChanged(next);
                    },
                  ),
                  _AmenityTile(
                    icon: Icons.security_outlined,
                    label: 'Bảo vệ',
                    value: _security,
                    color: AppColors.managerAccent,
                    onTap: () {
                      final next = !_security;
                      setState(() => _security = next);
                      widget.onSecurityChanged(next);
                    },
                  ),
                ],
              ),
            ],
          ),
          AdminSettingsSection(
            title: 'Tham gia và hiển thị',
            subtitle:
                'Quyết định ai được xin vào tòa nhà và thông tin nào được hiển thị ra ngoài.',
            icon: Icons.visibility_outlined,
            color: AppColors.primary,
            children: [
              AdminSettingsSwitch(
                title: 'Công khai tòa nhà',
                subtitle: 'Cho người thuê tìm thấy tòa nhà trên Trang chủ.',
                icon: Icons.public_outlined,
                value: _isPublic,
                onChanged: (value) {
                  setState(() => _isPublic = value);
                  widget.onPublicChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Cho nhắn tin trước khi tham gia',
                subtitle: 'Người thuê có thể hỏi trước khi xin vào.',
                icon: Icons.chat_bubble_outline,
                value: _allowPreJoinMessage,
                onChanged: (value) {
                  setState(() => _allowPreJoinMessage = value);
                  widget.onAllowPreJoinMessageChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Cho người thuê xin vào tòa nhà',
                subtitle: 'Bat/tat luong yêu cầu tham gia tòa nhà.',
                icon: Icons.person_add_alt_1_outlined,
                value: _allowTenantJoinRequest,
                onChanged: (value) {
                  setState(() => _allowTenantJoinRequest = value);
                  widget.onAllowTenantJoinRequestChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Cho quản lý ung tuyen',
                subtitle: 'Người khác có thể xin quyền quản lý.',
                icon: Icons.badge_outlined,
                value: _allowManagerApplication,
                onChanged: (value) {
                  setState(() => _allowManagerApplication = value);
                  widget.onAllowManagerApplicationChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Cần admin phe duyệt',
                subtitle: 'Mọi yêu cầu cần được admin xác nhận.',
                icon: Icons.fact_check_outlined,
                value: _requireApproval,
                onChanged: (value) {
                  setState(() => _requireApproval = value);
                  widget.onRequireApprovalChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Tự động vào nhóm chat tòa nhà',
                subtitle: 'Thêm thành viên vào chat chung khi tham gia.',
                icon: Icons.groups_2_outlined,
                value: _autoJoinGroupChat,
                onChanged: (value) {
                  setState(() => _autoJoinGroupChat = value);
                  widget.onAutoJoinGroupChatChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Hiện địa chỉ',
                subtitle: 'Cho phép người ngoài xem địa chỉ tòa nhà.',
                icon: Icons.place_outlined,
                value: _showAddress,
                onChanged: (value) {
                  setState(() => _showAddress = value);
                  widget.onShowAddressChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Hiện giá phòng',
                subtitle: 'Hiện giá phòng mặc định trên quảng cáo.',
                icon: Icons.payments_outlined,
                value: _showRoomPrice,
                onChanged: (value) {
                  setState(() => _showRoomPrice = value);
                  widget.onShowRoomPriceChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Hiện số phòng trống',
                subtitle: 'Hiện số phòng còn trống trên Trang chủ.',
                icon: Icons.meeting_room_outlined,
                value: _showAvailableRooms,
                onChanged: (value) {
                  setState(() => _showAvailableRooms = value);
                  widget.onShowAvailableRoomsChanged(value);
                },
              ),
            ],
          ),
          AdminSettingsAsyncButton(
            onPressed: widget.onSave,
            icon: Icons.save_outlined,
            label: 'Lưu tiện ích và quyền',
          ),
        ],
      ),
    );
  }
}

class _AmenityTile extends StatelessWidget {
  const _AmenityTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value ? color.withValues(alpha: 0.10) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: value ? color.withValues(alpha: 0.28) : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: value ? color : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: value ? Colors.white : color,
                      size: 21,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    value ? Icons.check_circle : Icons.circle_outlined,
                    color: value ? color : AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value ? color : AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value ? 'Đang bật' : 'Đang tắt',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
