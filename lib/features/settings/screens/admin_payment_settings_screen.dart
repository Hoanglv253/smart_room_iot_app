import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminSettingsSection(
            title: 'Thong tin chuyen khoan',
            subtitle:
                'Nguoi thue se nhin thay thong tin nay trong chi tiet hoa don.',
            children: [
              AdminSettingsTextField(
                controller: widget.bankNameController,
                label: 'Ten ngan hang',
              ),
              AdminSettingsTextField(
                controller: widget.bankIdController,
                label: 'Ma ngan hang VietQR',
                helperText:
                    'Nhap BIN hoac code ngan hang, vi du MB, VCB, 970436.',
              ),
              AdminSettingsTextField(
                controller: widget.bankAccountNumberController,
                label: 'So tai khoan',
                keyboardType: TextInputType.number,
              ),
              AdminSettingsTextField(
                controller: widget.bankAccountHolderController,
                label: 'Chu tai khoan',
              ),
              AdminSettingsTextField(
                controller: widget.transferContentController,
                label: 'Noi dung chuyen khoan mau',
                helperText:
                    'Co the dung {room}, {month}, {year}, {name} de app tu thay.',
                maxLines: 2,
              ),
              AdminSettingsAsyncButton(
                onPressed: widget.onSaveBuilding,
                icon: Icons.save_outlined,
                label: 'Luu thong tin chuyen khoan',
              ),
            ],
          ),
          AdminSettingsSection(
            title: 'PayOS tu dong',
            subtitle:
                'Dung de PayOS bao webhook ve backend va app tu xac nhan hoa don.',
            children: [
              AdminPayosStatusBox(
                configured: _payosConfigured,
                message:
                    _payosStatusMessage ??
                    'PayOS se tu xac nhan hoa don khi ngan hang bao giao dich.',
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
                    'App khong hien lai key cu. Nhap du 3 o neu muon cap nhat.',
              ),
              AdminSettingsAsyncButton(
                onPressed: _savePayosSettings,
                icon: Icons.verified_user_outlined,
                label: _payosConfigured
                    ? 'Cap nhat PayOS'
                    : 'Luu cau hinh PayOS',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
