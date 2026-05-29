import 'package:flutter/material.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Phong va gia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminSettingsSection(
            title: 'So do phong',
            subtitle:
                'Nhom nay tao nen danh sach phong va gia mac dinh cho toa nha.',
            children: [
              AdminSettingsTextField(
                controller: widget.floorCountController,
                label: 'So tang',
                keyboardType: TextInputType.number,
                onChanged: _refreshSummary,
              ),
              AdminSettingsTextField(
                controller: widget.roomsPerFloorController,
                label: 'So phong moi tang',
                keyboardType: TextInputType.number,
                helperText: 'Nhap muc nay de app tu tinh tong so phong.',
                onChanged: _refreshSummary,
              ),
              AdminSettingsTextField(
                controller: widget.totalRoomsController,
                label: 'Tong so phong',
                keyboardType: TextInputType.number,
                helperText:
                    'Hien tai se dong bo $effectiveTotalRooms phong khi bam luu.',
                onChanged: _refreshSummary,
              ),
              AdminSettingsTextField(
                controller: widget.defaultRentController,
                label: 'Tien thue mac dinh cho phong',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          AdminSettingsSection(
            title: 'Gia dich vu va hoa don',
            subtitle:
                'Cac gia tri nay se lam mac dinh khi admin tao hoa don hang thang.',
            children: [
              AdminSettingsTextField(
                controller: widget.electricityPriceController,
                label: 'Gia dien',
                keyboardType: TextInputType.number,
              ),
              AdminSettingsTextField(
                controller: widget.waterPriceController,
                label: 'Gia nuoc',
                keyboardType: TextInputType.number,
              ),
              AdminSettingsTextField(
                controller: widget.serviceFeeController,
                label: 'Phi dich vu',
                keyboardType: TextInputType.number,
              ),
              AdminSettingsTextField(
                controller: widget.internetFeeController,
                label: 'Phi internet',
                keyboardType: TextInputType.number,
              ),
              AdminSettingsTextField(
                controller: widget.parkingFeeController,
                label: 'Phi gui xe',
                keyboardType: TextInputType.number,
              ),
              Row(
                children: [
                  Expanded(
                    child: AdminSettingsTextField(
                      controller: widget.billCloseDayController,
                      label: 'Ngay chot so',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdminSettingsTextField(
                      controller: widget.billDueDayController,
                      label: 'Han dong tien',
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
            label: 'Luu phong va gia',
          ),
        ],
      ),
    );
  }
}
