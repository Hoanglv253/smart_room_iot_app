import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'admin_settings_widgets.dart';

class AdminRoomBillingSettingsScreen extends StatefulWidget {
  const AdminRoomBillingSettingsScreen({
    required this.floorCountController,
    required this.roomsPerFloorController,
    required this.totalRoomsController,
    required this.defaultRentController,
    required this.electricityPriceController,
    required this.waterPriceController,
    required this.serviceFeeController,
    required this.internetFeeController,
    required this.parkingFeeController,
    required this.billCloseDayController,
    required this.billDueDayController,
    required this.effectiveTotalRooms,
    required this.onSave,
    super.key,
  });

  final TextEditingController floorCountController;
  final TextEditingController roomsPerFloorController;
  final TextEditingController totalRoomsController;
  final TextEditingController defaultRentController;
  final TextEditingController electricityPriceController;
  final TextEditingController waterPriceController;
  final TextEditingController serviceFeeController;
  final TextEditingController internetFeeController;
  final TextEditingController parkingFeeController;
  final TextEditingController billCloseDayController;
  final TextEditingController billDueDayController;
  final int Function() effectiveTotalRooms;
  final Future<void> Function() onSave;

  @override
  State<AdminRoomBillingSettingsScreen> createState() =>
      _AdminRoomBillingSettingsScreenState();
}

class _AdminRoomBillingSettingsScreenState
    extends State<AdminRoomBillingSettingsScreen> {
  void _refreshSummary(String _) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final effectiveTotalRooms = widget.effectiveTotalRooms();
    final floorCount = _readInt(widget.floorCountController.text);
    final roomsPerFloor = _readInt(widget.roomsPerFloorController.text);
    final defaultRent = _readInt(widget.defaultRentController.text);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Phòng và giá',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminSettingsHeroCard(
            icon: Icons.meeting_room_outlined,
            title: '$effectiveTotalRooms phòng',
            subtitle:
                'Sơ đồ phòng và giá mặc định sẽ được đồng bộ khi bấm lưu.',
            color: AppColors.tenantAccent,
            metrics: [
              AdminSettingsHeroPill(
                icon: Icons.layers_outlined,
                label: floorCount > 0 ? '$floorCount tầng' : 'Chưa có tầng',
              ),
              AdminSettingsHeroPill(
                icon: Icons.grid_view_outlined,
                label: roomsPerFloor > 0
                    ? '$roomsPerFloor phòng/tầng'
                    : 'Chưa chia tầng',
              ),
              AdminSettingsHeroPill(
                icon: Icons.payments_outlined,
                label: defaultRent > 0 ? _money(defaultRent) : 'Chưa đặt giá',
              ),
            ],
          ),
          AdminSettingsSection(
            title: 'Số do phòng',
            subtitle:
                'Nhóm này tạo nên danh sách phòng và giá mặc định cho tòa nhà.',
            icon: Icons.auto_awesome_mosaic_outlined,
            color: AppColors.tenantAccent,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AdminSettingsInfoCard(
                      icon: Icons.layers_outlined,
                      label: 'Tầng',
                      value: floorCount > 0 ? '$floorCount' : '0',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminSettingsInfoCard(
                      icon: Icons.meeting_room_outlined,
                      label: 'Tổng phòng',
                      value: '$effectiveTotalRooms',
                      color: AppColors.tenantAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AdminSettingsTextField(
                controller: widget.floorCountController,
                label: 'Số tầng',
                keyboardType: TextInputType.number,
                onChanged: _refreshSummary,
              ),
              AdminSettingsTextField(
                controller: widget.roomsPerFloorController,
                label: 'Số phòng mỗi tầng',
                keyboardType: TextInputType.number,
                helperText: 'Nhập mục này để app tự tính tổng số phòng.',
                onChanged: _refreshSummary,
              ),
              AdminSettingsTextField(
                controller: widget.totalRoomsController,
                label: 'Tổng số phòng',
                keyboardType: TextInputType.number,
                helperText:
                    'Hiện tại sẽ đồng bộ $effectiveTotalRooms phòng khi bấm lưu.',
                onChanged: _refreshSummary,
              ),
              AdminSettingsTextField(
                controller: widget.defaultRentController,
                label: 'Tiền thuê mặc định cho phòng',
                keyboardType: TextInputType.number,
                onChanged: _refreshSummary,
              ),
            ],
          ),
          AdminSettingsSection(
            title: 'Giá dịch vụ và hóa đơn',
            subtitle:
                'Các giá trị này sẽ làm mặc định khi admin tạo hóa đơn hàng tháng.',
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFFF59E0B),
            children: [
              AdminSettingsTextField(
                controller: widget.electricityPriceController,
                label: 'Giá điện',
                keyboardType: TextInputType.number,
              ),
              AdminSettingsTextField(
                controller: widget.waterPriceController,
                label: 'Giá nước',
                keyboardType: TextInputType.number,
              ),
              AdminSettingsTextField(
                controller: widget.serviceFeeController,
                label: 'Phí dịch vụ',
                keyboardType: TextInputType.number,
              ),
              AdminSettingsTextField(
                controller: widget.internetFeeController,
                label: 'Phí internet',
                keyboardType: TextInputType.number,
              ),
              AdminSettingsTextField(
                controller: widget.parkingFeeController,
                label: 'Phí gửi xe',
                keyboardType: TextInputType.number,
              ),
              Row(
                children: [
                  Expanded(
                    child: AdminSettingsTextField(
                      controller: widget.billCloseDayController,
                      label: 'Ngày chốt số',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdminSettingsTextField(
                      controller: widget.billDueDayController,
                      label: 'Hạn đóng tiền',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AdminSettingsAsyncButton(
            onPressed: widget.onSave,
            icon: Icons.save_outlined,
            label: 'Lưu phòng và giá',
          ),
        ],
      ),
    );
  }

  static int _readInt(String value) => int.tryParse(value.trim()) ?? 0;

  static String _money(int amount) {
    final digits = amount.abs().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[index]);
    }
    return '${amount < 0 ? '-' : ''}${buffer.toString()} VND';
  }
}
