import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/theme/app_theme.dart';
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
  _InvoiceStatusOption(_allInvoiceStatus, 'Tất cả'),
  _InvoiceStatusOption(InvoiceStatus.unpaid, 'Chưa TT'),
  _InvoiceStatusOption(InvoiceStatus.waitingPayment, 'Đang TT'),
  _InvoiceStatusOption(InvoiceStatus.pending, 'Cho xác nhận'),
  _InvoiceStatusOption(InvoiceStatus.paid, 'Đã TT'),
  _InvoiceStatusOption(InvoiceStatus.overdue, 'Quá hạn'),
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
      appBar: AppBar(
        title: const Text('Hóa đơn của tôi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
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
                  message: 'Không tải được hóa đơn.',
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
              final monthlyInvoices = _viewModel.monthlyInvoices(invoices);
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _TenantInvoiceHeroCard(
                      month: _viewModel.selectedMonth,
                      year: _viewModel.selectedYear,
                      invoiceCount: 0,
                      totalAmount: 0,
                      paidCount: 0,
                      dueCount: 0,
                    ),
                    const SizedBox(height: 14),
                    periodPicker,
                    const SizedBox(height: 14),
                    const _TenantInvoiceEmptyView(
                      icon: Icons.receipt_long_outlined,
                      message: 'Phòng của bạn chưa có hóa đơn.',
                    ),
                  ],
                );
              }

              final filteredInvoices = _viewModel.filteredInvoices(
                monthlyInvoices,
              );
              final monthlyTotal = monthlyInvoices.fold<int>(
                0,
                (total, doc) => total + _readInt(doc.data()['totalAmount']),
              );
              final paidCount = monthlyInvoices.where((doc) {
                return (doc.data()['status'] ?? InvoiceStatus.unpaid)
                        .toString() ==
                    InvoiceStatus.paid;
              }).length;
              final dueCount = monthlyInvoices.length - paidCount;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _TenantInvoiceHeroCard(
                    month: _viewModel.selectedMonth,
                    year: _viewModel.selectedYear,
                    invoiceCount: monthlyInvoices.length,
                    totalAmount: monthlyTotal,
                    paidCount: paidCount,
                    dueCount: dueCount,
                  ),
                  const SizedBox(height: 14),
                  periodPicker,
                  const SizedBox(height: 14),
                  _TenantInvoiceStatusFilterBar(
                    invoices: monthlyInvoices,
                    selectedStatus: _viewModel.selectedStatus,
                    onChanged: _viewModel.setStatus,
                  ),
                  const SizedBox(height: 14),
                  if (filteredInvoices.isEmpty)
                    _TenantInvoiceEmptyView(
                      icon: Icons.event_busy_outlined,
                      message:
                          'Không có hóa đơn ${_statusFilterText(_viewModel.selectedStatus)}trong tháng ${_viewModel.selectedMonth}/${_viewModel.selectedYear}.',
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
                    const SizedBox(height: 10),
                    ...filteredInvoices.map((doc) {
                      final data = doc.data();
                      final status =
                          (data['status'] ?? InvoiceStatus.unpaid).toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TenantInvoiceCard(
                          data: data,
                          status: status,
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

class _TenantInvoiceHeroCard extends StatelessWidget {
  const _TenantInvoiceHeroCard({
    required this.month,
    required this.year,
    required this.invoiceCount,
    required this.totalAmount,
    required this.paidCount,
    required this.dueCount,
  });

  final int month;
  final int year;
  final int invoiceCount;
  final int totalAmount;
  final int paidCount;
  final int dueCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient(),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -32,
            child: Icon(
              Icons.receipt_long_rounded,
              color: Colors.white.withValues(alpha: 0.12),
              size: 148,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tháng $month/$year',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$invoiceCount hóa đơn trong kỳ này',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                _money(totalAmount),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TenantInvoiceMetric(
                      label: 'Đã TT',
                      value: paidCount,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TenantInvoiceMetric(
                      label: 'Cần xem',
                      value: dueCount,
                      color: const Color(0xFFFACC15),
                    ),
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

class _TenantInvoiceMetric extends StatelessWidget {
  const _TenantInvoiceMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantInvoiceCard extends StatelessWidget {
  const _TenantInvoiceCard({
    required this.data,
    required this.status,
    required this.onTap,
  });

  final Map<String, dynamic> data;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: statusColor,
                  size: 29,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _text(data['roomName'], 'Phòng của tôi'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          _money(data['totalAmount']),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _periodLabel(data),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _InvoiceStatusPill(status: status),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hạn: ${_dateText(data['dueDate'])}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InvoiceDropdownShell(
              label: 'Tháng',
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: month,
                  isDense: true,
                  isExpanded: true,
                  items: [
                    for (var index = 1; index <= 12; index++)
                      DropdownMenuItem(
                        value: index,
                        child: Text('Tháng $index'),
                      ),
                  ],
                  onChanged: onMonthChanged,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InvoiceDropdownShell(
              label: 'Năm',
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
    );
  }
}

class _InvoiceDropdownShell extends StatelessWidget {
  const _InvoiceDropdownShell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      child: child,
    );
  }
}

class _InvoiceStatusPill extends StatelessWidget {
  const _InvoiceStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primary,
            ),
          ),
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
                  '$invoiceCount hóa đơn',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            _money(totalAmount),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
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
      _showSnack('Không mở được link thanh toán PayOS.');
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
          appBar: AppBar(
            title: const Text('Chi tiết hóa đơn'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          bottomNavigationBar: _InvoiceBottomSummary(
            total: _readInt(invoice['totalAmount']),
            status: status,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 116),
            children: [
              _TenantInvoiceHeader(data: invoice),
              const SizedBox(height: 14),
              _InvoicePaymentTimeline(status: status),
              const SizedBox(height: 14),
              _TenantInvoiceSection(
                icon: Icons.info_outline,
                title: 'Thông tin',
                children: [
                  _InfoRow(
                    label: 'Phòng',
                    value: _text(invoice['roomName'], ''),
                  ),
                  _InfoRow(label: 'Kỳ hóa đơn', value: _periodLabel(invoice)),
                  _InfoRow(
                    label: 'Hạn thanh toán',
                    value: _dateText(invoice['dueDate']),
                  ),
                  _InfoRow(label: 'Trạng thái', value: _statusLabel(status)),
                ],
              ),
              const SizedBox(height: 14),
              _TenantInvoiceSection(
                icon: Icons.receipt_long_outlined,
                title: 'Chi tiết thanh toán',
                children: [
                  _InfoRow(
                    label: 'Tiền phòng',
                    value: _money(invoice['roomRent']),
                  ),
                  _InfoRow(
                    label: 'Tiền điện',
                    value:
                        '${_readInt(invoice['electricityUsage'])} số - ${_money(invoice['electricityAmount'])}',
                  ),
                  _InfoRow(
                    label: 'Tiền nước',
                    value:
                        '${_readInt(invoice['waterUsage'])} số - ${_money(invoice['waterAmount'])}',
                  ),
                  _InfoRow(
                    label: 'Phí dịch vụ',
                    value: _money(invoice['serviceFee']),
                  ),
                  _InfoRow(
                    label: 'Internet',
                    value: _money(invoice['internetFee']),
                  ),
                  _InfoRow(
                    label: 'Gửi xe',
                    value: _money(invoice['parkingFee']),
                  ),
                  _InfoRow(label: 'Phụ thu', value: _money(invoice['otherFee'])),
                  _InfoRow(label: 'Giảm trừ', value: _money(invoice['discount'])),
                ],
              ),
              if (canPayOnline || status == InvoiceStatus.pending) ...[
                const SizedBox(height: 14),
                _PaymentInstructionSection(
                  buildingId: widget.buildingId,
                  invoice: invoice,
                  viewModel: _viewModel,
                ),
              ],
              if (canPayOnline) ...[
                const SizedBox(height: 14),
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
                            ? 'Mở lại thanh toán PayOS'
                            : 'Thanh toán từ đếng PayOS',
                      ),
                    );
                  },
                ),
              ],
              if (paymentNote.isNotEmpty) ...[
                const SizedBox(height: 14),
                _TenantInvoiceSection(
                  icon: Icons.sticky_note_2_outlined,
                  title: 'Ghi chú Đã gửi',
                  children: [_InfoRow(label: 'Nội dung', value: paymentNote)],
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
                    labelText: 'Ghi chú / mã giao dịch',
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
                      label: const Text('Báo đã thanh toán'),
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
      return 'Firestore chưa cấp quyền báo đã thanh toán.';
    }

    return 'Không gửi được thông tin thanh toán.';
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
              'Thanh toán trước đó chưa được xác nhận. Bạn có thể gửi lại thông tin thanh toán.',
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
            icon: Icons.account_balance_outlined,
            title: 'Hướng dẫn thanh toán',
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
            icon: Icons.account_balance_outlined,
            title: 'Hướng dẫn thanh toán',
            children: [
              _InfoRow(
                label: 'Trạng thái',
                value: 'Chưa tải được thông tin chuyển khoản.',
              ),
            ],
          );
        }

        final building = snapshot.data!;
        final settings = _readMap(building['paymentSettings']);
        final bankName = _text(settings['bankName'], 'Chưa thiết lập');
        final bankId = _text(settings['bankId'], '');
        final accountNumber =
            _text(settings['bankAccountNumber'], 'Chưa thiết lập');
        final accountHolder =
            _text(settings['bankAccountHolder'], 'Chưa thiết lập');
        final transferContent = _transferContent(
          settings['transferContentTemplate'],
          invoice,
        );
        final amount = _readInt(invoice['totalAmount']);
        final canCreateVietQr = bankId.isNotEmpty &&
            accountNumber != 'Chưa thiết lập' &&
            accountHolder != 'Chưa thiết lập' &&
            amount > 0;

        return _TenantInvoiceSection(
          icon: Icons.account_balance_outlined,
          title: 'Hướng dẫn thanh toán',
          children: [
            _InfoRow(label: 'Ngân hàng', value: bankName),
            if (bankId.isNotEmpty) _InfoRow(label: 'Mã VietQR', value: bankId),
            _InfoRow(label: 'Số tài khoản', value: accountNumber),
            _InfoRow(label: 'Chủ tài khoản', value: accountHolder),
            _InfoRow(label: 'Số tiền', value: _money(amount)),
            _InfoRow(label: 'Nội dung', value: transferContent),
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
                  label: const Text('Tạo mã QR VietQR'),
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
          title: const Text('Mã QR VietQR'),
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
                          'Không tải được mã QR. Hãy kiểm tra mã ngân hàng VietQR.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(label: 'Số tiền', value: _money(amount)),
                _InfoRow(label: 'Nội dung', value: transferContent),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('đếng'),
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
              'Admin cần nhập mã ngân hàng VietQR, số tài khoản và chủ tài khoản để tạo QR.',
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
    final statusColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [statusColor, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -30,
            child: Icon(
              Icons.payments_rounded,
              color: Colors.white.withValues(alpha: 0.13),
              size: 142,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _money(data['totalAmount']),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_text(data['roomName'], 'Phòng của tôi')} - ${_periodLabel(data)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  _statusLabel(status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoicePaymentTimeline extends StatelessWidget {
  const _InvoicePaymentTimeline({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final waitingDone = status == InvoiceStatus.waitingPayment ||
        status == InvoiceStatus.pending ||
        status == InvoiceStatus.paid;
    final paidDone = status == InvoiceStatus.paid;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: _TimelineStep(
              icon: Icons.edit_document,
              label: 'Tạo hóa đơn',
              done: true,
            ),
          ),
          _TimelineLine(done: waitingDone),
          Expanded(
            child: _TimelineStep(
              icon: Icons.hourglass_top_outlined,
              label: 'Chờ thanh toán',
              done: waitingDone,
            ),
          ),
          _TimelineLine(done: paidDone),
          Expanded(
            child: _TimelineStep(
              icon: Icons.verified_outlined,
              label: 'Đã thanh toán',
              done: paidDone,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.label,
    required this.done,
  });

  final IconData icon;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = done ? const Color(0xFF16A34A) : AppColors.textSecondary;

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: done ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TimelineLine extends StatelessWidget {
  const _TimelineLine({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 26),
        color: done ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
      ),
    );
  }
}

class _TenantInvoiceSection extends StatelessWidget {
  const _TenantInvoiceSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceBottomSummary extends StatelessWidget {
  const _InvoiceBottomSummary({required this.total, required this.status});

  final int total;
  final String status;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng thanh toán',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _statusLabel(status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              _money(total),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
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
  return month > 0 && year > 0 ? 'Tháng $month/$year' : 'Chưa có kỳ';
}

String _dateText(Object? value) {
  if (value is! Timestamp) return 'Chưa có';
  final date = value.toDate();
  return '${date.day}/${date.month}/${date.year}';
}

String _statusLabel(String status) {
  return switch (status) {
    InvoiceStatus.waitingPayment => 'Đang thanh toán PayOS',
    InvoiceStatus.pending => 'Cho xác nhận',
    InvoiceStatus.paid => 'Đã thanh toán',
    InvoiceStatus.overdue => 'Quá hạn',
    InvoiceStatus.cancelled => 'Đã hủy',
    _ => 'Chưa thanh toán',
  };
}

String _statusFilterText(String status) {
  return switch (status) {
    InvoiceStatus.unpaid => 'chưa thanh toán ',
    InvoiceStatus.waitingPayment => 'Đang thanh toán ',
    InvoiceStatus.pending => 'cho xác nhận ',
    InvoiceStatus.paid => 'đã thanh toán ',
    InvoiceStatus.overdue => 'quá hạn ',
    InvoiceStatus.cancelled => 'đã hủy ',
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
  final room = _text(invoice['roomName'], 'Phòng');
  final tenantName = _text(invoice['tenantName'], 'Người thuê');
  final fallback = 'Thanh toán $room tháng $month/$year';

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
