import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../room/screens/room_control_screen.dart'; // Import màn hình phòng của user

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final AuthService authService = AuthService();

    // SỬ DỤNG FUTUREBUILDER LÀM BỘ ĐIỀU HƯỚNG GỐC (ROOT ROUTER)
    return FutureBuilder<String>(
      future: user != null
          ? authService.getUserRole(user.uid)
          : Future.value('user'),
      builder: (context, snapshot) {
        // 1. Trong lúc đợi Firebase kiểm tra thẻ quyền thì hiện màn hình loading trắng tinh tế
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          );
        }

        final role = snapshot.data ?? 'user';

        // 2. PHÂN LUỒNG GIAO DIỆN TUYỆT ĐỐI THEO ROLE
        if (role == 'admin') {
          return _buildAdminDashboard(context, user, authService);
        } else {
          return _buildUserHome(context, user, authService);
        }
      },
    );
  }

  // =========================================================================
  // GIAO DIỆN 1: ADMIN DASHBOARD (Hiển thị trực tiếp, không có nút "Phòng của tôi")
  // =========================================================================
  Widget _buildAdminDashboard(
    BuildContext context,
    User? user,
    AuthService authService,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        automaticallyImplyLeading: false,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'IoT CHUNG CƯ - BẢNG ĐIỀU KHIỂN',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.displayName ?? 'Admin Hoàng VL.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 21),
            onPressed: () => _handleLogout(context, authService),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng Thống Kê',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 170,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildAdminStatCard(
                    title: 'Người Dùng',
                    centerValue: '154',
                    centerLabel: 'Tổng số',
                    type: 'donut',
                    legendOne: 'Admins',
                    legendTwo: 'Quản lý',
                    legendThree: 'Người thuê',
                    mainColor: const Color(0xFF1565C0),
                  ),
                  _buildAdminStatCard(
                    title: 'Phòng',
                    centerValue: '85',
                    centerLabel: '',
                    type: 'bar',
                    legendOne: 'Hợp đồng: 70',
                    legendTwo: 'Trống: 15',
                    legendThree: '',
                    mainColor: const Color(0xFF1565C0),
                  ),
                  _buildAdminStatCard(
                    title: 'Thiết Bị',
                    centerValue: '92%',
                    centerLabel: '',
                    type: 'donut',
                    legendOne: 'Online',
                    legendTwo: 'Offline',
                    legendThree: '',
                    mainColor: const Color(0xFF26A69A),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.18,
                children: [
                  _buildAdminActionItem(
                    Icons.groups,
                    'Quản Lý\nNgười Dùng',
                    const Color(0xFF1565C0),
                  ),
                  _buildAdminActionItem(
                    Icons.apartment,
                    'Quản Lý\nTòa Nhà',
                    const Color(0xFF1565C0),
                  ),
                  _buildAdminActionItem(
                    Icons.settings,
                    'Cấu Hình\nIoT',
                    const Color(0xFF1565C0),
                  ),
                  _buildAdminActionItem(
                    Icons.description,
                    'Audit Log',
                    const Color(0xFF1565C0),
                  ),
                  _buildAdminActionItem(
                    Icons.receipt_long,
                    'Hóa Đơn &\nBáo Cáo',
                    const Color(0xFF1565C0),
                  ),
                  _buildAdminActionItem(
                    Icons.warning,
                    'Thông Báo Lỗi',
                    Colors.redAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hoạt Động Gần Đây',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAdminActivityItem(
                      color: const Color(0xFF1565C0),
                      text: 'Admin thêm Quản lý: Nguyễn T.M.',
                      time: '09:45',
                    ),
                    _buildAdminActivityItem(
                      color: const Color(0xFF1565C0),
                      text: 'Cập nhật firmware cảm biến P301',
                      time: '10:12',
                    ),
                    _buildAdminActivityItem(
                      color: Colors.redAccent,
                      text: 'Lỗi cảm biến nhiệt độ P405',
                      time: '10:30',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang Chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Người Dùng',
          ),
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

  Widget _buildAdminStatCard({
    required String title,
    required String centerValue,
    required String centerLabel,
    required String type,
    required String legendOne,
    required String legendTwo,
    required String legendThree,
    required Color mainColor,
  }) {
    return Container(
      width: 112,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.more_vert, size: 16, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: type == 'bar'
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 66,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 26,
                                height: 52,
                                color: mainColor,
                              ),
                              const SizedBox(width: 7),
                              Container(
                                width: 26,
                                height: 68,
                                color: Color(0xFFE3EEF8),
                              ),
                              const SizedBox(width: 7),
                              Container(
                                width: 26,
                                height: 14,
                                color: Color(0xFF4AA3DF),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          centerValue,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            value: 0.72,
                            strokeWidth: 10,
                            backgroundColor: const Color(0xFFE3EEF8),
                            color: mainColor,
                          ),
                        ),
                        SizedBox(
                          width: 54,
                          height: 54,
                          child: CircularProgressIndicator(
                            value: 0.24,
                            strokeWidth: 10,
                            backgroundColor: Colors.transparent,
                            color: Colors.redAccent,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              centerValue,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                            if (centerLabel.isNotEmpty)
                              Text(
                                centerLabel,
                                style: const TextStyle(fontSize: 10),
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          _buildAdminLegendDot(mainColor, legendOne),
          _buildAdminLegendDot(const Color(0xFF4AA3DF), legendTwo),
          if (legendThree.isNotEmpty)
            _buildAdminLegendDot(const Color(0xFFFFC107), legendThree),
        ],
      ),
    );
  }

  Widget _buildAdminLegendDot(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionItem(IconData icon, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7EAF0), width: 0.5),
      ),
      child: InkWell(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActivityItem({
    required Color color,
    required String text,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // GIAO DIỆN 2: USER DASHBOARD (Dành riêng cho cư dân thuê phòng)
  // =========================================================================
  Widget _buildUserHome(
    BuildContext context,
    User? user,
    AuthService authService,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Room Dashboard'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context, authService),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        color: Colors.blue[50],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 50, color: Colors.blue)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Người dùng Smart Room',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user?.email ?? '',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),

            // Nút bấm thần thánh dẫn vào phòng của cư dân
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RoomControlScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.meeting_room, color: Colors.white),
              label: const Text(
                'Phòng của tôi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // HÀM BỔ TRỢ UI (Helper Widgets & Functions)
  // =========================================================================

  // Hàm vẽ khối số liệu Dashboard Admin
  Widget _buildMetricCard(
    IconData icon,
    String label,
    String value,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  // Hàm vẽ dòng danh sách bảo trì
  Widget _buildMaintenanceItem(
    IconData icon,
    String room,
    String issue,
    String time,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(room, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(issue, style: const TextStyle(color: Colors.black54)),
        trailing: Text(
          time,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }

  // Hàm xử lý Đăng xuất dùng chung cho cả 2 giao diện
  void _handleLogout(BuildContext context, AuthService authService) async {
    await authService.logout();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
}
