import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/screens/profile_screen.dart';

class BasicSettingsScreen extends StatefulWidget {
  const BasicSettingsScreen({
    required this.user,
    required this.role,
    required this.onLogout,
    super.key,
  });

  final User user;
  final String role;
  final Future<void> Function(BuildContext context) onLogout;

  @override
  State<BasicSettingsScreen> createState() => _BasicSettingsScreenState();
}

class _BasicSettingsScreenState extends State<BasicSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _sendingPasswordReset = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: AppFirestoreService.users.doc(widget.user.uid).snapshots(),
      builder: (context, snapshot) {
        final profile = snapshot.data?.data() ?? <String, dynamic>{};
        final config = _SettingsRoleConfig.fromRole(widget.role);
        final name = _displayName(profile, widget.user);
        final email = _email(profile, widget.user);
        final avatarUrl = _text(profile['avatarUrl']);
        final contextLine = _contextLine(profile, config);
        final verifiedLabel =
            widget.user.emailVerified ? 'Đã xác minh' : 'Cần xác minh';

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Text(
              'Cài đặt tài khoản',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Quản lý profile, bảo mật và tùy chọn cá nhân của bạn.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (snapshot.hasError) ...[
              const SizedBox(height: 12),
              const _SettingsNotice(
                icon: Icons.cloud_off_outlined,
                text: 'Không tải được profile mới nhất, Đang hiển thị dữ liệu có sẵn.',
              ),
            ],
            const SizedBox(height: 16),
            _AccountHeroCard(
              config: config,
              name: name,
              email: email,
              avatarUrl: avatarUrl,
              contextLine: contextLine,
              onEdit: () => _openProfile(profile, config),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SettingsQuickPill(
                    icon: Icons.notifications_active_outlined,
                    label: _notificationsEnabled
                        ? 'Thông báo bật'
                        : 'Thông báo tắt',
                    color: config.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SettingsQuickPill(
                    icon: config.secondaryPillIcon,
                    label: config.isTenant ? verifiedLabel : 'Đang hoạt động',
                    color: config.secondaryAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'Tài khoản',
              children: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  color: config.accent,
                  title: 'Thông tin có nhạn',
                  subtitle: 'Tên, số điện thoại, email',
                  onTap: () => _openProfile(profile, config),
                ),
                _SettingsTile(
                  icon: Icons.photo_camera_outlined,
                  color: config.secondaryAccent,
                  title: 'Ảnh đại diện',
                  subtitle: 'Cập nhật ảnh profile',
                  onTap: () => _openProfile(profile, config),
                ),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  color: const Color(0xFFF59E0B),
                  title: 'Bảo mật',
                  subtitle: 'Đổi mật khẩu',
                  trailing: _sendingPasswordReset
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _sendingPasswordReset
                      ? null
                      : () => _sendPasswordReset(email),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SettingsSection(
              title: 'Tùy chọn',
              children: [
                _SettingsSwitchTile(
                  icon: Icons.notifications_none_outlined,
                  color: config.accent,
                  title: 'Thông báo',
                  subtitle: config.notificationSubtitle,
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    _showMessage(
                      value ? 'Đã bật thông báo.' : 'Đã tắt thông báo.',
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.language_outlined,
                  color: const Color(0xFF0EA5E9),
                  title: 'Ngôn ngữ',
                  subtitle: 'Tiếng Việt',
                  onTap: () => _showMessage('Ứng dụng đang dùng Tiếng Việt.'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _LogoutTile(onTap: _confirmLogout),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'Phiên bản 1.0.0',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openProfile(
    Map<String, dynamic> profile,
    _SettingsRoleConfig config,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          user: widget.user,
          roleLabel: config.roleLabel,
          avatarText: config.avatarText,
          avatarColor: config.avatarColor,
          avatarTextColor: config.accent,
          initialProfile: profile,
        ),
      ),
    );
  }

  Future<void> _sendPasswordReset(String email) async {
    if (email.isEmpty) {
      _showMessage('Tài khoản này chưa có email.');
      return;
    }

    setState(() => _sendingPasswordReset = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showMessage('Đã gửi email đặt lại mật khẩu.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Không gửi được email đặt lại mật khẩu.');
    } finally {
      if (mounted) setState(() => _sendingPasswordReset = false);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc muốn Đăng xuất tài khoản này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      await widget.onLogout(context);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _contextLine(
    Map<String, dynamic> profile,
    _SettingsRoleConfig config,
  ) {
    final buildingName = _text(profile['buildingName']);
    if (!config.isTenant) {
      return buildingName.isEmpty
          ? 'Quản lý tòa nhà'
          : 'Quản lý $buildingName';
    }

    final roomName = _text(profile['roomName']);
    if (roomName.isNotEmpty && buildingName.isNotEmpty) {
      return '$roomName - $buildingName';
    }
    if (roomName.isNotEmpty) return roomName;
    if (buildingName.isNotEmpty) return 'Đang ở $buildingName';
    return 'Chưa gắn phòng';
  }

  static String _displayName(Map<String, dynamic> profile, User user) {
    final displayName = _text(profile['displayName']);
    if (displayName.isNotEmpty) return displayName;

    final name = _text(profile['name']);
    if (name.isNotEmpty) return name;

    final authName = user.displayName?.trim() ?? '';
    if (authName.isNotEmpty) return authName;

    return user.email ?? 'Tài khoản';
  }

  static String _email(Map<String, dynamic> profile, User user) {
    final email = _text(profile['email']);
    if (email.isNotEmpty) return email;
    return user.email ?? '';
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';
}

class _SettingsRoleConfig {
  const _SettingsRoleConfig({
    required this.roleLabel,
    required this.roleChip,
    required this.avatarText,
    required this.accent,
    required this.secondaryAccent,
    required this.avatarColor,
    required this.heroColors,
    required this.notificationSubtitle,
    required this.secondaryPillIcon,
    required this.isTenant,
  });

  factory _SettingsRoleConfig.fromRole(String role) {
    if (role == UserRole.manager) {
      return const _SettingsRoleConfig(
        roleLabel: 'Quản lý',
        roleChip: 'Quản lý',
        avatarText: 'QL',
        accent: Color(0xFF2168F3),
        secondaryAccent: Color(0xFF0EA5E9),
        avatarColor: Color(0xFFE0F2FE),
        heroColors: [Color(0xFF2168F3), Color(0xFF0EA5E9)],
        notificationSubtitle: 'Tin nhắn, yêu cầu, thông báo tòa nhà',
        secondaryPillIcon: Icons.verified_user_outlined,
        isTenant: false,
      );
    }

    return const _SettingsRoleConfig(
      roleLabel: 'Người thuê',
      roleChip: 'Người thuê',
      avatarText: 'NT',
      accent: Color(0xFF16A34A),
      secondaryAccent: Color(0xFF2168F3),
      avatarColor: Color(0xFFDCFCE7),
      heroColors: [Color(0xFF16A34A), Color(0xFF2168F3)],
      notificationSubtitle: 'Hóa đơn, tin nhắn, thông báo phòng',
      secondaryPillIcon: Icons.verified_outlined,
      isTenant: true,
    );
  }

  final String roleLabel;
  final String roleChip;
  final String avatarText;
  final Color accent;
  final Color secondaryAccent;
  final Color avatarColor;
  final List<Color> heroColors;
  final String notificationSubtitle;
  final IconData secondaryPillIcon;
  final bool isTenant;
}

class _AccountHeroCard extends StatelessWidget {
  const _AccountHeroCard({
    required this.config,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.contextLine,
    required this.onEdit,
  });

  final _SettingsRoleConfig config;
  final String name;
  final String email;
  final String avatarUrl;
  final String contextLine;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: config.heroColors,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: config.accent.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -28,
            child: Icon(
              Icons.account_circle_rounded,
              color: Colors.white.withValues(alpha: 0.12),
              size: 148,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SettingsAvatar(
                    avatarUrl: avatarUrl,
                    fallback: config.avatarText,
                    backgroundColor: config.avatarColor,
                    textColor: config.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email.isEmpty ? 'Chưa có email' : email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFEAF1FF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroChip(
                    icon: Icons.badge_outlined,
                    label: config.roleChip,
                  ),
                  _HeroChip(
                    icon: config.isTenant
                        ? Icons.meeting_room_outlined
                        : Icons.apartment_outlined,
                    label: contextLine,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsAvatar extends StatelessWidget {
  const _SettingsAvatar({
    required this.avatarUrl,
    required this.fallback,
    required this.backgroundColor,
    required this.textColor,
  });

  final String avatarUrl;
  final String fallback;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 31,
      backgroundColor: backgroundColor,
      backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
      child: avatarUrl.isEmpty
          ? Text(
              fallback,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsQuickPill extends StatelessWidget {
  const _SettingsQuickPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              _SettingsIconBox(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          _SettingsIconBox(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsIconBox extends StatelessWidget {
  const _SettingsIconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Row(
            children: [
              _SettingsIconBox(
                icon: Icons.logout_rounded,
                color: Color(0xFFDC2626),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFFDC2626)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsNotice extends StatelessWidget {
  const _SettingsNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
