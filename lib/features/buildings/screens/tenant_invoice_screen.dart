import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/app_firestore_service.dart';
import '../view_models/invoice_list_view_model.dart';
import '../view_models/tenant_invoice_detail_view_model.dart';

const _allInvoiceStatus = 'all';
const _payosBackendBaseUrl = String.fromEnvironment(
  'PAYOS_BACKEND_URL',
  defaultValue: '',
);

class _InvoiceStatusOption {
  const _InvoiceStatusOption(this.value, this.label);

  final String value;
  final String label;
}

const _invoiceStatusOptions = [
  _InvoiceStatusOption(_allInvoiceStatus, 'Tat ca'),
  _InvoiceStatusOption(InvoiceStatus.unpaid, 'Chua TT'),
  _InvoiceStatusOption(InvoiceStatus.waitingPayment, 'Dang TT'),
  _InvoiceStatusOption(InvoiceStatus.pending, 'Cho xac nhan'),
  _InvoiceStatusOption(InvoiceStatus.paid, 'Da TT'),
  _InvoiceStatusOption(InvoiceStatus.overdue, 'Qua han'),
];

class TenantInvoiceScreen extends StatefulWidget {
  const TenantInvoiceScreen({
    required this.user,
    required this.buildingId,
    required this.roomId,
    super.key,
  });

  final User user;
  final String buildingId;
  final String roomId;

  @override
  State<TenantInvoiceScreen> createState() => _TenantInvoiceScreenState();
}

class _TenantInvoiceScreenState extends State<TenantInvoiceScreen> {
  final _viewModel = InvoiceListViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hoa don cua toi')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _viewModel.tenantInvoices(
              buildingId: widget.buildingId,
              tenantId: widget.user.uid,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _TenantInvoiceEmptyView(
                  icon: Icons.lock_outline,
                  message: 'Khong tai duoc hoa don.',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final invoices = _viewModel.sortInvoices(
                (snapshot.data?.docs ?? []).where((doc) {
                  return doc.data()['roomId'] == widget.roomId;
                }),
              );
              final yearOptions = _viewModel.yearOptions(invoices);
              final periodPicker = _TenantInvoicePeriodPicker(
                month: _viewModel.selectedMonth,
                year: _viewModel.selectedYear,
                years: yearOptions,
                onMonthChanged: (value) {
                  if (value == null) return;
                  _viewModel.setMonth(value);
                },
                onYearChanged: (value) {
                  if (value == null) return;
                  _viewModel.setYear(value);
                },
              );

              if (invoices.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    periodPicker,
                    const _TenantInvoiceEmptyView(
                      icon: Icons.receipt_long_outlined,
                      message: 'Phong cua ban chua co hoa don.',
                    ),
                  ],
                );
              }

              final monthlyInvoices = _viewModel.monthlyInvoices(invoices);
              final filteredInvoices = _viewModel.filteredInvoices(
                monthlyInvoices,
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  periodPicker,
                  const SizedBox(height: 12),
                  _TenantInvoiceStatusFilterBar(
                    invoices: monthlyInvoices,
                    selectedStatus: _viewModel.selectedStatus,
                    onChanged: _viewModel.setStatus,
                  ),
                  const SizedBox(height: 12),
                  if (filteredInvoices.isEmpty)
                    _TenantInvoiceEmptyView(
                      icon: Icons.event_busy_outlined,
                      message:
                          'Khong co hoa don ${_statusFilterText(_viewModel.selectedStatus)}trong thang ${_viewModel.selectedMonth}/${_viewModel.selectedYear}.',
                    )
                  else ...[
                    _TenantInvoiceMonthHeader(
                      data: {
                        'month': _viewModel.selectedMonth,
                        'year': _viewModel.selectedYear,
                      },
                      invoiceCount: filteredInvoices.length,
                      totalAmount: filteredInvoices.fold<int>(
                        0,
                        (total, doc) =>
                            total + _readInt(doc.data()['totalAmount']),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...filteredInvoices.map((doc) {
                      final data = doc.data();
                      final status =
                          (data['status'] ?? InvoiceStatus.unpaid).toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _statusColor(status).withValues(alpha: 0.14),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                color: _statusColor(status),
                              ),
                            ),
                            title: Text(_periodLabel(data)),
                            subtitle: Text(_statusLabel(status)),
                            trailing: Text(
                              _money(data['totalAmount']),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => _TenantInvoiceDetailScreen(
                                    buildingId: widget.buildingId,
                                    invoiceId: doc.id,
                                    invoice: data,
                                    user: widget.user,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TenantInvoiceStatusFilterBar extends StatelessWidget {
  const _TenantInvoiceStatusFilterBar({
    required this.invoices,
    required this.selectedStatus,
    required this.onChanged,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> invoices;
  final String selectedStatus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in _invoiceStatusOptions) ...[
            ChoiceChip(
              label: Text('${option.label} (${_count(option.value)})'),
              selected: selectedStatus == option.value,
              onSelected: (_) => onChanged(option.value),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  int _count(String status) {
    if (status == _allInvoiceStatus) return invoices.length;

    return invoices.where((doc) {
      final dataStatus =
          (doc.data()['status'] ?? InvoiceStatus.unpaid).toString();
      return dataStatus == status;
    }).length;
  }
}

class _TenantInvoicePeriodPicker extends StatelessWidget {
  const _TenantInvoicePeriodPicker({
    required this.month,
    required this.year,
    required this.years,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  final int month;
  final int year;
  final List<int> years;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<int?> onYearChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Thang',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: month,
                    isDense: true,
                    isExpanded: true,
                    items: [
                      for (var index = 1; index <= 12; index++)
                        DropdownMenuItem(
                          value: index,
                          child: Text('Thang $index'),
                        ),
                    ],
                    onChanged: onMonthChanged,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Nam',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: year,
                    isDense: true,
                    isExpanded: true,
                    items: [
                      for (final item in years)
                        DropdownMenuItem(
                          value: item,
                          child: Text(item.toString()),
                        ),
                    ],
                    onChanged: onYearChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenantInvoiceMonthHeader extends StatelessWidget {
  const _TenantInvoiceMonthHeader({
    required this.data,
    required this.invoiceCount,
    required this.totalAmount,
  });

  final Map<String, dynamic> data;
  final int invoiceCount;
  final int totalAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _periodLabel(data),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$invoiceCount hoa don',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            _money(totalAmount),
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantInvoiceDetailScreen extends StatefulWidget {
  const _TenantInvoiceDetailScreen({
    required this.buildingId,
    required this.invoiceId,
    required this.invoice,
    required this.user,
  });

  final String buildingId;
  final String invoiceId;
  final Map<String, dynamic> invoice;
  final User user;

  @override
  State<_TenantInvoiceDetailScreen> createState() =>
      _TenantInvoiceDetailScreenState();
}

class _TenantInvoiceDetailScreenState extends State<_TenantInvoiceDetailScreen> {
  final _noteController = TextEditingController();
  final _viewModel = TenantInvoiceDetailViewModel();

  @override
  void dispose() {
    _noteController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _reportPaid() async {
    final sent = await _viewModel.reportManualPayment(
      buildingId: widget.buildingId,
      invoiceId: widget.invoiceId,
      note: _noteController.text,
    );

    if (!mounted) return;
    if (sent) {
      Navigator.of(context).pop();
      return;
    }

    _showSnack(_tenantPaymentError());
  }

  Future<void> _startPayosPayment() async {
    final uri = await _viewModel.createPayosPayment(
      backendBaseUrl: _payosBackendBaseUrl,
      user: widget.user,
      buildingId: widget.buildingId,
      invoiceId: widget.invoiceId,
    );
    if (!mounted || uri == null) {
      if (_viewModel.errorMessage != null) _showSnack(_payosErrorMessage());
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      _showSnack('Khong mo duoc link thanh toan PayOS.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: AppFirestoreService.buildingInvoices(
        widget.buildingId,
      ).doc(widget.invoiceId).snapshots(),
      builder: (context, snapshot) {
        final invoice = snapshot.data?.data() ?? widget.invoice;
        final status = (invoice['status'] ?? InvoiceStatus.unpaid).toString();
        final paymentNote = (invoice['paymentNote'] ?? '').toString();
        final canPayOnline = status == InvoiceStatus.unpaid ||
            status == InvoiceStatus.waitingPayment;

        return Scaffold(
          appBar: AppBar(title: const Text('Chi tiet hoa don')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TenantInvoiceHeader(data: invoice),
              const SizedBox(height: 12),
              _TenantInvoiceSection(
                title: 'Thong tin',
                children: [
                  _InfoRow(
                    label: 'Phong',
                    value: _text(invoice['roomName'], ''),
                  ),
                  _InfoRow(label: 'Ky hoa don', value: _periodLabel(invoice)),
                  _InfoRow(
                    label: 'Han thanh toan',
                    value: _dateText(invoice['dueDate']),
                  ),
                  _InfoRow(label: 'Trang thai', value: _statusLabel(status)),
                ],
              ),
              const SizedBox(height: 12),
              _TenantInvoiceSection(
                title: 'Chi tiet thanh toan',
                children: [
                  _InfoRow(
                    label: 'Tien phong',
                    value: _money(invoice['roomRent']),
                  ),
                  _InfoRow(
                    label: 'Tien dien',
                    value:
                        '${_readInt(invoice['electricityUsage'])} so - ${_money(invoice['electricityAmount'])}',
                  ),
                  _InfoRow(
                    label: 'Tien nuoc',
                    value:
                        '${_readInt(invoice['waterUsage'])} so - ${_money(invoice['waterAmount'])}',
                  ),
                  _InfoRow(
                    label: 'Phi dich vu',
                    value: _money(invoice['serviceFee']),
                  ),
                  _InfoRow(
                    label: 'Internet',
                    value: _money(invoice['internetFee']),
                  ),
                  _InfoRow(
                    label: 'Gui xe',
                    value: _money(invoice['parkingFee']),
                  ),
                  _InfoRow(label: 'Phu thu', value: _money(invoice['otherFee'])),
                  _InfoRow(label: 'Giam tru', value: _money(invoice['discount'])),
                ],
              ),
              const SizedBox(height: 12),
              _TotalBox(total: _readInt(invoice['totalAmount'])),
              if (canPayOnline || status == InvoiceStatus.pending) ...[
                const SizedBox(height: 12),
                _PaymentInstructionSection(
                  buildingId: widget.buildingId,
                  invoice: invoice,
                  viewModel: _viewModel,
                ),
              ],
              if (canPayOnline) ...[
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _viewModel,
                  builder: (context, _) {
                    return FilledButton.icon(
                      onPressed: _viewModel.isCreatingPayosPayment
                          ? null
                          : _startPayosPayment,
                      icon: _viewModel.isCreatingPayosPayment
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.payment_outlined),
                      label: Text(
                        status == InvoiceStatus.waitingPayment
                            ? 'Mo lai thanh toan PayOS'
                            : 'Thanh toan tu dong PayOS',
                      ),
                    );
                  },
                ),
              ],
              if (paymentNote.isNotEmpty) ...[
                const SizedBox(height: 12),
                _TenantInvoiceSection(
                  title: 'Ghi chu da gui',
                  children: [_InfoRow(label: 'Noi dung', value: paymentNote)],
                ),
              ],
              if (status == InvoiceStatus.unpaid) ...[
                const SizedBox(height: 16),
                if (invoice['paymentRejectedAt'] != null) ...[
                  const _PaymentRejectedNotice(),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chu / ma giao dich',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _viewModel,
                  builder: (context, _) {
                    return FilledButton.icon(
                      onPressed: _viewModel.isLoading ? null : _reportPaid,
                      icon: _viewModel.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.payments_outlined),
                      label: const Text('Bao da thanh toan'),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _tenantPaymentError() {
    final error = _viewModel.errorMessage;
    if (error?.contains('permission-denied') == true) {
      return 'Firestore chua cap quyen bao da thanh toan.';
    }

    return 'Khong gui duoc thong tin thanh toan.';
  }

  String _payosErrorMessage() {
    final error = _viewModel.errorMessage ?? '';
    return error
        .replaceFirst('TimeoutException: ', '')
        .replaceFirst('Exception: ', '');
  }
}

class _PaymentRejectedNotice extends StatelessWidget {
  const _PaymentRejectedNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Thanh toan truoc do chua duoc xac nhan. Ban co the gui lai thong tin thanh toan.',
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentInstructionSection extends StatelessWidget {
  const _PaymentInstructionSection({
    required this.buildingId,
    required this.invoice,
    required this.viewModel,
  });

  final String buildingId;
  final Map<String, dynamic> invoice;
  final TenantInvoiceDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: viewModel.building(buildingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _TenantInvoiceSection(
            title: 'Huong dan thanh toan',
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            ],
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const _TenantInvoiceSection(
            title: 'Huong dan thanh toan',
            children: [
              _InfoRow(
                label: 'Trang thai',
                value: 'Chua tai duoc thong tin chuyen khoan.',
              ),
            ],
          );
        }

        final building = snapshot.data!;
        final settings = _readMap(building['paymentSettings']);
        final bankName = _text(settings['bankName'], 'Chua thiet lap');
        final bankId = _text(settings['bankId'], '');
        final accountNumber =
            _text(settings['bankAccountNumber'], 'Chua thiet lap');
        final accountHolder =
            _text(settings['bankAccountHolder'], 'Chua thiet lap');
        final transferContent = _transferContent(
          settings['transferContentTemplate'],
          invoice,
        );
        final amount = _readInt(invoice['totalAmount']);
        final canCreateVietQr = bankId.isNotEmpty &&
            accountNumber != 'Chua thiet lap' &&
            accountHolder != 'Chua thiet lap' &&
            amount > 0;

        return _TenantInvoiceSection(
          title: 'Huong dan thanh toan',
          children: [
            _InfoRow(label: 'Ngan hang', value: bankName),
            if (bankId.isNotEmpty) _InfoRow(label: 'Ma VietQR', value: bankId),
            _InfoRow(label: 'So tai khoan', value: accountNumber),
            _InfoRow(label: 'Chu tai khoan', value: accountHolder),
            _InfoRow(label: 'So tien', value: _money(amount)),
            _InfoRow(label: 'Noi dung', value: transferContent),
            const SizedBox(height: 12),
            if (canCreateVietQr)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () {
                    _showVietQrDialog(
                      context: context,
                      bankId: bankId,
                      accountNumber: accountNumber,
                      accountHolder: accountHolder,
                      amount: amount,
                      transferContent: transferContent,
                    );
                  },
                  icon: const Icon(Icons.qr_code_2_outlined),
                  label: const Text('Tao ma QR VietQR'),
                ),
              )
            else
              const _VietQrMissingNotice(),
          ],
        );
      },
    );
  }

  void _showVietQrDialog({
    required BuildContext context,
    required String bankId,
    required String accountNumber,
    required String accountHolder,
    required int amount,
    required String transferContent,
  }) {
    final url = _vietQrUrl(
      bankId: bankId,
      accountNumber: accountNumber,
      accountHolder: accountHolder,
      amount: amount,
      transferContent: transferContent,
    );

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ma QR VietQR'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    width: 260,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Khong tai duoc ma QR. Hay kiem tra ma ngan hang VietQR.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(label: 'So tien', value: _money(amount)),
                _InfoRow(label: 'Noi dung', value: transferContent),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Dong'),
            ),
          ],
        );
      },
    );
  }
}

class _VietQrMissingNotice extends StatelessWidget {
  const _VietQrMissingNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.22)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Admin can nhap ma ngan hang VietQR, so tai khoan va chu tai khoan de tao QR.',
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantInvoiceHeader extends StatelessWidget {
  const _TenantInvoiceHeader({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? InvoiceStatus.unpaid).toString();

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _money(data['totalAmount']),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(_statusLabel(status)),
              backgroundColor: _statusColor(status).withValues(alpha: 0.12),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenantInvoiceSection extends StatelessWidget {
  const _TenantInvoiceSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalBox extends StatelessWidget {
  const _TotalBox({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Tong thanh toan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            _money(total),
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantInvoiceEmptyView extends StatelessWidget {
  const _TenantInvoiceEmptyView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.blueAccent, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _periodLabel(Map<String, dynamic> data) {
  final month = _readInt(data['month']);
  final year = _readInt(data['year']);
  return month > 0 && year > 0 ? 'Thang $month/$year' : 'Chua co ky';
}

String _dateText(Object? value) {
  if (value is! Timestamp) return 'Chua co';
  final date = value.toDate();
  return '${date.day}/${date.month}/${date.year}';
}

String _statusLabel(String status) {
  return switch (status) {
    InvoiceStatus.waitingPayment => 'Dang thanh toan PayOS',
    InvoiceStatus.pending => 'Cho xac nhan',
    InvoiceStatus.paid => 'Da thanh toan',
    InvoiceStatus.overdue => 'Qua han',
    InvoiceStatus.cancelled => 'Da huy',
    _ => 'Chua thanh toan',
  };
}

String _statusFilterText(String status) {
  return switch (status) {
    InvoiceStatus.unpaid => 'chua thanh toan ',
    InvoiceStatus.waitingPayment => 'dang thanh toan ',
    InvoiceStatus.pending => 'cho xac nhan ',
    InvoiceStatus.paid => 'da thanh toan ',
    InvoiceStatus.overdue => 'qua han ',
    InvoiceStatus.cancelled => 'da huy ',
    _ => '',
  };
}

Color _statusColor(String status) {
  return switch (status) {
    InvoiceStatus.waitingPayment => Colors.purple,
    InvoiceStatus.pending => Colors.orange,
    InvoiceStatus.paid => Colors.green,
    InvoiceStatus.overdue => Colors.redAccent,
    InvoiceStatus.cancelled => Colors.grey,
    _ => Colors.blueAccent,
  };
}

String _money(Object? value) {
  final amount = _readInt(value);
  return '$amount VND';
}

String _text(Object? value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, dynamic value) => MapEntry(key.toString(), value));
  }
  return {};
}

String _transferContent(Object? template, Map<String, dynamic> invoice) {
  final rawTemplate = template?.toString().trim() ?? '';
  final month = _readInt(invoice['month']);
  final year = _readInt(invoice['year']);
  final room = _text(invoice['roomName'], 'Phong');
  final tenantName = _text(invoice['tenantName'], 'Nguoi thue');
  final fallback = 'Thanh toan $room thang $month/$year';

  final resolvedTemplate = rawTemplate.isEmpty ? fallback : rawTemplate;
  return resolvedTemplate
      .replaceAll('{room}', room)
      .replaceAll('{month}', month.toString())
      .replaceAll('{year}', year.toString())
      .replaceAll('{name}', tenantName);
}

String _vietQrUrl({
  required String bankId,
  required String accountNumber,
  required String accountHolder,
  required int amount,
  required String transferContent,
}) {
  final compactBankId = bankId.trim();
  final compactAccountNumber = accountNumber.trim().replaceAll(' ', '');
  final query = <String, String>{
    'amount': amount.toString(),
    'addInfo': transferContent,
    'accountName': accountHolder,
  };

  return Uri.https(
    'img.vietqr.io',
    '/image/$compactBankId-$compactAccountNumber-compact2.png',
    query,
  ).toString();
}

int _readInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
