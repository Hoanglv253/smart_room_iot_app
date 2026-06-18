import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'admin_settings_widgets.dart';

class AdminPaymentSettingsScreen extends StatefulWidget {
  const AdminPaymentSettingsScreen({
    required this.bankNameController,
    required this.bankIdController,
    required this.bankAccountNumberController,
    required this.bankAccountHolderController,
    required this.transferContentController,
    required this.payosClientIdController,
    required this.payosApiKeyController,
    required this.payosChecksumKeyController,
    required this.payosConfigured,
    required this.payosStatusMessage,
    required this.onSaveBuilding,
    required this.onSavePayosSettings,
    required this.getPayosConfigured,
    required this.getPayosStatusMessage,
    super.key,
  });

  final TextEditingController bankNameController;
  final TextEditingController bankIdController;
  final TextEditingController bankAccountNumberController;
  final TextEditingController bankAccountHolderController;
  final TextEditingController transferContentController;
  final TextEditingController payosClientIdController;
  final TextEditingController payosApiKeyController;
  final TextEditingController payosChecksumKeyController;
  final bool payosConfigured;
  final String? payosStatusMessage;
  final Future<void> Function() onSaveBuilding;
  final Future<void> Function() onSavePayosSettings;
  final bool Function() getPayosConfigured;
  final String? Function() getPayosStatusMessage;

  @override
  State<AdminPaymentSettingsScreen> createState() =>
      _AdminPaymentSettingsScreenState();
}

class _AdminPaymentSettingsScreenState
    extends State<AdminPaymentSettingsScreen> {
  late bool _payosConfigured;
  late String? _payosStatusMessage;

  @override
  void initState() {
    super.initState();
    _payosConfigured = widget.payosConfigured;
    _payosStatusMessage = widget.payosStatusMessage;
  }

  Future<void> _savePayosSettings() async {
    await widget.onSavePayosSettings();
    if (!mounted) return;
    setState(() {
      _payosConfigured = widget.getPayosConfigured();
      _payosStatusMessage = widget.getPayosStatusMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bankName = _value(widget.bankNameController, 'Ngân hàng');
    final accountNumber = _value(widget.bankAccountNumberController, 'Chưa có STK');
    final accountHolder = _value(widget.bankAccountHolderController, 'Chủ tài khoản');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Thanh toán',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminSettingsHeroCard(
            icon: Icons.account_balance_outlined,
            title: bankName,
            subtitle: accountHolder,
            color: const Color(0xFFF59E0B),
            metrics: [
              AdminSettingsHeroPill(
                icon: Icons.credit_card_outlined,
                label: accountNumber,
              ),
              AdminSettingsHeroPill(
                icon: _payosConfigured
                    ? Icons.verified_outlined
                    : Icons.info_outline,
                label: _payosConfigured ? 'PayOS Đã cấu hình' : 'PayOS chưa cấu hình',
              ),
            ],
          ),
          AdminSettingsSection(
            title: 'Thông tin chuyển khoản',
            subtitle:
                'Người thuê sẽ nhìn thấy thông tin này trong chi tiết hóa đơn.',
            icon: Icons.payments_outlined,
            color: const Color(0xFFF59E0B),
            children: [
              AdminSettingsTextField(
                controller: widget.bankNameController,
                label: 'Tên ngân hàng',
                onChanged: (_) => setState(() {}),
              ),
              AdminSettingsTextField(
                controller: widget.bankIdController,
                label: 'Ma ngân hàng VietQR',
                helperText:
                    'Nhập BIN hoặc code ngân hàng, ví dụ MB, VCB, 970436.',
              ),
              AdminSettingsTextField(
                controller: widget.bankAccountNumberController,
                label: 'Số tài khoản',
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
              AdminSettingsTextField(
                controller: widget.bankAccountHolderController,
                label: 'Chủ tài khoản',
                onChanged: (_) => setState(() {}),
              ),
              AdminSettingsTextField(
                controller: widget.transferContentController,
                label: 'Nội dung chuyển khoản mẫu',
                helperText:
                    'Có thể dùng {room}, {month}, {year}, {name} để app tự thay.',
                maxLines: 2,
              ),
              AdminSettingsAsyncButton(
                onPressed: widget.onSaveBuilding,
                icon: Icons.save_outlined,
                label: 'Lưu thông tin chuyển khoản',
              ),
            ],
          ),
          AdminSettingsSection(
            title: 'PayOS từ dong',
            subtitle:
                'Dùng để PayOS báo webhook về backend và app tự xác nhận hóa đơn.',
            icon: Icons.verified_user_outlined,
            color: _payosConfigured
                ? AppColors.managerAccent
                : const Color(0xFFF59E0B),
            children: [
              AdminPayosStatusBox(
                configured: _payosConfigured,
                message:
                    _payosStatusMessage ??
                    'PayOS sẽ từ xác nhận hóa đơn khi ngân hàng bao giao dịch.',
              ),
              const SizedBox(height: 12),
              AdminSettingsTextField(
                controller: widget.payosClientIdController,
                label: 'Client ID PayOS',
                obscureText: true,
              ),
              AdminSettingsTextField(
                controller: widget.payosApiKeyController,
                label: 'API Key PayOS',
                obscureText: true,
              ),
              AdminSettingsTextField(
                controller: widget.payosChecksumKeyController,
                label: 'Checksum Key PayOS',
                obscureText: true,
                helperText:
                    'App không hiển thị lại key cũ. Nhập đủ 3 ô nếu muốn cập nhật.',
              ),
              AdminSettingsAsyncButton(
                onPressed: _savePayosSettings,
                icon: Icons.verified_user_outlined,
                label: _payosConfigured
                    ? 'Cập nhật PayOS'
                    : 'Lưu cấu hình PayOS',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _value(TextEditingController controller, String fallback) {
    final text = controller.text.trim();
    return text.isEmpty ? fallback : text;
  }
}
