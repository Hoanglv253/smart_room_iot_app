import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Tien ich va quyen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminSettingsSection(
            title: 'Tien ich',
            subtitle:
                'Nhom nay se duoc dung cho quang cao va thong tin toa nha.',
            children: [
              AdminSettingsSwitch(
                title: 'Wifi',
                value: _wifi,
                onChanged: (value) {
                  setState(() => _wifi = value);
                  widget.onWifiChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Thang may',
                value: _elevator,
                onChanged: (value) {
                  setState(() => _elevator = value);
                  widget.onElevatorChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Camera',
                value: _camera,
                onChanged: (value) {
                  setState(() => _camera = value);
                  widget.onCameraChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Cho de xe',
                value: _parking,
                onChanged: (value) {
                  setState(() => _parking = value);
                  widget.onParkingChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'May giat',
                value: _laundry,
                onChanged: (value) {
                  setState(() => _laundry = value);
                  widget.onLaundryChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Bao ve',
                value: _security,
                onChanged: (value) {
                  setState(() => _security = value);
                  widget.onSecurityChanged(value);
                },
              ),
            ],
          ),
          AdminSettingsSection(
            title: 'Tham gia va hien thi',
            subtitle:
                'Quyet dinh ai duoc xin vao toa nha va thong tin nao duoc hien ra ngoai.',
            children: [
              AdminSettingsSwitch(
                title: 'Cong khai toa nha',
                value: _isPublic,
                onChanged: (value) {
                  setState(() => _isPublic = value);
                  widget.onPublicChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Cho nhan tin truoc khi tham gia',
                value: _allowPreJoinMessage,
                onChanged: (value) {
                  setState(() => _allowPreJoinMessage = value);
                  widget.onAllowPreJoinMessageChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Cho nguoi thue xin vao toa nha',
                value: _allowTenantJoinRequest,
                onChanged: (value) {
                  setState(() => _allowTenantJoinRequest = value);
                  widget.onAllowTenantJoinRequestChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Cho quan ly ung tuyen',
                value: _allowManagerApplication,
                onChanged: (value) {
                  setState(() => _allowManagerApplication = value);
                  widget.onAllowManagerApplicationChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Can admin phe duyet',
                value: _requireApproval,
                onChanged: (value) {
                  setState(() => _requireApproval = value);
                  widget.onRequireApprovalChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Tu dong vao nhom chat toa nha',
                value: _autoJoinGroupChat,
                onChanged: (value) {
                  setState(() => _autoJoinGroupChat = value);
                  widget.onAutoJoinGroupChatChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Hien dia chi',
                value: _showAddress,
                onChanged: (value) {
                  setState(() => _showAddress = value);
                  widget.onShowAddressChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Hien gia phong',
                value: _showRoomPrice,
                onChanged: (value) {
                  setState(() => _showRoomPrice = value);
                  widget.onShowRoomPriceChanged(value);
                },
              ),
              AdminSettingsSwitch(
                title: 'Hien so phong trong',
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
            label: 'Luu tien ich va quyen',
          ),
        ],
      ),
    );
  }
}
