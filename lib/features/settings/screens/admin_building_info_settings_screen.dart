import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'admin_settings_widgets.dart';

class AdminBuildingInfoSettingsScreen extends StatefulWidget {
  const AdminBuildingInfoSettingsScreen({
    required this.nameController,
    required this.provinceController,
    required this.wardController,
    required this.addressController,
    required this.descriptionController,
    required this.phoneController,
    required this.emailController,
    required this.selectedLocation,
    required this.onLocationFieldsChanged,
    required this.onPickLocation,
    required this.onSave,
    super.key,
  });

  final TextEditingController nameController;
  final TextEditingController provinceController;
  final TextEditingController wardController;
  final TextEditingController addressController;
  final TextEditingController descriptionController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final Map<String, dynamic> selectedLocation;
  final VoidCallback onLocationFieldsChanged;
  final Future<Map<String, dynamic>?> Function() onPickLocation;
  final Future<void> Function() onSave;

  @override
  State<AdminBuildingInfoSettingsScreen> createState() =>
      _AdminBuildingInfoSettingsScreenState();
}

class _AdminBuildingInfoSettingsScreenState
    extends State<AdminBuildingInfoSettingsScreen> {
  late Map<String, dynamic> _location;

  @override
  void initState() {
    super.initState();
    _location = {...widget.selectedLocation};
  }

  void _syncLocationFields() {
    widget.onLocationFieldsChanged();
    setState(() {
      _location = {
        ..._location,
        'province': widget.provinceController.text.trim(),
        'ward': widget.wardController.text.trim(),
      };
    });
  }

  Future<void> _pickLocation() async {
    final nextLocation = await widget.onPickLocation();
    if (!mounted || nextLocation == null) return;
    setState(() => _location = {...nextLocation});
  }

  @override
  Widget build(BuildContext context) {
    final buildingName = widget.nameController.text.trim().isEmpty
        ? 'Tên tòa nhà'
        : widget.nameController.text.trim();
    final area = [
      widget.wardController.text.trim(),
      widget.provinceController.text.trim(),
    ].where((part) => part.isNotEmpty).join(', ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Thông tin tòa nhà',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminSettingsHeroCard(
            icon: Icons.apartment_outlined,
            title: buildingName,
            subtitle: area.isEmpty
                ? 'Hoàn thiện tên, địa chỉ và liên hệ để hiển thị trên Trang chủ.'
                : area,
            metrics: [
              AdminSettingsHeroPill(
                icon: Icons.place_outlined,
                label: _coordinateLabel(_location),
              ),
              AdminSettingsHeroPill(
                icon: Icons.call_outlined,
                label: widget.phoneController.text.trim().isEmpty
                    ? 'Chưa có SĐT'
                    : widget.phoneController.text.trim(),
              ),
            ],
          ),
          AdminSettingsSection(
            title: 'Thông tin chung',
            subtitle:
                'Tên, liên hệ và địa chỉ này được dùng cho quảng cáo, tìm kiếm và hóa đơn.',
            icon: Icons.edit_location_alt_outlined,
            color: AppColors.primary,
            children: [
              AdminSettingsTextField(
                controller: widget.nameController,
                label: 'Tên tòa nhà',
                onChanged: (_) => setState(() {}),
              ),
              AdminProvinceDropdown(
                controller: widget.provinceController,
                onChanged: (_) => _syncLocationFields(),
              ),
              AdminSettingsTextField(
                controller: widget.wardController,
                label: 'Xã/phường',
                helperText: 'Dùng cho bộ lọc khu vực và địa chỉ mới.',
                onChanged: (_) => _syncLocationFields(),
              ),
              AdminSettingsTextField(
                controller: widget.addressController,
                label: 'Địa chỉ chi tiết',
                helperText:
                    'Số nhà, tên đường; sau đó chọn vị trí chính xác trên map.',
                onChanged: (_) => _syncLocationFields(),
              ),
              AdminLocationPickerButton(
                location: _location,
                onPressed: _pickLocation,
              ),
              AdminSettingsTextField(
                controller: widget.descriptionController,
                label: 'Mô tả ngan',
                maxLines: 3,
              ),
              AdminSettingsTextField(
                controller: widget.phoneController,
                label: 'Số điện thoại liên hệ',
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
              ),
              AdminSettingsTextField(
                controller: widget.emailController,
                label: 'Email liên hệ',
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          AdminSettingsAsyncButton(
            onPressed: widget.onSave,
            icon: Icons.save_outlined,
            label: 'Lưu thông tin tòa nhà',
          ),
        ],
      ),
    );
  }

  static String _coordinateLabel(Map<String, dynamic> location) {
    final lat = location['lat'];
    final lng = location['lng'];
    if (lat == null || lng == null) return 'Chưa chọn map';
    return 'Đã chọn bản đồ';
  }
}
