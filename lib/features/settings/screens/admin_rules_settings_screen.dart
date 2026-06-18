import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Nội quy',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: rulesController,
            builder: (context, value, _) {
              final count = value.text.trim().length;
              return AdminSettingsHeroCard(
                icon: Icons.article_outlined,
                title: count > 0 ? '$count ký tự nội quy' : 'Soạn nội quy',
                subtitle:
                    'Nội quy sẽ được dùng lại trong thông báo, hợp đồng và thông tin phòng.',
                color: const Color(0xFF8B5CF6),
                metrics: [
                  AdminSettingsHeroPill(
                    icon: Icons.edit_note_outlined,
                    label: count > 0 ? 'Đã có nội dung' : 'Chưa có nội dung',
                  ),
                ],
              );
            },
          ),
          AdminSettingsSection(
            title: 'Nội quy tòa nhà',
            subtitle:
                'Nội quy này có thể dùng lại trong thông báo, hợp đồng và thông tin phòng sau này.',
            icon: Icons.rule_outlined,
            color: const Color(0xFF8B5CF6),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RuleTemplateChip(
                    label: 'Giờ giấc',
                    onTap: () => _appendTemplate(
                      'Giờ giấc: Giữ yên lặng sau 22h, không gây ồn ảnh hưởng phòng khác.',
                    ),
                  ),
                  _RuleTemplateChip(
                    label: 'Khách',
                    onTap: () => _appendTemplate(
                      'Khách đến chơi cần báo trước với quản lý và không ở lại qua đêm nếu chưa được đồng ý.',
                    ),
                  ),
                  _RuleTemplateChip(
                    label: 'Vệ sinh',
                    onTap: () => _appendTemplate(
                      'Vệ sinh: Giữ gìn khu vực chung, đổ rác đúng nơi quy định.',
                    ),
                  ),
                  _RuleTemplateChip(
                    label: 'An ninh',
                    onTap: () => _appendTemplate(
                      'An ninh: Tự bảo quản tài sản cá nhân, khóa cửa khi ra ngoài.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AdminSettingsTextField(
                controller: rulesController,
                label: 'Nội quy tòa nhà',
                maxLines: 10,
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: rulesController,
                builder: (context, value, _) {
                  return Text(
                    '${value.text.trim().length} ký tự - sẽ hiển thị cho người thuê khi xem phòng.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
            ],
          ),
          AdminSettingsAsyncButton(
            onPressed: onSave,
            icon: Icons.save_outlined,
            label: 'Lưu nội quy',
          ),
        ],
      ),
    );
  }

  void _appendTemplate(String template) {
    final current = rulesController.text.trim();
    final next = current.isEmpty ? template : '$current\n\n$template';
    rulesController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }
}

class _RuleTemplateChip extends StatelessWidget {
  const _RuleTemplateChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: const Icon(Icons.add, size: 17),
      label: Text(label),
      backgroundColor: AppColors.primarySoft,
      side: const BorderSide(color: AppColors.border),
      labelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
