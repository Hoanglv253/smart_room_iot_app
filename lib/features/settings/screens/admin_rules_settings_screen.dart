import 'package:flutter/material.dart';

import 'admin_settings_widgets.dart';

class AdminRulesSettingsScreen extends StatelessWidget {
  const AdminRulesSettingsScreen({
    required this.rulesController,
    required this.onSave,
    super.key,
  });

  final TextEditingController rulesController;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Noi quy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminSettingsSection(
            title: 'Noi quy toa nha',
            subtitle:
                'Noi quy nay co the dung lai trong thong bao, hop dong va thong tin phong sau nay.',
            children: [
              AdminSettingsTextField(
                controller: rulesController,
                label: 'Noi quy toa nha',
                maxLines: 8,
              ),
            ],
          ),
          AdminSettingsAsyncButton(
            onPressed: onSave,
            icon: Icons.save_outlined,
            label: 'Luu noi quy',
          ),
        ],
      ),
    );
  }
}
