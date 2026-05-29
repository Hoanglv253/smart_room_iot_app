import 'package:flutter/material.dart';

import '../../../core/data/vietnam_admin_units.dart';

class AdminSettingsMenuTile extends StatelessWidget {
  const AdminSettingsMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class AdminSettingsSection extends StatelessWidget {
  const AdminSettingsSection({
    required this.title,
    required this.children,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class AdminSettingsTextField extends StatelessWidget {
  const AdminSettingsTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
    this.helperText,
    this.onChanged,
    this.obscureText = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        obscureText: obscureText,
        enableSuggestions: !obscureText,
        autocorrect: !obscureText,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class AdminProvinceDropdown extends StatelessWidget {
  const AdminProvinceDropdown({
    required this.controller,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final currentValue = controller.text.trim();
    final names =
        currentValue.isNotEmpty && !vietnamProvinceNames.contains(currentValue)
        ? [currentValue, ...vietnamProvinceNames]
        : vietnamProvinceNames;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: currentValue.isEmpty ? null : currentValue,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Tinh/thanh pho',
          helperText: 'Dung cho bo loc khu vuc va dia chi moi.',
          border: OutlineInputBorder(),
        ),
        items: names
            .map(
              (name) =>
                  DropdownMenuItem<String>(value: name, child: Text(name)),
            )
            .toList(),
        onChanged: (value) {
          final nextValue = value ?? '';
          controller.text = nextValue;
          onChanged?.call(nextValue);
        },
      ),
    );
  }
}

class AdminSettingsSwitch extends StatelessWidget {
  const AdminSettingsSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

class AdminLocationPickerButton extends StatelessWidget {
  const AdminLocationPickerButton({
    required this.location,
    required this.onPressed,
    super.key,
  });

  final Map<String, dynamic> location;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final lat = _readDouble(location['lat']);
    final lng = _readDouble(location['lng']);
    final hasLocation = lat != null && lng != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(
              hasLocation ? 'Doi vi tri tren ban do' : 'Chon tren ban do',
            ),
          ),
          if (hasLocation) ...[
            const SizedBox(height: 6),
            Text(
              'Toa do da chon: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  static double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class AdminPayosStatusBox extends StatelessWidget {
  const AdminPayosStatusBox({
    required this.configured,
    required this.message,
    super.key,
  });

  final bool configured;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = configured ? Colors.green : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            configured ? Icons.check_circle_outline : Icons.info_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class AdminSettingsAsyncButton extends StatefulWidget {
  const AdminSettingsAsyncButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.expanded = true,
    super.key,
  });

  final Future<void> Function() onPressed;
  final IconData icon;
  final String label;
  final bool expanded;

  @override
  State<AdminSettingsAsyncButton> createState() =>
      _AdminSettingsAsyncButtonState();
}

class _AdminSettingsAsyncButtonState extends State<AdminSettingsAsyncButton> {
  bool _isBusy = false;

  Future<void> _handlePressed() async {
    if (_isBusy) return;

    setState(() => _isBusy = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: _isBusy ? null : _handlePressed,
      icon: _isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(widget.icon),
      label: Text(widget.label),
    );

    if (!widget.expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class AdminPermissionErrorView extends StatelessWidget {
  const AdminPermissionErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: Colors.redAccent, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thu lai'),
            ),
          ],
        ),
      ),
    );
  }
}
