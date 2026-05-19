import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../admin/screens/admin_building_rooms_screen.dart';
import '../../admin/screens/admin_device_list_screen.dart';
import '../../admin/screens/admin_settings_screen.dart';
import '../../admin/screens/admin_user_list_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../notifications/screens/notification_center_screen.dart';
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
        } else if (role == 'manager') {
          return _buildManagerDashboard(context, user, authService);
        } else {
          return _buildUserHome();
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
            onPressed: () => _openAdminSettings(context),
          ),
          _buildAdminNotificationButton(context),
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
            _buildAdminStatsSection(),
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
                    onTap: () => _openAdminUserList(context),
                  ),
                  _buildAdminActionItem(
                    Icons.apartment,
                    'Quản Lý\nTòa Nhà',
                    const Color(0xFF1565C0),
                    onTap: () => _openAdminBuildingRooms(context),
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
            _buildAdminRecentActivitySection(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            _openAdminUserList(context);
          } else if (index == 2) {
            _openAdminDeviceList(context);
          } else if (index == 4) {
            _openAdminSettings(context);
          }
        },
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
                          height: 62,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 26,
                                height: 48,
                                color: mainColor,
                              ),
                              const SizedBox(width: 7),
                              Container(
                                width: 26,
                                height: 62,
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

  Widget _buildAdminStatsSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Không tải được dữ liệu thống kê.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          );
        }

        final stats = _AdminDashboardStats.fromUserDocs(
          snapshot.data?.docs ??
              const <QueryDocumentSnapshot<Map<String, dynamic>>>[],
        );
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return SizedBox(
          height: 195,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAdminStatCard(
                title: 'Người Dùng',
                centerValue: isLoading ? '...' : '${stats.totalUsers}',
                centerLabel: 'Tổng số',
                type: 'donut',
                legendOne: 'Quản trị: ${stats.admins}',
                legendTwo: 'Quản lý: ${stats.managers}',
                legendThree: 'Người thuê: ${stats.tenants}',
                mainColor: const Color(0xFF1565C0),
              ),
              _buildAdminStatCard(
                title: 'Phòng',
                centerValue: isLoading ? '...' : '${stats.occupiedRooms}',
                centerLabel: '',
                type: 'bar',
                legendOne: 'Đang thuê: ${stats.occupiedRooms}',
                legendTwo: 'Có dữ liệu phòng: ${stats.roomsWithCode}',
                legendThree: '',
                mainColor: const Color(0xFF1565C0),
              ),
              _buildAdminStatCard(
                title: 'Thiết Bị',
                centerValue: '${_AdminDashboardStats.onlineDevicePercent}%',
                centerLabel: '',
                type: 'donut',
                legendOne: 'Online: ${_AdminDashboardStats.onlineDevices}',
                legendTwo: 'Offline: ${_AdminDashboardStats.offlineDevices}',
                legendThree: '',
                mainColor: const Color(0xFF26A69A),
              ),
            ],
          ),
        );
      },
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

  Widget _buildAdminNotificationButton(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('targetRoles', arrayContains: 'admin')
          .snapshots(),
      builder: (context, snapshot) {
        final notifications = _AdminNotification.fromDocs(
          snapshot.data?.docs ??
              const <QueryDocumentSnapshot<Map<String, dynamic>>>[],
        );

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 21,
              ),
              onPressed: () => _showAdminNotifications(
                context,
                notifications,
              ),
            ),
            if (notifications.isNotEmpty)
              Positioned(
                right: 9,
                top: 15,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    notifications.length > 9 ? '9+' : '${notifications.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAdminRecentActivitySection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('targetRoles', arrayContains: 'admin')
          .snapshots(),
      builder: (context, snapshot) {
        final notifications = _AdminNotification.fromDocs(
          snapshot.data?.docs ??
              const <QueryDocumentSnapshot<Map<String, dynamic>>>[],
        );
        final visibleItems = notifications.take(4).toList();

        return Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                else if (visibleItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Chưa có thông báo từ quản lý hoặc người thuê.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  )
                else
                  ...visibleItems.map(
                    (item) => _buildAdminActivityItem(
                      color: item.color,
                      text: item.message,
                      time: item.timeLabel,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAdminNotifications(
    BuildContext context,
    List<_AdminNotification> notifications,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông báo từ quản lý và người thuê',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                if (notifications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Chưa có thông báo nào.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: item.color.withValues(alpha: 0.12),
                            child: Icon(item.icon, color: item.color),
                          ),
                          title: Text(
                            item.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(item.subtitle),
                          trailing: Text(
                            item.timeLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminActionItem(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7EAF0), width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
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
  // GIAO DIỆN 2: MANAGER DASHBOARD (Dành riêng cho tài khoản quản lý)
  // =========================================================================
  Widget _buildManagerDashboard(
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
              backgroundColor: Color(0xFFFFD7A6),
              child: Text(
                'QL',
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
                    'IoT CHUNG CƯ - BẢNG ĐIỀU KHIỂN QUẢN LÝ',
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
                    user?.displayName ?? 'Quản lý tòa nhà',
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
                icon: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 21,
                ),
                onPressed: () => _openNotificationCenter(
                  context,
                  role: 'manager',
                  title: 'Thông Báo Quản Lý',
                ),
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
              'Tổng Quan Block A',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            _buildManagerOverviewStats(),
            const SizedBox(height: 14),
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
                    Icons.meeting_room,
                    'Quản Lý\nPhòng',
                    const Color(0xFF1565C0),
                  ),
                  _buildAdminActionItem(
                    Icons.people,
                    'Người\nThuê',
                    const Color(0xFF1565C0),
                  ),
                  _buildAdminActionItem(
                    Icons.build,
                    'Yêu Cầu\nSửa Chữa',
                    Colors.deepOrange,
                  ),
                  _buildAdminActionItem(
                    Icons.electric_bolt,
                    'Điện Nước',
                    const Color(0xFF1565C0),
                  ),
                  _buildAdminActionItem(
                    Icons.campaign,
                    'Gửi\nThông Báo',
                    const Color(0xFF1565C0),
                    onTap: () => showNotificationComposer(
                      context: context,
                      senderRole: 'manager',
                      targetRoles: const ['user'],
                      type: 'notice',
                      title: 'Gửi thông báo cho người thuê',
                      hintText: 'Nhập nội dung thông báo...',
                      successMessage: 'Đã gửi thông báo cho người thuê.',
                    ),
                  ),
                  _buildAdminActionItem(
                    Icons.analytics,
                    'Báo Cáo',
                    const Color(0xFF1565C0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phòng Cần Theo Dõi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildManagerRoomItem(
                      room: 'P501 - Block A',
                      tenant: 'Hoàng T.M.',
                      status: 'Máy lạnh đang bật',
                      color: const Color(0xFF1565C0),
                    ),
                    _buildManagerRoomItem(
                      room: 'P302 - Block A',
                      tenant: 'Nguyễn M.K.',
                      status: 'Chưa thanh toán điện',
                      color: Colors.deepOrange,
                    ),
                    _buildManagerRoomItem(
                      room: 'P405 - Block B',
                      tenant: 'Trần H.A.',
                      status: 'Báo lỗi cảm biến',
                      color: Colors.redAccent,
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
        onTap: (index) {
          if (index == 1) {
            _openAdminUserList(context);
          }
        },
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
            icon: Icon(Icons.meeting_room),
            label: 'Phòng',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Sửa Chữa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Hóa Đơn',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài Đặt'),
        ],
      ),
    );
  }

  Widget _buildManagerSummaryCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerOverviewStats() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        final users = snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final occupiedRooms = users
            .map((doc) {
              final data = doc.data();
              return (data['roomNumber'] ?? data['room'] ?? '').toString();
            })
            .where((room) => room.trim().isNotEmpty)
            .toSet()
            .length;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildManagerSummaryCard(
                    icon: Icons.apartment,
                    value: snapshot.connectionState == ConnectionState.waiting
                        ? '...'
                        : '$occupiedRooms',
                    label: 'Phòng đang thuê',
                    color: const Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .where('targetRoles', arrayContains: 'manager')
                        .snapshots(),
                    builder: (context, reportSnapshot) {
                      final reportCount = (reportSnapshot.data?.docs ??
                              const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                          .where((doc) => doc.data()['type'] == 'report')
                          .length;
                      return _buildManagerSummaryCard(
                        icon: Icons.warning_amber_rounded,
                        value: reportSnapshot.connectionState ==
                                ConnectionState.waiting
                            ? '...'
                            : '$reportCount',
                        label: 'Báo cáo từ người thuê',
                        color: Colors.deepOrange,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildManagerSummaryCard(
                    icon: Icons.receipt_long,
                    value: '28',
                    label: 'Hóa đơn đã thu',
                    color: const Color(0xFF1A7F3F),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildManagerSummaryCard(
                    icon: Icons.devices,
                    value: '94%',
                    label: 'Thiết bị online',
                    color: const Color(0xFF26A69A),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildManagerRoomItem({
    required String room,
    required String tenant,
    required String status,
    required Color color,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$tenant - $status',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black38),
        ],
      ),
    );
  }

  void _openAdminUserList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AdminUserListScreen()),
    );
  }

  void _openAdminDeviceList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AdminDeviceListScreen()),
    );
  }

  void _openAdminBuildingRooms(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AdminBuildingRoomsScreen()),
    );
  }

  void _openAdminSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AdminSettingsScreen()),
    );
  }

  void _openNotificationCenter(
    BuildContext context, {
    required String role,
    required String title,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotificationCenterScreen(
          currentRole: role,
          title: title,
        ),
      ),
    );
  }

  // =========================================================================
  // GIAO DIỆN 3: USER DASHBOARD (Dành riêng cho cư dân thuê phòng)
  // =========================================================================
  Widget _buildUserHome() {
    return const RoomControlScreen();
  }

  // =========================================================================
  // HÀM BỔ TRỢ UI (Helper Widgets & Functions)
  // =========================================================================

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

class _AdminDashboardStats {
  const _AdminDashboardStats({
    required this.totalUsers,
    required this.admins,
    required this.managers,
    required this.tenants,
    required this.occupiedRooms,
    required this.roomsWithCode,
  });

  final int totalUsers;
  final int admins;
  final int managers;
  final int tenants;
  final int occupiedRooms;
  final int roomsWithCode;

  static const int totalDevices = 7;
  static const int onlineDevices = 7;
  static const int offlineDevices = totalDevices - onlineDevices;
  static const int onlineDevicePercent = totalDevices == 0
      ? 0
      : (onlineDevices * 100) ~/ totalDevices;

  factory _AdminDashboardStats.fromUserDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var admins = 0;
    var managers = 0;
    var tenants = 0;
    final roomCodes = <String>{};

    for (final doc in docs) {
      final data = doc.data();
      final role = (data['role'] ?? 'user').toString();

      switch (role) {
        case 'admin':
          admins++;
          break;
        case 'manager':
          managers++;
          break;
        default:
          tenants++;
      }

      final room = (data['room'] ?? data['roomCode'] ?? data['roomNumber'] ?? '')
          .toString()
          .trim();
      if (room.isNotEmpty) {
        roomCodes.add(room);
      }
    }

    return _AdminDashboardStats(
      totalUsers: docs.length,
      admins: admins,
      managers: managers,
      tenants: tenants,
      occupiedRooms: roomCodes.isNotEmpty ? roomCodes.length : tenants,
      roomsWithCode: roomCodes.length,
    );
  }
}

class _AdminNotification {
  const _AdminNotification({
    required this.message,
    required this.subtitle,
    required this.timeLabel,
    required this.sortTime,
    required this.color,
    required this.icon,
  });

  final String message;
  final String subtitle;
  final String timeLabel;
  final DateTime sortTime;
  final Color color;
  final IconData icon;

  static List<_AdminNotification> fromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final items = <_AdminNotification>[];

    for (final doc in docs) {
      final data = doc.data();
      final role = (data['senderRole'] ?? '').toString();
      final name = (data['senderName'] ?? 'Người dùng').toString();
      final message = (data['message'] ?? '').toString();
      final type = (data['type'] ?? 'notice').toString();
      final timestamp = _readTimestamp(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final roleLabel = role == 'manager'
          ? 'Quản lý'
          : role == 'user'
              ? 'Người thuê'
              : 'Admin';

      items.add(
        _AdminNotification(
          message: '$roleLabel $name: $message',
          subtitle: type == 'report' ? 'Báo cáo từ người thuê' : 'Thông báo',
          timeLabel: _formatTime(timestamp),
          sortTime: timestamp,
          color: type == 'report'
              ? Colors.deepOrange
              : const Color(0xFF1565C0),
          icon: type == 'report' ? Icons.report : Icons.notifications,
        ),
      );
    }

    items.sort((a, b) => b.sortTime.compareTo(a.sortTime));
    return items;
  }

  static DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String _formatTime(DateTime dateTime) {
    if (dateTime.millisecondsSinceEpoch == 0) return 'Mới';
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
