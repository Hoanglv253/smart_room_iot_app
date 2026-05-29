import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Thong tin toa nha')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminSettingsSection(
            title: 'Thong tin chung',
            subtitle:
                'Ten, lien he va dia chi nay duoc dung cho quang cao, tim kiem va hoa don.',
            children: [
              AdminSettingsTextField(
                controller: widget.nameController,
                label: 'Ten toa nha',
              ),
              AdminProvinceDropdown(
                controller: widget.provinceController,
                onChanged: (_) => _syncLocationFields(),
              ),
              AdminSettingsTextField(
                controller: widget.wardController,
                label: 'Xa/phuong',
                helperText: 'Dung cho bo loc khu vuc va dia chi moi.',
                onChanged: (_) => _syncLocationFields(),
              ),
              AdminSettingsTextField(
                controller: widget.addressController,
                label: 'Dia chi chi tiet',
                helperText:
                    'So nha, ten duong; sau do chon vi tri chinh xac tren map.',
                onChanged: (_) => _syncLocationFields(),
              ),
              AdminLocationPickerButton(
                location: _location,
                onPressed: _pickLocation,
              ),
              AdminSettingsTextField(
                controller: widget.descriptionController,
                label: 'Mo ta ngan',
                maxLines: 3,
              ),
              AdminSettingsTextField(
                controller: widget.phoneController,
                label: 'So dien thoai lien he',
                keyboardType: TextInputType.phone,
              ),
              AdminSettingsTextField(
                controller: widget.emailController,
                label: 'Email lien he',
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          AdminSettingsAsyncButton(
            onPressed: widget.onSave,
            icon: Icons.save_outlined,
            label: 'Luu thong tin toa nha',
          ),
        ],
      ),
    );
  }
}
