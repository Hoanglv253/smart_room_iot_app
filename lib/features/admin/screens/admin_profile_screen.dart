import 'package:flutter/material.dart';

import '../models/admin_profile_data.dart';
import 'admin_nav.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final TextEditingController _nameController = TextEditingController(
    text: 'HOÀNG V.L.',
  );
  final TextEditingController _idController = TextEditingController(
    text: 'ADM-001-HVL',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '0123 456 789',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'hoang.v.l@iot.com',
  );
  final TextEditingController _joinedDateController = TextEditingController(
    text: '15/01/2023',
  );
  final TextEditingController _roomController = TextEditingController(
    text: AdminProfileData.roomCount.toString(),
  );
  final TextEditingController _deviceController = TextEditingController(
    text: '250',
  );

  bool _isEditing = false;
  static const int _currentIndex = 4;

  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _background = Color(0xFFF3F5F8);
  static const String _position = 'Quản trị viên hệ thống';

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _joinedDateController.dispose();
    _roomController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 72,
        titleSpacing: 14,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFFFCCBC),
              child: Text(
                'AD',
                style: TextStyle(
                  color: Color(0xFF5D4037),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IoT CHUNG CƯ -',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Admin Hoàng VL.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 21),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 21,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 11,
                top: 17,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'CHỈNH SỬA HỒ SƠ' : 'HỒ SƠ ADMIN',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Color(0xFFFFCCBC),
                  child: Icon(
                    Icons.person,
                    color: Color(0xFF1F4F7A),
                    size: 52,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: _isEditing
                    ? SizedBox(
                        width: 210,
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Tên admin',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      )
                    : Text(
                        _nameController.text,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              _ProfileInfoGroup(
                children: [
                  const _ProfileInfoTile(
                    icon: Icons.work,
                    label: 'Chức vụ',
                    value: _position,
                    locked: true,
                  ),
                  _ProfileInfoTile(
                    icon: Icons.badge,
                    label: 'Mã ID',
                    controller: _idController,
                    isEditing: _isEditing,
                  ),
                  _ProfileInfoTile(
                    icon: Icons.phone,
                    label: 'Số điện thoại',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    isEditing: _isEditing,
                  ),
                  _ProfileInfoTile(
                    icon: Icons.email,
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    isEditing: _isEditing,
                  ),
                  _ProfileInfoTile(
                    icon: Icons.calendar_month,
                    label: 'Ngày tham gia',
                    controller: _joinedDateController,
                    isEditing: _isEditing,
                  ),
                  _ProfileInfoTile(
                    icon: Icons.apartment,
                    label: 'Số phòng',
                    controller: _roomController,
                    keyboardType: TextInputType.number,
                    isEditing: _isEditing,
                  ),
                  _ProfileInfoTile(
                    icon: Icons.devices,
                    label: 'Thiết bị',
                    controller: _deviceController,
                    keyboardType: TextInputType.number,
                    isEditing: _isEditing,
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isEditing)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelEditing,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: const Text(
                          'HỦY',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saveProfile,
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        child: const Text(
                          'LƯU HỒ SƠ',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: () => setState(() => _isEditing = true),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: const Text(
                      'CHỈNH SỬA HỒ SƠ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => openAdminTab(
          context,
          currentIndex: _currentIndex,
          targetIndex: index,
        ),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang Chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Người Dùng'),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Thiết Bị'),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Nhật Ký',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài Đặt'),
        ],
      ),
    );
  }

  void _saveProfile() {
    final roomCount = int.tryParse(_roomController.text.trim());
    if (roomCount != null && roomCount > 0) {
      AdminProfileData.roomCount = roomCount;
    }
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu thông tin hồ sơ.')),
    );
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }
}

class _ProfileInfoGroup extends StatelessWidget {
  const _ProfileInfoGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    this.value,
    this.controller,
    this.keyboardType,
    this.isEditing = false,
    this.locked = false,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool isEditing;
  final bool locked;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final displayValue = value ?? controller?.text ?? '';

    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: isEditing && !locked ? 58 : 43),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(icon, color: _AdminProfileScreenState._primaryBlue, size: 21),
              const SizedBox(width: 14),
              Expanded(
                child: isEditing && !locked && controller != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: TextField(
                          controller: controller,
                          keyboardType: keyboardType,
                          decoration: InputDecoration(
                            labelText: label,
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      )
                    : Text(
                        '$label: $displayValue',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: locked ? Colors.black54 : Colors.black87,
                        ),
                      ),
              ),
              if (locked) ...[
                const SizedBox(width: 8),
                const Icon(Icons.lock, color: Colors.black38, size: 16),
              ],
              const SizedBox(width: 12),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 48, color: Color(0xFFE7EAF0)),
      ],
    );
  }
}
