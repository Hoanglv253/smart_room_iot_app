import 'package:flutter/material.dart';

import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../notifications/screens/notification_center_screen.dart';

class RoomControlScreen extends StatefulWidget {
  const RoomControlScreen({super.key});

  @override
  State<RoomControlScreen> createState() => _RoomControlScreenState();
}

class _RoomControlScreenState extends State<RoomControlScreen> {
  bool _lightOn = true;
  bool _fanOn = true;
  bool _acOn = true;
  int _fanSpeed = 2;
  int _currentIndex = 0;

  static const Color _primaryBlue = Color(0xFF0D5FA8);
  static const Color _deepBlue = Color(0xFF0A4E91);
  static const Color _softBackground = Color(0xFFF2F5F8);
  static const Color _lineColor = Color(0xFFE1E7EF);
  final AuthService _authService = AuthService();

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
      backgroundColor: _softBackground,
      appBar: AppBar(
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 10,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD7A6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.4),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'H',
                    style: TextStyle(
                      color: Color(0xFF4C3A24),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 0.92,
                    ),
                  ),
                  Text(
                    'P501',
                    style: TextStyle(
                      color: Color(0xFF4C3A24),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'IoT CHUNG CƯ - BẢNG ĐIỀU KHIỂN NGƯỜI THUÊ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Người Thuê: Hoàng T.M. (Phòng 501 - Block A)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.2, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Người Thuê: Hoàng T.M. (Phòng 501 - Block A)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DashboardCard(
                      height: 156,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardTitle(
                            title: 'Môi Trường Phòng:',
                            onMore: () {},
                          ),
                          const SizedBox(height: 4),
                          const Expanded(child: _EnvironmentChart()),
                          const SizedBox(height: 3),
                          const _MetricLine(
                            color: _deepBlue,
                            text: 'Nhiệt độ (26°C)',
                          ),
                          const _MetricLine(
                            color: Color(0xFF4AA3A7),
                            text: 'Độ ẩm (55%)',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _DeviceCard(
                      height: 156,
                      title: 'Đèn Chính (P501)',
                      isOn: _lightOn,
                      status: 'Đang bật',
                      icon: Icons.lightbulb,
                      onChanged: (value) => setState(() => _lightOn = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DashboardCard(
                      height: 154,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _CardTitle(title: 'Quạt Trần (P501)'),
                          const SizedBox(height: 8),
                          _SegmentSwitch(
                            value: _fanOn,
                            onChanged: (value) =>
                                setState(() => _fanOn = value),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Tốc độ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(3, (index) {
                              final speed = index + 1;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: index == 2 ? 0 : 5,
                                  ),
                                  child: _SpeedButton(
                                    label: '$speed',
                                    selected: _fanSpeed == speed,
                                    onTap: () =>
                                        setState(() => _fanSpeed = speed),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const Spacer(),
                          Text(
                            _fanOn
                                ? 'Đang bật - Tốc độ $_fanSpeed'
                                : 'Đang tắt',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _DashboardCard(
                      height: 154,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _CardTitle(title: 'Máy Lạnh (P501)'),
                          const SizedBox(height: 8),
                          _SegmentSwitch(
                            value: _acOn,
                            onChanged: (value) => setState(() => _acOn = value),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Expanded(
                                child: Text(
                                  'Mode',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                'Temp',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Expanded(
                                child: Text(
                                  'Cool/Fan/Heat',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                              Text(
                                '24°C',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            _acOn ? 'Đang bật - 24°C Cool' : 'Đang tắt',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: const [
                  Expanded(
                    child: _DashboardCard(
                      height: 58,
                      child: Center(
                        child: Text(
                          'Tiêu Thụ Điện T5',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: _DashboardCard(
                      height: 58,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '120 kWh',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Hóa đơn: Đã thanh toán',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1A7F3F),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              const _DashboardCard(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(2, 2, 2, 0),
                  child: _ActivityList(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationCenterScreen(
                  currentRole: 'user',
                  title: 'Thông Báo Người Thuê',
                  canSendReport: true,
                ),
              ),
            );
            return;
          }
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: Colors.black54,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 10.5),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang Chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Thiết Bị'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Hóa Đơn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông Báo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài Đặt'),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child, this.height});

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _RoomControlScreenState._lineColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title, this.onMore});

  final String title;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onMore,
          child: const Icon(Icons.more_vert, size: 18, color: Colors.black54),
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.title,
    required this.isOn,
    required this.status,
    required this.icon,
    required this.onChanged,
    this.height,
  });

  final String title;
  final bool isOn;
  final String status;
  final IconData icon;
  final ValueChanged<bool> onChanged;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      height: height,
      child: Column(
        children: [
          _CardTitle(title: title),
          const SizedBox(height: 8),
          _SegmentSwitch(value: isOn, onChanged: onChanged),
          const SizedBox(height: 8),
          Expanded(
            child: Icon(
              icon,
              size: 42,
              color: isOn
                  ? _RoomControlScreenState._primaryBlue
                  : Colors.black38,
            ),
          ),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SegmentSwitch extends StatelessWidget {
  const _SegmentSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF9EADBA)),
        color: const Color(0xFFEAF0F6),
      ),
      child: Row(
        children: [
          _SwitchHalf(
            label: 'ON',
            selected: value,
            onTap: () => onChanged(true),
          ),
          _SwitchHalf(
            label: 'OFF',
            selected: !value,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _SwitchHalf extends StatelessWidget {
  const _SwitchHalf({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? _RoomControlScreenState._primaryBlue
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: selected
              ? _RoomControlScreenState._primaryBlue
              : const Color(0xFFE5E9EF),
          foregroundColor: selected ? Colors.white : Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          elevation: selected ? 1 : 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _EnvironmentChart extends StatelessWidget {
  const _EnvironmentChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _EnvironmentChartPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _EnvironmentChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFFD6DEE8)
      ..strokeWidth = 1;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    const labels = ['30', '26', '22'];
    const leftGap = 20.0;
    final chartWidth = size.width - leftGap;
    final rowHeight = size.height / 2.8;

    for (var i = 0; i < 3; i++) {
      final y = 8 + (i * rowHeight);
      canvas.drawLine(Offset(leftGap, y), Offset(size.width, y), axisPaint);
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(fontSize: 9, color: Colors.black87),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    final bluePoints = [
      const Offset(0.04, 0.66),
      const Offset(0.18, 0.38),
      const Offset(0.34, 0.58),
      const Offset(0.50, 0.30),
      const Offset(0.70, 0.48),
      const Offset(0.94, 0.34),
    ];
    final tealPoints = [
      const Offset(0.02, 0.42),
      const Offset(0.20, 0.68),
      const Offset(0.40, 0.52),
      const Offset(0.56, 0.58),
      const Offset(0.72, 0.42),
      const Offset(0.96, 0.54),
    ];

    _drawLine(
      canvas,
      size,
      chartWidth,
      leftGap,
      bluePoints,
      _RoomControlScreenState._deepBlue,
    );
    _drawLine(
      canvas,
      size,
      chartWidth,
      leftGap,
      tealPoints,
      const Color(0xFF4AA3A7),
    );

    textPainter.text = const TextSpan(
      text: '12:00',
      style: TextStyle(fontSize: 9, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(leftGap + chartWidth * 0.45, size.height - 12),
    );
    textPainter.text = const TextSpan(
      text: '10:30',
      style: TextStyle(fontSize: 9, color: Colors.black87),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 28, size.height - 12));
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    double chartWidth,
    double leftGap,
    List<Offset> points,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final point = Offset(
        leftGap + points[i].dx * chartWidth,
        8 + points[i].dy * (size.height - 24),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Hoạt Động Gần Đây',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        SizedBox(height: 12),
        _ActivityItem(text: 'Yêu cầu sửa đèn: Đã gửi', time: '10:05'),
        _ActivityItem(text: 'Thông báo: Cúp điện (02/06)', time: '10:20'),
        _ActivityItem(text: 'Cài đặt tự động: Đã bật', time: '10:35'),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.text, required this.time});

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: _RoomControlScreenState._primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
}
