import 'package:flutter/material.dart';

import 'admin_nav.dart';
import 'admin_profile_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final AuthService _authService = AuthService();
  static const int _currentIndex = 4;

  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _background = Color(0xFFF3F5F8);

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
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
            onPressed: () {},
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
              const Text(
                'CÀI ĐẶT',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.account_circle,
                    title: 'Hồ Sơ Admin',
                    onTap: () => _openAdminProfile(context),
                  ),
                  _SettingsTile(
                    icon: Icons.lock,
                    title: 'Đổi Mật Khẩu',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.security,
                    title: 'Xác Thực 2 Lớp',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.wifi,
                    title: 'Thiết Lập Mạng IoT',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_active,
                    title: 'Cài Đặt Cảnh Báo',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.vpn_key,
                    title: 'Quản Lý Quyền Truy Cập',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.business,
                    title: 'Thông Tin Tòa Nhà',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.settings,
                    title: 'Cấu Hình Hệ Thống',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.language,
                    title: 'Ngôn Ngữ: Tiếng Việt',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.info,
                    title: 'Thông Tin Ứng Dụng & Phiên Bản',
                    onTap: () {},
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _LogoutTile(onTap: _handleLogout),
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

  void _openAdminProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AdminProfileScreen()),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 43,
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(icon, color: _AdminSettingsScreenState._primaryBlue, size: 21),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black54, size: 20),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 48, color: Color(0xFFE7EAF0)),
      ],
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EF)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: const SizedBox(
          height: 45,
          child: Row(
            children: [
              SizedBox(width: 14),
              Icon(Icons.logout, color: Colors.redAccent, size: 21),
              SizedBox(width: 14),
              Text(
                'ĐĂNG XUẤT',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
