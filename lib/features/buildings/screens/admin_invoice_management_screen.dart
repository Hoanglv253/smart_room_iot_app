import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../view_models/admin_invoice_detail_view_model.dart';
import '../view_models/create_invoice_view_model.dart';
import '../view_models/invoice_list_view_model.dart';

const _allInvoiceStatus = 'all';

class _InvoiceStatusOption {
  const _InvoiceStatusOption(this.value, this.label);

  final String value;
  final String label;
}

const _invoiceStatusOptions = [
  _InvoiceStatusOption(_allInvoiceStatus, 'Tất cả'),
  _InvoiceStatusOption(InvoiceStatus.unpaid, 'Chưa thu'),
  _InvoiceStatusOption(InvoiceStatus.waitingPayment, 'Đang TT'),
  _InvoiceStatusOption(InvoiceStatus.pending, 'Cho xác nhận'),
  _InvoiceStatusOption(InvoiceStatus.paid, 'Đã thu'),
  _InvoiceStatusOption(InvoiceStatus.overdue, 'Quá hạn'),
];

class AdminInvoiceManagementScreen extends StatefulWidget {
  const AdminInvoiceManagementScreen({
    required this.buildingId,
    required this.building,
    this.canCreate = true,
    this.canConfirmPayment = true,
    super.key,
  });

  final String buildingId;
  final Map<String, dynamic> building;
  final bool canCreate;
  final bool canConfirmPayment;

  @override
  State<AdminInvoiceManagementScreen> createState() =>
      _AdminInvoiceManagementScreenState();
}

class _AdminInvoiceManagementScreenState
    extends State<AdminInvoiceManagementScreen> {
  final _viewModel = InvoiceListViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _openCreateInvoice() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CreateInvoiceScreen(
          buildingId: widget.buildingId,
          building: widget.building,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buildingName = (widget.building['name'] ?? 'Tòa nhà').toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hóa đơn'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: widget.canCreate
          ? FloatingActionButton(
              onPressed: _openCreateInvoice,
              tooltip: 'Tạo hóa đơn',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _viewModel.buildingInvoices(widget.buildingId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _InvoiceEmptyView(
                  icon: Icons.lock_outline,
                  message: 'Không tải được danh sách hóa đơn.',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final invoices = _viewModel.sortInvoices(snapshot.data?.docs ?? []);
              final yearOptions = _viewModel.yearOptions(invoices);
              final monthlyInvoices = _viewModel.monthlyInvoices(invoices);
              final filteredInvoices = _viewModel.filteredInvoices(
                monthlyInvoices,
              );
              final periodPicker = _InvoicePeriodPicker(
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

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _InvoiceRevenueOverview(
                    invoices: monthlyInvoices,
                    month: _viewModel.selectedMonth,
                    year: _viewModel.selectedYear,
                    canCreate: widget.canCreate,
                    onCreate: _openCreateInvoice,
                  ),
                  const SizedBox(height: 12),
                  periodPicker,
                  if (invoices.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InvoiceStatusFilterBar(
                      invoices: monthlyInvoices,
                      selectedStatus: _viewModel.selectedStatus,
                      onChanged: _viewModel.setStatus,
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (invoices.isEmpty)
                    _InvoiceEmptyView(
                      icon: Icons.receipt_long_outlined,
                      message: 'Chưa có hóa đơn nào cho $buildingName.',
                    )
                  else if (filteredInvoices.isEmpty)
                    _InvoiceEmptyView(
                      icon: Icons.event_busy_outlined,
                      message:
                          'Không có hóa đơn ${_statusFilterText(_viewModel.selectedStatus)}trong tháng ${_viewModel.selectedMonth}/${_viewModel.selectedYear}.',
                    )
                  else ...[
                    _InvoiceMonthHeader(
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _InvoiceCard(
                          invoiceId: doc.id,
                          data: doc.data(),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _AdminInvoiceDetailScreen(
                                  buildingId: widget.buildingId,
                                  building: widget.building,
                                  invoiceId: doc.id,
                                  invoice: doc.data(),
                                  canConfirmPayment:
                                      widget.canConfirmPayment,
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

class _InvoiceStatusFilterBar extends StatelessWidget {
  const _InvoiceStatusFilterBar({
    required this.invoices,
    required this.selectedStatus,
    required this.onChanged,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> invoices;
  final String selectedStatus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final option in _invoiceStatusOptions) ...[
              _InvoiceStatusPill(
                label: '${option.label} (${_count(option.value)})',
                selected: selectedStatus == option.value,
                onTap: () => onChanged(option.value),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  int _count(String status) {
    if (status == _allInvoiceStatus) return invoices.length;

    return invoices.where((doc) {
      final dataStatus = (doc.data()['status'] ?? InvoiceStatus.unpaid).toString();
      return dataStatus == status;
    }).length;
  }
}

class _InvoiceStatusPill extends StatelessWidget {
  const _InvoiceStatusPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, color: Colors.white, size: 17),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceRevenueOverview extends StatelessWidget {
  const _InvoiceRevenueOverview({
    required this.invoices,
    required this.month,
    required this.year,
    required this.canCreate,
    required this.onCreate,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> invoices;
  final int month;
  final int year;
  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final paidTotal = _sumByStatus(InvoiceStatus.paid);
    final pendingTotal = _sumByStatus(InvoiceStatus.pending);
    final unpaidTotal = _sumUnpaid();
    final expectedTotal = paidTotal + pendingTotal + unpaidTotal;
    final progress = expectedTotal == 0 ? 0.0 : paidTotal / expectedTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient(),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -40,
            child: Icon(
              Icons.receipt_long_rounded,
              color: Colors.white.withValues(alpha: 0.12),
              size: 150,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tháng $month/$year',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _money(paidTotal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Đã thu trong kỳ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 66,
                    height: 66,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress.clamp(0, 1).toDouble(),
                          strokeWidth: 7,
                          backgroundColor: Colors.white.withValues(alpha: 0.20),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _InvoiceHeroMetric(
                      label: 'Đã thu',
                      value: paidTotal,
                      color: AppColors.managerAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InvoiceHeroMetric(
                      label: 'Cho xác nhận',
                      value: pendingTotal,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InvoiceHeroMetric(
                      label: 'Chưa thu',
                      value: unpaidTotal,
                      color: const Color(0xFF93C5FD),
                    ),
                  ),
                ],
              ),
              if (canCreate) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onCreate,
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      'Tạo hóa đơn',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  int _sumByStatus(String status) {
    return invoices.where((doc) {
      final dataStatus = (doc.data()['status'] ?? InvoiceStatus.unpaid).toString();
      return dataStatus == status;
    }).fold<int>(0, (total, doc) => total + _readInt(doc.data()['totalAmount']));
  }

  int _sumUnpaid() {
    return invoices.where((doc) {
      final status = (doc.data()['status'] ?? InvoiceStatus.unpaid).toString();
      return status != InvoiceStatus.paid &&
          status != InvoiceStatus.pending &&
          status != InvoiceStatus.cancelled;
    }).fold<int>(0, (total, doc) => total + _readInt(doc.data()['totalAmount']));
  }
}

class _InvoiceHeroMetric extends StatelessWidget {
  const _InvoiceHeroMetric({
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _money(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _InvoicePeriodPicker extends StatelessWidget {
  const _InvoicePeriodPicker({
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InvoicePeriodDropdown(
              icon: Icons.calendar_month_outlined,
              value: month,
              items: [
                for (var index = 1; index <= 12; index++) index,
              ],
              labelBuilder: (value) => 'Tháng $value',
              onChanged: onMonthChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _InvoicePeriodDropdown(
              icon: Icons.event_available_outlined,
              value: year,
              items: years,
              labelBuilder: (value) => value.toString(),
              onChanged: onYearChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicePeriodDropdown extends StatelessWidget {
  const _InvoicePeriodDropdown({
    required this.icon,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final IconData icon;
  final int value;
  final List<int> items;
  final String Function(int value) labelBuilder;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: value,
                isDense: true,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                borderRadius: BorderRadius.circular(18),
                items: [
                  for (final item in items)
                    DropdownMenuItem(
                      value: item,
                      child: Text(labelBuilder(item)),
                    ),
                ],
                selectedItemBuilder: (context) {
                  return [
                    for (final item in items)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          labelBuilder(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ];
                },
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceMonthHeader extends StatelessWidget {
  const _InvoiceMonthHeader({
    required this.data,
    required this.invoiceCount,
    required this.totalAmount,
  });

  final Map<String, dynamic> data;
  final int invoiceCount;
  final int totalAmount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
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
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$invoiceCount hóa đơn',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Text(
          _money(totalAmount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
class _CreateInvoiceScreen extends StatefulWidget {
  const _CreateInvoiceScreen({
    required this.buildingId,
    required this.building,
    this.invoiceId,
    this.initialInvoice,
  });

  final String buildingId;
  final Map<String, dynamic> building;
  final String? invoiceId;
  final Map<String, dynamic>? initialInvoice;

  bool get isEditing => invoiceId != null && initialInvoice != null;

  @override
  State<_CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<_CreateInvoiceScreen> {
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _roomRentController = TextEditingController();
  final _electricityOldController = TextEditingController();
  final _electricityNewController = TextEditingController();
  final _waterOldController = TextEditingController();
  final _waterNewController = TextEditingController();
  final _serviceFeeController = TextEditingController();
  final _internetFeeController = TextEditingController();
  final _parkingFeeController = TextEditingController();
  final _otherFeeController = TextEditingController();
  final _discountController = TextEditingController();
  final _viewModel = CreateInvoiceViewModel();

  late final Future<QuerySnapshot<Map<String, dynamic>>> _roomsFuture;
  String? _selectedRoomId;
  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedRoom;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _viewModel.buildingRooms(widget.buildingId);

    final now = DateTime.now();
    final invoice = widget.initialInvoice;
    _selectedRoomId = invoice?['roomId']?.toString();
    _monthController.text =
        _readInt(invoice?['month'], fallback: now.month).toString();
    _yearController.text =
        _readInt(invoice?['year'], fallback: now.year).toString();
    _monthController.addListener(_handlePeriodChanged);
    _yearController.addListener(_handlePeriodChanged);
    _roomRentController.text = _readInt(invoice?['roomRent']).toString();
    _electricityOldController.text =
        _readInt(invoice?['electricityOld']).toString();
    _electricityNewController.text =
        _readInt(invoice?['electricityNew']).toString();
    _waterOldController.text = _readInt(invoice?['waterOld']).toString();
    _waterNewController.text = _readInt(invoice?['waterNew']).toString();
    _serviceFeeController.text =
        _readInt(invoice?['serviceFee'], fallback: _readInt(widget.building['serviceFee']))
            .toString();
    _internetFeeController.text =
        _readInt(invoice?['internetFee'], fallback: _readInt(widget.building['internetFee']))
            .toString();
    _parkingFeeController.text =
        _readInt(invoice?['parkingFee'], fallback: _readInt(widget.building['parkingFee']))
            .toString();
    _otherFeeController.text = _readInt(invoice?['otherFee']).toString();
    _discountController.text = _readInt(invoice?['discount']).toString();

    for (final controller in [
      _roomRentController,
      _electricityOldController,
      _electricityNewController,
      _waterOldController,
      _waterNewController,
      _serviceFeeController,
      _internetFeeController,
      _parkingFeeController,
      _otherFeeController,
      _discountController,
    ]) {
      controller.addListener(_refreshTotal);
    }

    if (widget.isEditing) {
      _viewModel.setRoomHistoryMessage(
        'Đang sửa hóa đơn chưa thanh toán. Nếu đổi phòng hoặc kỳ, app sẽ kiểm tra trùng hóa đơn khi lưu.',
      );
    }
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    _roomRentController.dispose();
    _electricityOldController.dispose();
    _electricityNewController.dispose();
    _waterOldController.dispose();
    _waterNewController.dispose();
    _serviceFeeController.dispose();
    _internetFeeController.dispose();
    _parkingFeeController.dispose();
    _otherFeeController.dispose();
    _discountController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _refreshTotal() {
    if (mounted) setState(() {});
  }

  void _handlePeriodChanged() {
    if (_selectedRoom == null && _selectedRoomId == null) return;

    _viewModel.setHasDuplicateInvoice(false);
    _viewModel.setRoomHistoryMessage(
      'Kỳ hóa đơn đã thay đổi. Khi lưu app sẽ kiểm tra trùng kỳ với kỳ mới.',
    );
  }

  void _selectRoom(QueryDocumentSnapshot<Map<String, dynamic>> roomDoc) {
    final room = roomDoc.data();
    final roomRent = _readInt(room['rent']);
    final defaultRent = _readInt(widget.building['defaultRent']);

    setState(() {
      _selectedRoomId = roomDoc.id;
      _selectedRoom = roomDoc;
      _roomRentController.text =
          (roomRent > 0 ? roomRent : defaultRent).toString();
      _electricityOldController.text = '0';
      _waterOldController.text = '0';
    });
    _viewModel.setRoomHistoryMessage(null);
    _viewModel.setHasDuplicateInvoice(false);

    _loadRoomInvoiceContext(roomDoc.id);
  }

  Future<void> _loadRoomInvoiceContext(String roomId) async {
    _viewModel.setRoomHistoryLoading(true);

    try {
      final invoices = await _viewModel.roomInvoices(
        buildingId: widget.buildingId,
        roomId: roomId,
      );
      if (!mounted || _selectedRoomId != roomId) return;

      final currentPeriod = _periodKeyFromControllers();
      final duplicateInvoice = invoices.where((invoice) {
        return _periodKey(invoice) == currentPeriod &&
            invoice['_id']?.toString() != widget.invoiceId;
      }).toList();

      final previousInvoices = invoices.where((invoice) {
        return _periodKey(invoice) < currentPeriod;
      }).toList()
        ..sort((left, right) => _periodKey(right).compareTo(_periodKey(left)));

      _viewModel.setHasDuplicateInvoice(duplicateInvoice.isNotEmpty);

      if (previousInvoices.isNotEmpty) {
        final previous = previousInvoices.first;
        final electricityNew = _readInt(previous['electricityNew']);
        final waterNew = _readInt(previous['waterNew']);
        _electricityOldController.text = electricityNew.toString();
        _waterOldController.text = waterNew.toString();
        _viewModel.setRoomHistoryMessage(
          'Đã lấy chỉ số cũ từ hóa đơn ${_periodLabel(previous)}.',
        );
      } else {
        _viewModel.setRoomHistoryMessage(
          'Chưa có hóa đơn trước đó, chỉ số cũ đang mặc định là 0.',
        );
      }

      if (_viewModel.hasDuplicateInvoice) {
        _viewModel.setRoomHistoryMessage(
          'Phòng này đã có hóa đơn ${_monthController.text}/${_yearController.text}. Hãy kiểm tra lại trước khi tạo mới.',
        );
      }
    } catch (e) {
      if (!mounted || _selectedRoomId != roomId) return;
      final message = e.toString();
      _viewModel.setRoomHistoryMessage(
        message.contains('permission-denied')
            ? 'Firestore chưa cấp quyền đọc hóa đơn cũ.'
            : 'Không tải được hóa đơn cũ.',
      );
    } finally {
      if (mounted && _selectedRoomId == roomId) {
        _viewModel.setRoomHistoryLoading(false);
      }
    }
  }

  Future<void> _saveInvoice(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms,
  ) async {
    if (widget.isEditing) {
      final status =
          (widget.initialInvoice?['status'] ?? InvoiceStatus.unpaid).toString();
      if (status != InvoiceStatus.unpaid) {
        _showSnack('Chỉ được sửa hóa đơn chưa thanh toán.');
        return;
      }
    }

    final roomDoc = _selectedRoom ?? _findRoomById(rooms, _selectedRoomId);
    if (roomDoc == null) {
      _showSnack('Hãy chọn phòng cần lap hóa đơn.');
      return;
    }

    final room = roomDoc.data();
    final tenantId = (room['tenantId'] ?? '').toString();
    if (tenantId.isEmpty) {
      _showSnack('Phòng này chưa có người thuê.');
      return;
    }

    final month = _readInt(_monthController.text);
    final year = _readInt(_yearController.text);
    if (month < 1 || month > 12 || year < 2000) {
      _showSnack('Tháng hoặc năm không hợp lệ.');
      return;
    }

    final List<Map<String, dynamic>> existingInvoices;
    try {
      existingInvoices = await _viewModel.roomInvoices(
        buildingId: widget.buildingId,
        roomId: roomDoc.id,
      );
    } catch (e) {
      final message = e.toString();
      _showSnack(
        message.contains('permission-denied')
            ? 'Firestore chưa cấp quyền kiểm tra hóa đơn cũ.'
            : 'Không kiểm tra được hóa đơn cũ.',
      );
      return;
    }

    final currentPeriod = _periodKey(null, year: year, month: month);
    final hasDuplicate = existingInvoices.any((invoice) {
      return _periodKey(invoice) == currentPeriod &&
          invoice['_id']?.toString() != widget.invoiceId;
    });
    if (hasDuplicate) {
      _viewModel.setHasDuplicateInvoice(true);
      _showSnack('Phòng này đã có hóa đơn tháng $month/$year.');
      return;
    }

    try {
      final electricityOld = _readInt(_electricityOldController.text);
      final electricityNew = _readInt(_electricityNewController.text);
      final waterOld = _readInt(_waterOldController.text);
      final waterNew = _readInt(_waterNewController.text);
      final electricityUsage =
          (electricityNew - electricityOld).clamp(0, 999999).toInt();
      final waterUsage = (waterNew - waterOld).clamp(0, 999999).toInt();
      final electricityPrice = _readInt(widget.building['electricityPrice']);
      final waterPrice = _readInt(widget.building['waterPrice']);
      final roomName = _text(room['name'], roomDoc.id);
      final roomNumber = _readInt(room['roomNumber']);
      final tenantName = _text(room['tenantName'], 'Người thuê');
      final tenantEmail = _text(room['tenantEmail'], '');
      final dueDate = _dueDate(year, month, _readInt(widget.building['billDueDay']));

      final invoiceData = {
        'buildingId': widget.buildingId,
        'roomId': roomDoc.id,
        'roomName': roomName,
        'roomNumber': roomNumber,
        'tenantId': tenantId,
        'tenantName': tenantName,
        'tenantEmail': tenantEmail,
        'month': month,
        'year': year,
        'periodKey': '$year-${month.toString().padLeft(2, '0')}',
        'roomRent': _readInt(_roomRentController.text),
        'electricityOld': electricityOld,
        'electricityNew': electricityNew,
        'electricityUsage': electricityUsage,
        'electricityPrice': electricityPrice,
        'electricityAmount': electricityUsage * electricityPrice,
        'waterOld': waterOld,
        'waterNew': waterNew,
        'waterUsage': waterUsage,
        'waterPrice': waterPrice,
        'waterAmount': waterUsage * waterPrice,
        'serviceFee': _readInt(_serviceFeeController.text),
        'internetFee': _readInt(_internetFeeController.text),
        'parkingFee': _readInt(_parkingFeeController.text),
        'otherFee': _readInt(_otherFeeController.text),
        'discount': _readInt(_discountController.text),
        'totalAmount': _totalAmount,
        'status': InvoiceStatus.unpaid,
        'paymentMethod': '',
        'paymentNote': '',
        'dueDate': Timestamp.fromDate(dueDate),
      };
      final saved = widget.isEditing
          ? await _viewModel.updateUnpaidInvoice(
              buildingId: widget.buildingId,
              invoiceId: widget.invoiceId!,
              invoice: invoiceData,
            )
          : await _viewModel.createInvoice(
              buildingId: widget.buildingId,
              invoice: invoiceData,
            );
      if (!saved) {
        _showSnack(_createInvoiceError());
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      _showSnack(
        widget.isEditing ? 'Không sửa được hóa đơn.' : 'Không tạo được hóa đơn.',
      );
    }
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? _findRoomById(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms,
    String? roomId,
  ) {
    if (roomId == null) return null;
    for (final room in rooms) {
      if (room.id == roomId) return room;
    }
    return null;
  }

  int get _electricityAmount {
    final usage = (_readInt(_electricityNewController.text) -
            _readInt(_electricityOldController.text))
        .clamp(0, 999999)
        .toInt();
    return usage * _readInt(widget.building['electricityPrice']);
  }

  int get _waterAmount {
    final usage = (_readInt(_waterNewController.text) -
            _readInt(_waterOldController.text))
        .clamp(0, 999999)
        .toInt();
    return usage * _readInt(widget.building['waterPrice']);
  }

  int get _totalAmount {
    final subtotal = _readInt(_roomRentController.text) +
        _electricityAmount +
        _waterAmount +
        _readInt(_serviceFeeController.text) +
        _readInt(_internetFeeController.text) +
        _readInt(_parkingFeeController.text) +
        _readInt(_otherFeeController.text);
    final total = subtotal - _readInt(_discountController.text);
    return total < 0 ? 0 : total;
  }

  int _periodKeyFromControllers() {
    return _periodKey(
      null,
      year: _readInt(_yearController.text),
      month: _readInt(_monthController.text),
    );
  }

  static int _periodKey(
    Map<String, dynamic>? invoice, {
    int? year,
    int? month,
  }) {
    final resolvedYear = year ?? _readInt(invoice?['year']);
    final resolvedMonth = month ?? _readInt(invoice?['month']);
    return resolvedYear * 100 + resolvedMonth;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Sửa hóa đơn' : 'Tạo hóa đơn'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: _roomsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final rooms = (snapshot.data?.docs ?? []).where((doc) {
                final tenantId = (doc.data()['tenantId'] ?? '').toString();
                return tenantId.isNotEmpty;
              }).toList()
                ..sort((left, right) {
                  final leftNumber = _readInt(left.data()['roomNumber']);
                  final rightNumber = _readInt(right.data()['roomNumber']);
                  return leftNumber.compareTo(rightNumber);
                });

              if (rooms.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: _InvoiceEmptyView(
                    icon: Icons.meeting_room_outlined,
                    message: 'Chưa có phòng nào đang có người thuê.',
                  ),
                );
              }

              final selectedRoomId =
                  _findRoomById(rooms, _selectedRoomId) == null
                      ? null
                      : _selectedRoomId;
              final selectedRoom = _findRoomById(rooms, selectedRoomId);
              final selectedRoomData = selectedRoom?.data();
              final selectedRoomName = selectedRoom == null
                  ? 'Chưa chọn phòng'
                  : _text(
                      selectedRoomData == null ? null : selectedRoomData['name'],
                      selectedRoom.id,
                    );
              final selectedTenantName = selectedRoom == null
                  ? 'Chọn phòng để lập hóa đơn'
                  : _text(
                      selectedRoomData == null
                          ? null
                          : selectedRoomData['tenantName'],
                      'Người thuê',
                    );
              final periodLabel =
                  'Tháng ${_monthController.text}/${_yearController.text}';
              final canSave = selectedRoomId != null &&
                  !_viewModel.isLoading &&
                  !_viewModel.hasDuplicateInvoice;

              return Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
                    children: [
                      _CreateInvoiceHeroCard(
                        roomName: selectedRoomName,
                        tenantName: selectedTenantName,
                        periodLabel: periodLabel,
                        total: _totalAmount,
                        isEditing: widget.isEditing,
                      ),
                      const SizedBox(height: 14),
                      _CreateInvoiceSection(
                        icon: Icons.fact_check_outlined,
                        title: 'Thông tin có ban',
                        subtitle: 'Chọn phòng và kỳ cần lap hóa đơn.',
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: selectedRoomId,
                            decoration: const InputDecoration(
                              labelText: 'Phòng',
                              prefixIcon: Icon(Icons.meeting_room_outlined),
                            ),
                            items: rooms.map((doc) {
                              final room = doc.data();
                              final name = _text(room['name'], doc.id);
                              final tenantName =
                                  _text(room['tenantName'], 'Người thuê');
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(
                                  '$name - $tenantName',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (roomId) {
                              if (roomId == null) return;
                              final roomDoc =
                                  rooms.firstWhere((doc) => doc.id == roomId);
                              _selectRoom(roomDoc);
                            },
                          ),
                          if (_viewModel.isLoadingRoomHistory) ...[
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(minHeight: 2),
                          ] else if (_viewModel.roomHistoryMessage != null) ...[
                            const SizedBox(height: 12),
                            _InvoiceNotice(
                              message: _viewModel.roomHistoryMessage!,
                              isWarning: _viewModel.hasDuplicateInvoice,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _numberField(
                                  _monthController,
                                  'Tháng',
                                  icon: Icons.calendar_month_outlined,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _numberField(
                                  _yearController,
                                  'Năm',
                                  icon: Icons.event_available_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _CreateInvoiceSection(
                        icon: Icons.bolt_outlined,
                        title: 'Điện nước',
                        subtitle: 'Nhập chỉ số cũ và mới, app sẽ tự tính tiền.',
                        children: [
                          _MeterInputPanel(
                            icon: Icons.bolt_rounded,
                            title: 'Điện',
                            color: const Color(0xFFF59E0B),
                            amountLabel: 'Tiền điện',
                            amount: _electricityAmount,
                            oldField: _numberField(
                              _electricityOldController,
                              'Cu',
                            ),
                            newField: _numberField(
                              _electricityNewController,
                              'Mới',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _MeterInputPanel(
                            icon: Icons.water_drop_outlined,
                            title: 'Nước',
                            color: const Color(0xFF0EA5E9),
                            amountLabel: 'Tiền nước',
                            amount: _waterAmount,
                            oldField: _numberField(
                              _waterOldController,
                              'Cu',
                            ),
                            newField: _numberField(
                              _waterNewController,
                              'Mới',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _CreateInvoiceSection(
                        icon: Icons.payments_outlined,
                        title: 'Phí khác',
                        subtitle: 'Kiểm tra các khoản thu trước khi lưu.',
                        children: [
                          _FeeInputRow(
                            icon: Icons.home_work_outlined,
                            label: 'Tiền phòng',
                            controller: _roomRentController,
                          ),
                          _FeeInputRow(
                            icon: Icons.miscellaneous_services_outlined,
                            label: 'Phí dịch vụ',
                            controller: _serviceFeeController,
                          ),
                          _FeeInputRow(
                            icon: Icons.wifi_outlined,
                            label: 'Internet',
                            controller: _internetFeeController,
                          ),
                          _FeeInputRow(
                            icon: Icons.local_parking_outlined,
                            label: 'Gửi xe',
                            controller: _parkingFeeController,
                          ),
                          _FeeInputRow(
                            icon: Icons.add_card_outlined,
                            label: 'Phụ thu',
                            controller: _otherFeeController,
                          ),
                          _FeeInputRow(
                            icon: Icons.discount_outlined,
                            label: 'Giảm trừ',
                            controller: _discountController,
                            color: AppColors.managerAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _CreateInvoiceSaveBar(
                      total: _totalAmount,
                      isLoading: _viewModel.isLoading,
                      isEditing: widget.isEditing,
                      canSave: canSave,
                      onSave: () => _saveInvoice(rooms),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _createInvoiceError() {
    final error = _viewModel.errorMessage;
    if (error?.contains('permission-denied') == true) {
      return widget.isEditing
          ? 'Firestore chưa cấp quyền sửa hóa đơn.'
          : 'Firestore chưa cấp quyền tạo hóa đơn.';
    }
    if (error?.contains('Chỉ được sửa hóa đơn chưa thanh toán') == true) {
      return 'Chỉ được sửa hóa đơn chưa thanh toán.';
    }

    return widget.isEditing ? 'Không sửa được hóa đơn.' : 'Không tạo được hóa đơn.';
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static DateTime _dueDate(int year, int month, int rawDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = rawDay <= 0 ? lastDay : rawDay.clamp(1, lastDay).toInt();
    return DateTime(year, month, day, 23, 59, 59);
  }
}

class _CreateInvoiceHeroCard extends StatelessWidget {
  const _CreateInvoiceHeroCard({
    required this.roomName,
    required this.tenantName,
    required this.periodLabel,
    required this.total,
    required this.isEditing,
  });

  final String roomName;
  final String tenantName;
  final String periodLabel;
  final int total;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient(),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -34,
            child: Icon(
              Icons.request_quote_rounded,
              color: Colors.white.withValues(alpha: 0.13),
              size: 142,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Đang sửa hóa đơn' : 'Hóa đơn mới',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          periodLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                roomName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                tenantName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tạm tính',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _money(total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateInvoiceSection extends StatelessWidget {
  const _CreateInvoiceSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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

class _MeterInputPanel extends StatelessWidget {
  const _MeterInputPanel({
    required this.icon,
    required this.title,
    required this.color,
    required this.amountLabel,
    required this.amount,
    required this.oldField,
    required this.newField,
  });

  final IconData icon;
  final String title;
  final Color color;
  final String amountLabel;
  final int amount;
  final Widget oldField;
  final Widget newField;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _money(amount),
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: oldField),
              const SizedBox(width: 10),
              Expanded(child: newField),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$amountLabel: ${_money(amount)}',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeInputRow extends StatelessWidget {
  const _FeeInputRow({
    required this.icon,
    required this.label,
    required this.controller,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: '0',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateInvoiceSaveBar extends StatelessWidget {
  const _CreateInvoiceSaveBar({
    required this.total,
    required this.isLoading,
    required this.isEditing,
    required this.canSave,
    required this.onSave,
  });

  final int total;
  final bool isLoading;
  final bool isEditing;
  final bool canSave;
  final VoidCallback onSave;

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
              blurRadius: 24,
              offset: const Offset(0, -10),
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
                    'Tổng cộng',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _money(total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: canSave ? onSave : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(150, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(isEditing ? 'Cập nhật' : 'Lưu hóa đơn'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminInvoiceDetailScreen extends StatefulWidget {
  const _AdminInvoiceDetailScreen({
    required this.buildingId,
    required this.building,
    required this.invoiceId,
    required this.invoice,
    required this.canConfirmPayment,
  });

  final String buildingId;
  final Map<String, dynamic> building;
  final String invoiceId;
  final Map<String, dynamic> invoice;
  final bool canConfirmPayment;

  @override
  State<_AdminInvoiceDetailScreen> createState() =>
      _AdminInvoiceDetailScreenState();
}

class _AdminInvoiceDetailScreenState extends State<_AdminInvoiceDetailScreen> {
  final _viewModel = AdminInvoiceDetailViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _markPaid() async {
    final saved = await _viewModel.markPaid(
      buildingId: widget.buildingId,
      invoiceId: widget.invoiceId,
    );

    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_adminPaymentError())),
    );
  }

  Future<void> _openEditInvoice() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _CreateInvoiceScreen(
          buildingId: widget.buildingId,
          building: widget.building,
          invoiceId: widget.invoiceId,
          initialInvoice: widget.invoice,
        ),
      ),
    );

    if (!mounted || updated != true) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final status = (invoice['status'] ?? InvoiceStatus.unpaid).toString();
    final paymentNote = (invoice['paymentNote'] ?? '').toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết hóa đơn'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _InvoiceHeader(data: invoice),
          const SizedBox(height: 14),
          _InvoiceInfoGrid(data: invoice, status: status),
          const SizedBox(height: 14),
          _InvoiceChargeBreakdown(data: invoice),
          if (paymentNote.isNotEmpty) ...[
            const SizedBox(height: 14),
            _InvoiceNoteCard(note: paymentNote),
          ],
          const SizedBox(height: 14),
          _InvoicePaymentStateCard(status: status),
          if (status == InvoiceStatus.unpaid ||
              (widget.canConfirmPayment && status != InvoiceStatus.paid)) ...[
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: _viewModel,
              builder: (context, _) {
                return _InvoiceDetailActionCard(
                  status: status,
                  canEdit: status == InvoiceStatus.unpaid,
                  canConfirm:
                      widget.canConfirmPayment && status != InvoiceStatus.paid,
                  isLoading: _viewModel.isLoading,
                  onEdit: _openEditInvoice,
                  onConfirm: _markPaid,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String _adminPaymentError() {
    final error = _viewModel.errorMessage;
    if (error?.contains('permission-denied') == true) {
      return 'Firestore chưa cấp quyền xác nhận thanh toán.';
    }

    return 'Không xác nhận được thanh toán.';
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoiceId,
    required this.data,
    required this.onTap,
  });

  final String invoiceId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? InvoiceStatus.unpaid).toString();
    final color = _statusColor(status);
    final dueDate = _dateText(data['dueDate']);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(24),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(_statusIcon(status), color: color),
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
                                _text(data['roomName'], invoiceId),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _InvoiceStatusBadge(status: status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _periodLabel(data),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                dueDate == 'Chưa có'
                                    ? 'Chưa có hạn thanh toán'
                                    : 'Hạn TT: $dueDate',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _money(data['totalAmount']),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceStatusBadge extends StatelessWidget {
  const _InvoiceStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _shortStatusLabel(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InvoiceHeader extends StatelessWidget {
  const _InvoiceHeader({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? InvoiceStatus.unpaid).toString();
    final statusColor = _statusColor(status);
    final dueDate = _dateText(data['dueDate']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient(),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -38,
            child: Icon(
              Icons.receipt_long_rounded,
              color: Colors.white.withValues(alpha: 0.12),
              size: 152,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tổng thanh toán',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _money(data['totalAmount']),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(status), color: Colors.white, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          _shortStatusLabel(status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InvoiceHeroChip(
                    icon: Icons.meeting_room_outlined,
                    label: _text(data['roomName'], ''),
                  ),
                  _InvoiceHeroChip(
                    icon: Icons.calendar_month_outlined,
                    label: _periodLabel(data),
                  ),
                  _InvoiceHeroChip(
                    icon: Icons.event_available_outlined,
                    label: dueDate == 'Chưa có' ? 'Chưa có hạn' : 'Hạn $dueDate',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_statusIcon(status), color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusLabel(status),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceHeroChip extends StatelessWidget {
  const _InvoiceHeroChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label.isEmpty ? 'Chưa có' : label,
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

class _InvoiceInfoGrid extends StatelessWidget {
  const _InvoiceInfoGrid({
    required this.data,
    required this.status,
  });

  final Map<String, dynamic> data;
  final String status;

  @override
  Widget build(BuildContext context) {
    final items = [
      _InvoiceInfoChip(
        icon: Icons.person_outline,
        label: 'Người thuê',
        value: _text(data['tenantName'], 'Chưa có'),
      ),
      _InvoiceInfoChip(
        icon: Icons.meeting_room_outlined,
        label: 'Phòng',
        value: _text(data['roomName'], 'Chưa có'),
      ),
      _InvoiceInfoChip(
        icon: Icons.calendar_month_outlined,
        label: 'Ky',
        value: _periodLabel(data),
      ),
      _InvoiceInfoChip(
        icon: _statusIcon(status),
        label: 'Trạng thái',
        value: _statusLabel(status),
        color: _statusColor(status),
      ),
    ];

    return _InvoiceDetailCard(
      icon: Icons.info_outline_rounded,
      title: 'Thông tin',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth < 360
              ? constraints.maxWidth
              : (constraints.maxWidth - 10) / 2;

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final item in items) SizedBox(width: itemWidth, child: item),
            ],
          );
        },
      ),
    );
  }
}

class _InvoiceInfoChip extends StatelessWidget {
  const _InvoiceInfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceDetailCard extends StatelessWidget {
  const _InvoiceDetailCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
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
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InvoiceChargeBreakdown extends StatelessWidget {
  const _InvoiceChargeBreakdown({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _ChargeLineData(
        icon: Icons.home_work_outlined,
        label: 'Tiền phòng',
        value: _money(data['roomRent']),
        color: AppColors.primary,
      ),
      _ChargeLineData(
        icon: Icons.bolt_outlined,
        label: 'Tiền điện',
        value:
            '${_readInt(data['electricityUsage'])} số - ${_money(data['electricityAmount'])}',
        color: const Color(0xFFF59E0B),
      ),
      _ChargeLineData(
        icon: Icons.water_drop_outlined,
        label: 'Tiền nước',
        value:
            '${_readInt(data['waterUsage'])} số - ${_money(data['waterAmount'])}',
        color: const Color(0xFF0EA5E9),
      ),
      _ChargeLineData(
        icon: Icons.miscellaneous_services_outlined,
        label: 'Phí dịch vụ',
        value: _money(data['serviceFee']),
        color: AppColors.tenantAccent,
      ),
      _ChargeLineData(
        icon: Icons.wifi_outlined,
        label: 'Internet',
        value: _money(data['internetFee']),
        color: const Color(0xFF64748B),
      ),
      _ChargeLineData(
        icon: Icons.local_parking_outlined,
        label: 'Gửi xe',
        value: _money(data['parkingFee']),
        color: const Color(0xFF64748B),
      ),
      _ChargeLineData(
        icon: Icons.add_card_outlined,
        label: 'Phụ thu',
        value: _money(data['otherFee']),
        color: const Color(0xFF64748B),
      ),
      _ChargeLineData(
        icon: Icons.discount_outlined,
        label: 'Giảm trừ',
        value: _money(data['discount']),
        color: AppColors.managerAccent,
      ),
    ];

    return _InvoiceDetailCard(
      icon: Icons.receipt_outlined,
      title: 'Khoản thu',
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _InvoiceChargeRow(data: rows[index]),
            if (index != rows.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          _InvoiceTotalLine(total: _readInt(data['totalAmount'])),
        ],
      ),
    );
  }
}

class _ChargeLineData {
  const _ChargeLineData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _InvoiceChargeRow extends StatelessWidget {
  const _InvoiceChargeRow({required this.data});

  final _ChargeLineData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(data.icon, color: data.color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              data.value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InvoiceTotalLine extends StatelessWidget {
  const _InvoiceTotalLine({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Tổng thanh toán',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _money(total),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicePaymentStateCard extends StatelessWidget {
  const _InvoicePaymentStateCard({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isPaid = status == InvoiceStatus.paid;
    final color = isPaid ? AppColors.managerAccent : _statusColor(status);
    final title = isPaid ? 'Đã ghi nhận thanh toán' : _statusLabel(status);
    final subtitle = isPaid
        ? 'Hóa đơn này đã được đánh dấu là đã thanh toán.'
        : 'Hóa đơn này vẫn cần theo dõi hoặc xác nhận thanh toán.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_statusIcon(status), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceNoteCard extends StatelessWidget {
  const _InvoiceNoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return _InvoiceDetailCard(
      icon: Icons.sticky_note_2_outlined,
      title: 'Ghi chú thanh toán',
      child: Text(
        note,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _InvoiceDetailActionCard extends StatelessWidget {
  const _InvoiceDetailActionCard({
    required this.status,
    required this.canEdit,
    required this.canConfirm,
    required this.isLoading,
    required this.onEdit,
    required this.onConfirm,
  });

  final String status;
  final bool canEdit;
  final bool canConfirm;
  final bool isLoading;
  final VoidCallback onEdit;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return _InvoiceDetailCard(
      icon: Icons.tune_outlined,
      title: 'Thao tác',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canEdit) ...[
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Sửa hóa đơn'),
            ),
            if (canConfirm) const SizedBox(height: 10),
          ],
          if (canConfirm)
            FilledButton.icon(
              onPressed: isLoading ? null : onConfirm,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_outlined),
              label: Text(
                status == InvoiceStatus.pending
                    ? 'Xác nhận đã nhận tiền'
                    : 'Đánh dấu đã thanh toán',
              ),
            ),
        ],
      ),
    );
  }
}

class _InvoiceNotice extends StatelessWidget {
  const _InvoiceNotice({
    required this.message,
    required this.isWarning,
  });

  final String message;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? Colors.orange : Colors.blueAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? Icons.warning_amber_outlined : Icons.info_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _InvoiceEmptyView extends StatelessWidget {
  const _InvoiceEmptyView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: AppColors.primary, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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

String _shortStatusLabel(String status) {
  return switch (status) {
    InvoiceStatus.waitingPayment => 'Đang TT',
    InvoiceStatus.pending => 'Cho xác nhận',
    InvoiceStatus.paid => 'Đã thu',
    InvoiceStatus.overdue => 'Quá hạn',
    InvoiceStatus.cancelled => 'Đã hủy',
    _ => 'Chưa thu',
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

IconData _statusIcon(String status) {
  return switch (status) {
    InvoiceStatus.waitingPayment => Icons.sync_rounded,
    InvoiceStatus.pending => Icons.hourglass_top_rounded,
    InvoiceStatus.paid => Icons.check_circle_rounded,
    InvoiceStatus.overdue => Icons.warning_amber_rounded,
    InvoiceStatus.cancelled => Icons.cancel_rounded,
    _ => Icons.receipt_long_rounded,
  };
}

Color _statusColor(String status) {
  return switch (status) {
    InvoiceStatus.waitingPayment => AppColors.tenantAccent,
    InvoiceStatus.pending => const Color(0xFFF59E0B),
    InvoiceStatus.paid => AppColors.managerAccent,
    InvoiceStatus.overdue => Colors.redAccent,
    InvoiceStatus.cancelled => Colors.grey,
    _ => AppColors.primary,
  };
}

String _money(Object? value) {
  final amount = _readInt(value);
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[index]);
  }
  return '${negative ? '-' : ''}$buffer VND';
}

String _text(Object? value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _readInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
